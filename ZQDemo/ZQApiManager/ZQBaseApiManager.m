
#import "ZQBaseApiManager.h"

@interface ZQApiTask ()

@property (copy, nonatomic) NSString *urlString;

@property (copy, nonatomic) NSDictionary *params;

@property (assign, nonatomic) ZQApiState state;

@property (assign, nonatomic) ZQApiDataSourceType dataSourceType;

@property (strong, nonatomic) id responseData;

@property (strong, nonatomic) id receiveData;

@property (strong, nonatomic) NSError *error;

@property (weak, nonatomic) NSURLSessionDataTask *task;
@property (weak, nonatomic) ZQBaseApiManager *apiManager;

@end

@implementation ZQApiTask

/**
 *  取消请求
 */
- (void)cancel
{
    [self.apiManager cancelWithTask:self];
}
/**
 *  重新请求
 */
- (ZQApiTask *)resume
{
    return [self.apiManager resumeWithTask:self];
}

@end


@interface ZQBaseApiManager ()
{
    /**
     *  符合ZQApiManagerProtocol协议的self本身
     */
    __weak id<ZQApiManagerProtocol> child;
    
    /**
     *  当前请求任务列表
     */
    NSMutableDictionary<NSURLSessionDataTask *, ZQApiTask *> *currentTasks;
    /**
     *  当前请求任务列表
     */
    NSMutableArray<ZQApiTask *> *waitingTasks;
    /**
     *  自动请求任务列表
     */
    NSMutableArray<ZQApiTask *> *autoResumeTasks;
}

@end

@implementation ZQBaseApiManager

- (void)dealloc
{
//    NSLog(@"ZQBaseApiManager-dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    if ([self conformsToProtocol:@protocol(ZQApiManagerProtocol)] && ![self isMemberOfClass:[ZQBaseApiManager class]]) {
        child = (id<ZQApiManagerProtocol>)self;
        
        params = [NSMutableDictionary dictionary];
        currentTasks = [NSMutableDictionary<NSURLSessionDataTask *, ZQApiTask *> dictionary];
        waitingTasks = [NSMutableArray<ZQApiTask *> array];
        autoResumeTasks = [NSMutableArray<ZQApiTask *> array];
        requestType = ZQApiRequestTypePost;
        timeoutInterval = [ZQApiManager shareApiManager].shareTimeoutInterval;
        if ([child respondsToSelector:@selector(configureDatabase:)]) {
            [child configureDatabase:[ZQApiManager shareApiManager].database];
        }
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(netReachabilityStatusChanged:) name:ZQNetReachabilityStatusNotification object:nil];
    }
    else {
        // ZQBaseApiManager为抽象类,不能直接实例化;
        // 直接实例化或不遵守ZQApiManagerProtocol的就让他crash，防止派生类乱来。
        NSAssert(NO, @"ZQBaseApiManager为抽象类,不能直接实例化和其子类必须要实现ZQApiManagerProtocol这个protocol。");
    }
    return self;
}

- (instancetype)initWithSuccess:(void (^)(ZQApiTask *task))success failure:(void (^)(ZQApiTask *task))failure
{
    if (self = [self init]) {
        self.successBlock = success;
        self.failureBlock = failure;
    }
    return self;
}

+ (instancetype)apiManagerWithSuccess:(void (^)(ZQApiTask *task))success failure:(void (^)(ZQApiTask *task))failure
{
    return [[self alloc]initWithSuccess:success failure:failure];
}

/**
 *  新请求起飞点
 */
- (ZQApiTask *)loadData
{
    ZQApiTask *apiTask = [[ZQApiTask alloc]init];
    apiTask.urlString = urlString;
    apiTask.state = ZQApiStateDefault;
    apiTask.params = [params copy];
    
    apiTask.apiManager = self;
    [self requestPolicyWithTask:apiTask];
    return apiTask;
}

/**
 *  请求重新开始
 */
- (ZQApiTask *)resumeWithTask:(ZQApiTask *)apiTask
{
    urlString = apiTask.urlString;
    params = [apiTask.params mutableCopy];
    apiTask.state = ZQApiStateDefault;
    
    apiTask.apiManager = self;
    apiTask.responseData = nil;
    apiTask.receiveData = nil;
    apiTask.dataSourceType = ZQApiDataSourceTypeDefault;
    apiTask.error = nil;
    apiTask.task = nil;
    
    [self requestPolicyWithTask:apiTask];
    return apiTask;
}

/**
 *  请求策略逻辑
 */
