
#import "ZQBaseApiManager.h"
#import <CommonCrypto/CommonDigest.h>

@interface ZQApiTask ()

@property (copy, nonatomic) NSString *taskIdentifier;

@property (copy, nonatomic) NSString *urlString;

@property (copy, nonatomic) NSDictionary *params;

@property (assign, nonatomic) ZQApiState state;

@property (assign, nonatomic) ZQApiDataSourceType dataSourceType;

@property (strong, nonatomic) id responseData;

@property (strong, nonatomic) id receiveData;

@property (strong, nonatomic) NSError *error;

@property (weak, nonatomic) NSURLSessionDataTask *task;
@property (weak, nonatomic) ZQBaseApiManager *apiManager;
/**
 *  判断请求任务列表是否存在和当前请求任务相同taskIdentifier的请求任务
 *
 *  @param tasks 请求任务
 *
 *  @return 返回是否存在
 */
- (BOOL)isExistInTasks:(NSArray<ZQApiTask *> *)tasks;

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

- (BOOL)isExistInTasks:(NSArray<ZQApiTask *> *)tasks
{
    BOOL exist = NO;
    for (ZQApiTask *task in tasks) {
        if ([task.taskIdentifier isEqualToString:self.taskIdentifier]) {
            exist = YES;
            break;
        }
    }
    return exist;
}

@end


@interface ZQBaseApiManager ()
{
    /**
     *  符合ZQApiManagerProtocol协议的self本身
     */
    __weak id<ZQApiManagerProtocol> child;
    
    /**
     *  是否存在网络监听器
     */
    BOOL existNetObserver;
}
/**
 *  当前请求任务列表
 */
@property (strong, nonatomic) NSMutableDictionary<NSURLSessionDataTask *, ZQApiTask *> *currentTasks;
/**
 *  等待请求任务列表
 */
@property (strong, nonatomic) NSMutableArray<ZQApiTask *> *waitingTasks;
/**
 *  自动请求任务列表
 */
@property (strong, nonatomic) NSMutableArray<ZQApiTask *> *autoResumeTasks;

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
        self.currentTasks = [NSMutableDictionary<NSURLSessionDataTask *, ZQApiTask *> dictionary];

        requestType = ZQApiRequestTypePost;
        timeoutInterval = [ZQApiManager shareApiManager].publicTimeoutInterval;
        
        if ([child respondsToSelector:@selector(initialize)]) {
            [child initialize];
        }
        if ([child respondsToSelector:@selector(configureDatabase:)]) {
            [child configureDatabase:[ZQApiManager shareApiManager].database];
        }
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

#pragma mark - 主要逻辑方法

/**
 *  新请求起飞点
 */
- (ZQApiTask *)loadData
{
    // 添加网络监听
    if (autoResume && !existNetObserver) {
        existNetObserver = YES;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(netReachabilityStatusDidChanged:) name:ZQNetReachabilityStatusNotification object:nil];
    }
    // 去掉网络监听
    if (!autoResume && existNetObserver) {
        existNetObserver = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
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
            if (self.currentTasks.count) {
                [self cancelAllTasks];
            }
            break;
        case ZQApiRequestPolicyCancelCurrent:
            if (self.currentTasks.count) {
                [apiTask cancel];
                return;
            }
            break;
        case ZQApiRequestPolicySerialize:
            if (self.currentTasks.count || self.waitingTasks.count) {
                [self.waitingTasks addObject:apiTask];
                return;
            }
            break;
    }
    [self validateParamsWithTask:apiTask];
}

/**
 *  参数配置/验证
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
    
    if ((autoCache || autoResume) && !apiTask.taskIdentifier) {
        [self makeTaskIdentifier:apiTask];
    }
    
    [self cachePolicyWithTask:apiTask];
}

/**
 *  缓存策略
 *
 *  1.无缓存策略:所有请求由网络发起
 *  2.有缓存策略:(当无缓存数据时请求网络)
 *      3.开启了自动缓存同时在优先自动缓存时间内:优先加载自动缓存
 *          4.无网络时:
 *              5.读取协议缓存(优先)
 *              6.读取自动缓存
 *              7.请求网络
 *          8.有网络时:
 *              9.设置了下次访问方式:按设置访问网络或缓存
 *              10.没有设置了下次访问方式:按优先访问网络(默认)或缓存
 */