- (void)requestPolicyWithTask:(ZQApiTask *)apiTask
{
    switch (requestPolicy) {
        case ZQApiRequestPolicyParallel:
            break;
        case ZQApiRequestPolicyCancelPrevious:
            if (currentTasks.count || waitingTasks.count) {
                [self cancelCurrentTasks];
            }
            break;
        case ZQApiRequestPolicyCancelCurrent:
            if (currentTasks.count || waitingTasks.count) {
                [apiTask cancel];
                return;
            }
            break;
        case ZQApiRequestPolicySerialize:
            if (currentTasks.count || waitingTasks.count) {
                [waitingTasks addObject:apiTask];
                return;
            }
            break;
    }
    [self validateParamsWithTask:apiTask];
}

/**
 *  参数配置/认证
 */
- (void)validateParamsWithTask:(ZQApiTask *)apiTask {
    
    if ([child respondsToSelector:@selector(configureParams:withTask:)]) {
        [child configureParams:params withTask:apiTask];
        apiTask.params = [params copy];
    }
    if ([[ZQApiManager shareApiManager].publicHandle respondsToSelector:@selector(configureParams:withTask:)]) {
        [[ZQApiManager shareApiManager].publicHandle configureParams:params withTask:apiTask];
        apiTask.params = [params copy];
    }
    
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
    if (([child respondsToSelector:@selector(isCorrectParamsWithTask:errorInfo:)] && ![child isCorrectParamsWithTask:apiTask errorInfo:errorInfo])
        || ([[ZQApiManager shareApiManager].publicHandle respondsToSelector:@selector(isCorrectParamsWithTask:errorInfo:)] && ![[ZQApiManager shareApiManager].publicHandle isCorrectParamsWithTask:apiTask errorInfo:errorInfo])) {
            
        errorInfo[NSLocalizedDescriptionKey] = @"请求参数不正确!";
        apiTask.state = ZQApiStateParamsError;
        apiTask.params = [params copy];
        apiTask.error = [NSError errorWithDomain:ZQApiErrorDomain code:ZQApiStateParamsError userInfo:errorInfo];
        [self failureWithTask:apiTask];
        return;
    }

    apiTask.params =[params copy];
    [self cachePolicyWithTask:apiTask];
}

/**
 *  缓存策略
 *
 *  1.无缓存策略:所有请求由网络发起
 *  2.有缓存策略:
 *      3.无网络时:加载本地缓存
 *      4.有网络时:
 *          5.设置了下次访问方式:按设置访问网络或缓存
 *          6.没有设置了下次访问方式:按优先访问网络(默认)或缓存
 */
- (void)cachePolicyWithTask:(ZQApiTask *)apiTask
{
    // 网络请求标记
    BOOL netRequesTag;
    // 是否实现了读取缓存方法
    if (![child respondsToSelector:@selector(readCacheWithDatabase:task:isNeedReform:)]) {
        netRequesTag = YES;
        [self sendRequestWithTask:apiTask];
        return;
    }
    
    // 网络状态
    if ([ZQApiManager shareApiManager].netReachabilityStatus == ZQNetReachabilityStatusNotReachable) {
        netRequesTag = NO;
    }
    else {
        switch (nextRequestSourceType) {
            case ZQApiDataSourceTypeDefault:
                netRequesTag = preferredRequestSourceType == ZQApiDataSourceTypeCache ? NO : YES;
                break;
            case ZQApiDataSourceTypeNet:
                netRequesTag = YES;
                nextRequestSourceType = ZQApiDataSourceTypeDefault;
                break;
            case ZQApiDataSourceTypeCache:
                netRequesTag = NO;
                nextRequestSourceType = ZQApiDataSourceTypeDefault;
                break;
        }
    }
    
    if (netRequesTag) {
        [self sendRequestWithTask:apiTask];
    }
    else {
        BOOL isNeedReform = YES;
        id cacheData = [child readCacheWithDatabase:[ZQApiManager shareApiManager].database task:apiTask isNeedReform:&isNeedReform];
        if (cacheData) {
            apiTask.dataSourceType = ZQApiDataSourceTypeCache;
            netRequesTag = NO;
            if (isNeedReform) {
                apiTask.responseData = cacheData;
                [self reformResponseObjectWithTask:apiTask];
            }
            else {
                apiTask.receiveData = cacheData;
                [self successWithTask:apiTask];
            }
        }
        else {
            netRequesTag = YES;
            [self sendRequestWithTask:apiTask];
        }
    }
}

/**
 *  发起网络请求
 */