- (void)cachePolicyWithTask:(ZQApiTask *)apiTask
{
    // 是否实现了读取缓存协议或开启了自动缓存
    if (![child respondsToSelector:@selector(readCacheWithDatabase:task:isNeedReform:)] && !autoCache) {
        [self sendRequestWithTask:apiTask];
        return;
    }
    // 在优先自动缓存时间内加载自动缓存
    if (autoCache && preferredAutoCacheTimeInterval > 0) {
        if ([self readAutoCacheWithTask:apiTask]) {
            [self reformResponseObjectWithTask:apiTask];
            return;
        }
    }
    
    // 网络请求标记
    BOOL netRequesTag;
    if ([ZQApiManager shareApiManager].netReachabilityStatus == ZQNetReachabilityStatusNotReachable) { // 无网络时
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

    if (!netRequesTag && [child respondsToSelector:@selector(readCacheWithDatabase:task:isNeedReform:)]) {
        BOOL isNeedReform = YES;
        id cacheData = [child readCacheWithDatabase:[ZQApiManager shareApiManager].database task:apiTask isNeedReform:&isNeedReform];
        if (cacheData) {
            apiTask.dataSourceType = ZQApiDataSourceTypeCache;
            if (isNeedReform) {
                apiTask.responseData = cacheData;
                [self reformResponseObjectWithTask:apiTask];
            }
            else {
                apiTask.receiveData = cacheData;
                [self successWithTask:apiTask];
            }
            return;
        }
    }
    
    if (!netRequesTag && autoCache) {
        if ([self readAutoCacheWithTask:apiTask]) {
            [self reformResponseObjectWithTask:apiTask];
            return;
        }
    }

    [self sendRequestWithTask:apiTask];
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
        if (autoResume && ![apiTask isExistInTasks:_autoResumeTasks]) {
            [self.autoResumeTasks addObject:apiTask];
        }
        [self failureWithTask:apiTask];
        return;
    }
    
    // url转换
    apiTask.urlString = [apiTask.urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];

    
    // NSError转换
    NSError *(^customError)(NSError *) = ^(NSError *error) {
        
        NSInteger errorCode;
        if (error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorNotConnectedToInternet) {    // 没有网络
            errorCode = ZQApiStateNoNetWork;
        }
        else if ((error.code == NSURLErrorTimedOut)) {   // 超时
            errorCode = ZQApiStateTimeout;
        }
        else if ((error.code == NSURLErrorCancelled)) {    // 请求取消
            errorCode = ZQApiStateCancel;
        }
        else {
            errorCode = ZQApiStateOther;
        }
        
        return [NSError errorWithDomain:ZQApiErrorDomain code:errorCode userInfo:error.userInfo];
    };
    
    apiTask.state = ZQApiStateLoading;
    
    
    if ([ZQApiManager shareApiManager].currentTimeoutInterval != timeoutInterval) {
        [ZQApiManager shareApiManager].currentTimeoutInterval = timeoutInterval;
    }
    NSURLSessionDataTask *task = nil;
    // 发起请求
    switch (requestType)
    {
        case ZQApiRequestTypeGet: {
            task = [[ZQApiManager shareApiManager] get:apiTask.urlString params:apiTask.params success:^(NSURLSessionDataTask *task, id responseObject) {
                ZQApiTask *apiTask = self.currentTasks[task];
                [self.currentTasks removeObjectForKey:task];
                apiTask.responseData = responseObject;
                [self validateResponseObjectWithTask:apiTask];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                ZQApiTask *apiTask = self.currentTasks[task];
                [self.currentTasks removeObjectForKey:task];
                apiTask.error = customError(error);
                [self failureWithTask:apiTask];
            }];
            break;
        }
        case ZQApiRequestTypePost: {
            
            task = [[ZQApiManager shareApiManager] post:apiTask.urlString params:apiTask.params success:^(NSURLSessionDataTask *task, id responseObject) {
                ZQApiTask *apiTask = self.currentTasks[task];
                [self.currentTasks removeObjectForKey:task];
                apiTask.responseData = responseObject;
                [self validateResponseObjectWithTask:apiTask];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                ZQApiTask *apiTask = self.currentTasks[task];
                [self.currentTasks removeObjectForKey:task];
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
                ZQApiTask *apiTask = self.currentTasks[task];
                [self.currentTasks removeObjectForKey:task];
                apiTask.responseData = responseObject;
                [self validateResponseObjectWithTask:apiTask];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                ZQApiTask *apiTask = self.currentTasks[task];
                [self.currentTasks removeObjectForKey:task];
                apiTask.error = customError(error);
                [self failureWithTask:apiTask];
            }];
            break;
        }
    }
    apiTask.task = task;
    self.currentTasks[task] = apiTask;
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
    apiTask.receiveData = apiTask.responseData;
    
    if ([[ZQApiManager shareApiManager].publicHandle respondsToSelector:@selector(reformReceiveDataWithTask:)]) {
        apiTask.receiveData = [[ZQApiManager shareApiManager].publicHandle reformReceiveDataWithTask:apiTask];
    }
    if ([child respondsToSelector:@selector(reformReceiveDataWithTask:)]) {
        apiTask.receiveData = [child reformReceiveDataWithTask:apiTask];
    }
    
    [self successWithTask:apiTask];
}

/**
 *  成功返回处理
 */
- (void)successWithTask:(ZQApiTask *)apiTask
{
    apiTask.state = ZQApiStateSuccess;
    apiTask.error = nil;
    
    if (apiTask.dataSourceType == ZQApiDataSourceTypeNet && [child respondsToSelector:@selector(saveCacheWithDatabase:task:)]) {
        [child saveCacheWithDatabase:[ZQApiManager shareApiManager].database task:apiTask];
    }
    
    if (apiTask.dataSourceType == ZQApiDataSourceTypeNet && autoCache) {
        [self saveAutoCacheWithTask:apiTask];
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
    
    [self resumeWaitingTasks];
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
    
    [self resumeWaitingTasks];
}
/**
 *  启动等待列表的请求任务
 */
- (void)resumeWaitingTasks
{
    if (requestType == ZQApiRequestPolicySerialize) {
        ZQApiTask *firstTask = self.waitingTasks.firstObject;
        [self.waitingTasks removeObject:firstTask];
        [self validateParamsWithTask:firstTask];
    }
}
/**
 *  网络状态改变时操作自动重启列表的请求任务
 */
- (void)netReachabilityStatusDidChanged:(NSNotification *)notification
{
    ZQNetReachabilityStatus status = [notification.userInfo[ZQNetStatusKey] integerValue];
    if (status == ZQNetReachabilityStatusReachableViaWiFi || status == ZQNetReachabilityStatusReachableViaWWAN) {
        [_autoResumeTasks makeObjectsPerformSelector:@selector(resume)];
        [_autoResumeTasks removeAllObjects];
    }
}

#pragma mark - 公有方法

/**
 *  取消所有任务(包含在等待列表的请求任务)
 */
- (void)cancelAllTasks
{
    [_waitingTasks makeObjectsPerformSelector:@selector(cancel)];
    [_currentTasks.allKeys makeObjectsPerformSelector:@selector(cancel)];
    [_autoResumeTasks removeAllObjects];
}

/**
 *  取消某个请求
 */
- (void)cancelWithTask:(ZQApiTask *)apiTask
{
    if ([_waitingTasks containsObject:apiTask] || apiTask.state == ZQApiStateDefault) {
        [_waitingTasks removeObject:apiTask];
        apiTask.state = ZQApiStateCancel;
        apiTask.error = [NSError errorWithDomain:ZQApiErrorDomain code:ZQApiStateCancel userInfo:@{NSLocalizedDescriptionKey: @"请求被取消"}];
        [self failureWithTask:apiTask];
        return;
    }
    if (apiTask.task && _currentTasks[apiTask.task]) {
        [apiTask.task cancel];
    }
}

#pragma mark - 私有方法

/**
 *  读取自动缓存
 *
 *  @param apiTask 请求任务
 *
 *  @return 返回是否读取成功
 */
- (BOOL)readAutoCacheWithTask:(ZQApiTask *)apiTask
{
    FMResultSet *set = [[ZQApiManager shareApiManager].database executeQuery:@"SELECT * FROM t_auto_task_cache WHERE task_id = ?;", apiTask.taskIdentifier];
    if (set.next) {
        NSData *taskCache = [set objectForColumnName:@"task_cache"];
        NSInteger taskDate = [set intForColumn:@"task_date"];
        if (preferredAutoCacheTimeInterval == 0 || [NSDate date].timeIntervalSince1970 - taskDate <= preferredAutoCacheTimeInterval) {
            apiTask.responseData = [NSKeyedUnarchiver unarchiveObjectWithData:taskCache];
            apiTask.dataSourceType = ZQApiDataSourceTypeCache;
            return YES;
        }
    }
    return NO;
}
/**
 *  保存自动缓存
 */
- (void)saveAutoCacheWithTask:(ZQApiTask *)task
{
    NSData * taskCache = [NSKeyedArchiver archivedDataWithRootObject:task.responseData];
    
    [[ZQApiManager shareApiManager].database executeUpdate:@"REPLACE INTO t_auto_task_cache (task_id, task_date, task_cache) VALUES (?,?,?);", task.taskIdentifier, @((int)([NSDate date].timeIntervalSince1970)), taskCache];
}

/**
 *  生成TaskIdentifier
 */
- (void)makeTaskIdentifier:(ZQApiTask *)apiTask
{
    if (taskIdentifierBlock) {
        apiTask.taskIdentifier = [self md5:taskIdentifierBlock(apiTask)];
    }
    else {
        NSMutableString * taskIdentifierString = [NSMutableString stringWithFormat:@"ZQApiManager&%@", apiTask.urlString];
        NSMutableArray *array = [apiTask.params.allKeys mutableCopy];
        [array sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare:obj2];
        }];
        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [taskIdentifierString appendFormat:@"&%@=%@", obj, apiTask.params[obj]];
        }];
        apiTask.taskIdentifier = [self md5:taskIdentifierString];
    }
}

- (NSString *)md5:(NSString *)string
{
    const char * str = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];
    
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    return [ret copy];
}

#pragma mark - getter方法

- (NSMutableArray<ZQApiTask *> *)waitingTasks
{
    if (_waitingTasks == nil) {
        _waitingTasks = [NSMutableArray<ZQApiTask *> array];
    }
    return _waitingTasks;
}
- (NSMutableArray<ZQApiTask *> *)autoResumeTasks
{
    if (_autoResumeTasks == nil) {
        _autoResumeTasks = [NSMutableArray<ZQApiTask *> array];
    }
    return _autoResumeTasks;
}
@end