- (void)sendRequestWithTask:(ZQApiTask *)apiTask
{
    apiTask.dataSourceType = ZQApiDataSourceTypeNet;
    // 网络状态
    if ([ZQApiManager shareApiManager].netReachabilityStatus == ZQNetReachabilityStatusNotReachable) {
        apiTask.state = ZQApiStateNoNetWork;
        apiTask.error = [[NSError alloc]initWithDomain:ZQApiErrorDomain code:ZQApiStateNoNetWork userInfo:@{NSLocalizedDescriptionKey: @"没有网络连接!"}];
        if (autoResume) {
            [autoResumeTasks addObject:apiTask];
        }
        [self failureWithTask:apiTask];
        return;
    }
    
    // url转换
    apiTask.urlString = [apiTask.urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];

    
    // NSError转换
    NSError *(^customError)(NSError *) = ^(NSError *error) {
        
        NSInteger errorCode;
        if (error.code == -1004 || error.code == -1009) {          // 没有网络
            errorCode = ZQApiStateNoNetWork;
        }
        else if ((error.code == -1001)) {   // 超时
            errorCode = ZQApiStateTimeout;
        }
        else if ((error.code == -999)) {    // 请求取消
            errorCode = ZQApiStateCancel;
        }
        else {
            errorCode = ZQApiStateOther;
        }
        
        return [NSError errorWithDomain:ZQApiErrorDomain code:errorCode userInfo:error.userInfo];
    };
    
    apiTask.state = ZQApiStateLoading;
    
    
    if ([ZQApiManager shareApiManager].shareTimeoutInterval != timeoutInterval) {
        [ZQApiManager shareApiManager].manager.requestSerializer.timeoutInterval = timeoutInterval;
    }
    NSURLSessionDataTask *task = nil;
    // 发起请求
    switch (requestType)
    {
        case ZQApiRequestTypeGet: {
            task = [[ZQApiManager shareApiManager] get:apiTask.urlString params:apiTask.params success:^(NSURLSessionDataTask *task, id responseObject) {
                ZQApiTask *apiTask = currentTasks[task];
                [currentTasks removeObjectForKey:task];
                apiTask.responseData = responseObject;
                [self validateResponseObjectWithTask:apiTask];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                ZQApiTask *apiTask = currentTasks[task];
                [currentTasks removeObjectForKey:task];
                apiTask.error = customError(error);
                [self failureWithTask:apiTask];
            }];
            break;
        }
        case ZQApiRequestTypePost: {
            
            task = [[ZQApiManager shareApiManager] post:apiTask.urlString params:apiTask.params success:^(NSURLSessionDataTask *task, id responseObject) {
                ZQApiTask *apiTask = currentTasks[task];
                [currentTasks removeObjectForKey:task];
                apiTask.responseData = responseObject;
                [self validateResponseObjectWithTask:apiTask];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                ZQApiTask *apiTask = currentTasks[task];
                [currentTasks removeObjectForKey:task];
                apiTask.error = customError(error);
                [self failureWithTask:apiTask];
            }];
            break;
        }
        case ZQApiRequestTypePostFile: {
            task = [[ZQApiManager shareApiManager] post:apiTask.urlString params:apiTask.params formDataBlock:^(id<ZQMultipartFormData> formData) {
                if ([child respondsToSelector:@selector(postFileWithFormData:)]) {
                    [child postFileWithFormData:formData];
                }
            } progress:^(NSProgress *uploadProgress) {
                if ([self.delegate respondsToSelector:@selector(apiManager:uploadWithTask:progress:)]) {
                    [self.delegate apiManager:self uploadWithTask:apiTask progress:uploadProgress];
                }
                if (self.progressBlock) {
                    self.progressBlock(uploadProgress);
                }
            } success:^(NSURLSessionDataTask *task, id responseObject) {
                ZQApiTask *apiTask = currentTasks[task];
                [currentTasks removeObjectForKey:task];
                apiTask.responseData = responseObject;
                [self validateResponseObjectWithTask:apiTask];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                ZQApiTask *apiTask = currentTasks[task];
                [currentTasks removeObjectForKey:task];
                apiTask.error = customError(error);
                [self failureWithTask:apiTask];
            }];
            break;
        }
    }
    apiTask.task = task;
    currentTasks[task] = apiTask;
}



/**
 *  验证结果
 */
- (void)validateResponseObjectWithTask:(ZQApiTask *)apiTask
{
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
    if (([[ZQApiManager shareApiManager].publicHandle respondsToSelector:@selector(isCorrectResponseDataWithTask:errorInfo:)] && ![[ZQApiManager shareApiManager].publicHandle isCorrectResponseDataWithTask:apiTask errorInfo:errorInfo])
        || ([child respondsToSelector:@selector(isCorrectResponseDataWithTask:errorInfo:)] && ![child isCorrectResponseDataWithTask:apiTask errorInfo:errorInfo])) {
            
        errorInfo[NSLocalizedDescriptionKey] = @"返回结果不正确!";
        apiTask.state = ZQApiStateResultError;
        apiTask.error = [NSError errorWithDomain:ZQApiErrorDomain code:ZQApiStateParamsError userInfo:errorInfo];
        [self failureWithTask:apiTask];
        return;
    }
    
    [self reformResponseObjectWithTask:apiTask];
}

/**
 *  格式化
 */
- (void)reformResponseObjectWithTask:(ZQApiTask *)apiTask
{
    id reformData = nil;
    if ([[ZQApiManager shareApiManager].publicHandle respondsToSelector:@selector(reformResponseData:withTask:)]) {
        reformData = [[ZQApiManager shareApiManager].publicHandle reformResponseData:apiTask.responseData withTask:apiTask];
    }
    
    if ([child respondsToSelector:@selector(reformResponseData:withTask:)]) {
        reformData = [child reformResponseData:reformData ? reformData : apiTask.responseData withTask:apiTask];
    }
    apiTask.receiveData = reformData ? reformData : apiTask.responseData;
    [self successWithTask:apiTask];
}

/**
 *  成功返回处理
 */
- (void)successWithTask:(ZQApiTask *)apiTask
{
    apiTask.state = ZQApiStateSuccess;
    apiTask.error = nil;
    
    if (apiTask.dataSourceType == ZQApiDataSourceTypeCache && [child respondsToSelector:@selector(saveCacheWithDatabase:task:)]) {
        [child saveCacheWithDatabase:[ZQApiManager shareApiManager].database task:apiTask];
    }
    
    if ([[ZQApiManager shareApiManager].publicHandle respondsToSelector:@selector(requestDidSuccessWithTask:)]) {
        [[ZQApiManager shareApiManager].publicHandle requestDidSuccessWithTask:apiTask];
    }
    if ([child respondsToSelector:@selector(requestDidSuccessWithTask:)]) {
        [child requestDidSuccessWithTask:apiTask];
    }
    if (self.successBlock) {
        self.successBlock(apiTask);
    }
    
    if ([self.delegate respondsToSelector:@selector(apiManager:didSuccessedWithTask:)]) {
        [self.delegate apiManager:self didSuccessedWithTask:apiTask];
    }
    
    [self waitingTasksResume];
}

/**
 *  失败返回处理
 */
- (void)failureWithTask:(ZQApiTask *)apiTask
{
    apiTask.state = apiTask.error.code;
    
    if ([[ZQApiManager shareApiManager].publicHandle respondsToSelector:@selector(requestDidFailureWithTask:)]) {
        [[ZQApiManager shareApiManager].publicHandle requestDidFailureWithTask:apiTask];
    }
    if ([child respondsToSelector:@selector(requestDidFailureWithTask:)]) {
        [child requestDidFailureWithTask:apiTask];
    }
    if (self.failureBlock) {
        self.failureBlock(apiTask);
    }
    
    if ([self.delegate respondsToSelector:@selector(apiManager:didFailedWithTask:)]) {
        [self.delegate apiManager:self didFailedWithTask:apiTask];
    }
    
    [self waitingTasksResume];
}
/**
 *  开启等待请求任务
 */
- (void)waitingTasksResume
{
    if (waitingTasks.count) {
        ZQApiTask *firstTask = waitingTasks.firstObject;
        [waitingTasks removeObject:firstTask];
        [self validateParamsWithTask:firstTask];
    }
}
/**
 *  取消当前请求任务(包含在等待列表的请求任务)
 */
- (void)cancelCurrentTasks
{
    [waitingTasks makeObjectsPerformSelector:@selector(cancel)];
    [currentTasks.allKeys makeObjectsPerformSelector:@selector(cancel)];
}

/**
 *  取消某个请求
 */
- (void)cancelWithTask:(ZQApiTask *)apiTask
{
    if ([waitingTasks containsObject:apiTask] || apiTask.state == ZQApiStateDefault) {
        [waitingTasks removeObject:apiTask];
        apiTask.state = ZQApiStateCancel;
        apiTask.error = [NSError errorWithDomain:ZQApiErrorDomain code:ZQApiStateCancel userInfo:@{NSLocalizedDescriptionKey: @"请求被取消"}];
        [self failureWithTask:apiTask];
        return;
    }
    if (apiTask.task && currentTasks[apiTask.task]) {
        [apiTask.task cancel];
    }
}
/**
 *  启动autoResume请求任务
 */
- (void)netReachabilityStatusChanged:(NSNotification *)notification
{
    if (!autoResume) {
        return;
    }
    ZQNetReachabilityStatus status = [notification.userInfo[ZQNetStatusKey] integerValue];
    if (status == ZQNetReachabilityStatusReachableViaWiFi || status == ZQNetReachabilityStatusReachableViaWWAN) {
        [autoResumeTasks makeObjectsPerformSelector:@selector(resume)];
        [autoResumeTasks removeAllObjects];
    }
}

@end
