//
//  ZQBaseApiManager.m
//  OOLaGongYi
//
//  Created by ZhaoQu on 16/9/27.
//  Copyright © 2016年 GZ Leihou Software Development CO.,LTD. All rights reserved.
//

#import "ZQBaseApiManager.h"

@interface ZQApiTask ()

/**
 *  请求Url
 */
@property (copy, nonatomic) NSString *urlString;
/**
 *  请求参数列表
 */
@property (strong, nonatomic) NSMutableDictionary *params;
/**
 *  接口状态
 */
@property (assign, nonatomic) ZQApiState state;
/**
 *  请求方式
 */
@property (assign, nonatomic) ZQApiRequestType requestType;
/**
 *  请求策略
 */
@property (assign, nonatomic) ZQApiRequestPolicy requestPolicy;
/**
 *  数据来源
 */
@property (assign, nonatomic) ZQApiDataSourceType dataSourceType;
/**
 *  原始数据
 */
@property (strong, nonatomic) id responseData;
/**
 *  返回数据
 */
@property (strong, nonatomic) id receiveData;
/**
 *  错误
 */
@property (strong, nonatomic) NSError *error;

@end

@implementation ZQApiTask

/**
 *  取消请求
 */
- (void)cancel
{
    
}
/**
 *  重新请求
 */
- (void)resume
{
    
}

@end


@interface ZQBaseApiManager ()

@property (assign, nonatomic) BOOL netRequesTag;

@property (strong, nonatomic) NSMutableArray<NSURLSessionDataTask *> *currentTasks;

@property (strong, nonatomic) NSMutableDictionary<NSURLSessionDataTask *, ZQApiTask *> *tasks;

@end

@implementation ZQBaseApiManager

- (instancetype)init
{
    if (self = [super init]) {
        if ([self conformsToProtocol:@protocol(ZQApiManagerProtocol)] && ![self isMemberOfClass:[ZQBaseApiManager class]]) {
            child = (id<ZQApiManagerProtocol>)self;
            
            params = [NSMutableDictionary dictionary];
            _tasks = [NSMutableDictionary<NSURLSessionDataTask *, ZQApiTask *> dictionary];
            _timeoutInterval = [ZQApiManager shareApiManager].shareTimeoutInterval;
            requestPolicy = ZQApiRequestTacticsPreferredNet;
            
            if ([child respondsToSelector:@selector(configureDatabase:)]) {
                [child configureDatabase:[ZQApiManager shareApiManager].database];
            }
        }
        else {
            // ZQBaseApiManager为抽象类,不能直接实例化;
            // 直接实例化或不遵守ZQApiManagerProtocol的就让他crash，防止派生类乱来。
            NSAssert(NO, @"ZQBaseApiManager为抽象类,不能直接实例化和其子类必须要实现ZQApiManagerProtocol这个protocol。");
        }
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
 *  1.无缓存策略:所有请求由网络发起
 *  2.有缓存策略:
 *      3.无网络时:加载本地缓存
 *      4.有网络时:
 *          5.设置了下次访问方式:按设置访问网络或缓存
 *          6.没有设置了下次访问方式:按优先访问网络(默认)或缓存
 */
- (void)loadData
{
    ZQApiTask *apiTask = [[ZQApiTask alloc]init];
    apiTask.urlString = urlString;
    apiTask.params = params;
    apiTask.state = ZQApiStateDefault;
    apiTask.requestPolicy = requestPolicy;
    
    
    
    if (![child respondsToSelector:@selector(readCacheWithDatabase:task:isNeedReform:)]) {
        self.netRequesTag = YES;
        [self sendRequestWithTask:apiTask];
        return;
    }
    
    /**
     *  网络状态
     */
    if ([ZQApiManager shareApiManager].netReachabilityStatus == ZQNetReachabilityStatusNotReachable) {
        self.netRequesTag = NO;
    }
    else {
        switch (self.nextRequestSourceType) {
            case ZQApiDataSourceTypeDefault:
                if (requestPolicy & ZQApiRequestTacticsPreferredCache) {
                    self.netRequesTag = NO;
                }
                else {
                    self.netRequesTag = YES;
                }
                break;
            case ZQApiDataSourceTypeNet:
                self.netRequesTag = YES;
                self.nextRequestSourceType = ZQApiDataSourceTypeDefault;
                break;
            case ZQApiDataSourceTypeCache:
                self.netRequesTag = NO;
                self.nextRequestSourceType = ZQApiDataSourceTypeDefault;
                break;
        }
    }
    
    if (self.netRequesTag) {
        [self sendRequestWithTask:apiTask];
    }
    else {
        BOOL isNeedReform = YES;
        id cacheData = [child readCacheWithDatabase:[ZQApiManager shareApiManager].database task:apiTask isNeedReform:&isNeedReform];
        if (cacheData) {
            self.netRequesTag = NO;
            if (isNeedReform) {
                [self reformResponseObjectWithTask:apiTask];
            }
            else {
                [self requestDidSuccessWithTask:apiTask];
            }
        }
        else {
            self.netRequesTag = YES;
            [self sendRequestWithTask:apiTask];
        }
    }
}

- (void)sendRequestWithTask:(ZQApiTask *)apiTask
{
    /**
     *  网络状态
     */
    if ([ZQApiManager shareApiManager].netReachabilityStatus == ZQNetReachabilityStatusNotReachable) {
        apiTask.state = ZQApiStateNoNetWork;
        apiTask.error = [[NSError alloc]initWithDomain:ZQApiErrorDomain code:ZQApiStateNoNetWork userInfo:@{NSLocalizedDescriptionKey: @"没有网络连接!"}];
        [self requestDidFailureWithTask:apiTask];
        return;
    }
    
//    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
    
    
    /**
     *  参数认证
     */
    if ([child respondsToSelector:@selector(isCorrectParamsWithWithTask:)])
    {
        apiTask.error = [NSError errorWithDomain:ZQApiErrorDomain code:ZQApiStateParamsError userInfo:@{NSLocalizedDescriptionKey: @"请求参数不正确!"}];
        if (![child isCorrectParamsWithWithTask:apiTask]) {
            apiTask.state = ZQApiStateParamsError;
            [self requestDidFailureWithTask:apiTask];
            return;
        }
    }
    /**
     *  公共参数认证
     */
    if ([[ZQApiManager shareApiManager].publicHandle respondsToSelector:@selector(isCorrectParamsWithWithTask:)]) {
        apiTask.error = [NSError errorWithDomain:ZQApiErrorDomain code:ZQApiStateParamsError userInfo:@{NSLocalizedDescriptionKey: @"请求参数不正确!"}];
        
        if (![[ZQApiManager shareApiManager].publicHandle isCorrectParamsWithWithTask:apiTask]) {
            apiTask.state = ZQApiStateParamsError;
            [self requestDidFailureWithTask:apiTask];
            return;
        }
    }
    
    /**
     *  NSError转换
     */
    NSError *(^customError)(NSError *) = ^(NSError *error) {
        
        NSInteger errorCode;
        if (error.code == -1004) {
            errorCode = ZQApiStateNoNetWork;
        }
        else if ((error.code == -1001)) {
            errorCode = ZQApiStateTimeout;
        }
        else {
            errorCode = ZQApiStateOther;
        }
        
        return [NSError errorWithDomain:ZQApiErrorDomain code:errorCode userInfo:error.userInfo];
    };
    
    /**
     *  发起请求
     */
    switch (apiTask.requestType)
    {
        case ZQApiRequestTypeGet: {
            NSURLSessionDataTask *task = [[ZQApiManager shareApiManager] get:urlString params:params success:^(NSURLSessionDataTask *task, id responseObject) {
                apiTask.responseData = responseObject;
                [self validateResponseObjectWithTask:apiTask];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                apiTask.error = customError(error);
                [self requestDidFailureWithTask:apiTask];
            }];
            [self.currentTasks addObject:task];
            break;
        }
        case ZQApiRequestTypePost: {
            
            NSURLSessionDataTask *task = [[ZQApiManager shareApiManager] post:urlString params:params success:^(NSURLSessionDataTask *task, id responseObject) {
                apiTask.responseData = responseObject;
                [self validateResponseObjectWithTask:apiTask];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                apiTask.error = customError(error);
                [self requestDidFailureWithTask:apiTask];
            }];
            [self.currentTasks addObject:task];
            break;
        }
        case ZQApiRequestTypePostFile: {
            NSURLSessionDataTask *task = [[ZQApiManager shareApiManager] post:urlString params:params constructingBodyWithBlock:^(id<ZQMultipartFormData> formData) {
                if ([child respondsToSelector:@selector(postFileWithFormData:)]) {
                    [child postFileWithFormData:formData];
                }
            } progress:^(NSProgress *uploadProgress) {
                if (self.progressBlock) {
                    self.progressBlock(uploadProgress);
                }
            } success:^(NSURLSessionDataTask *task, id responseObject) {
                apiTask.responseData = responseObject;
                [self validateResponseObjectWithTask:apiTask];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                apiTask.error = customError(error);
                [self requestDidFailureWithTask:apiTask];
            }];
            [self.currentTasks addObject:task];
            break;
        }
    }
}



/**
 *  验证结果
 */
- (void)validateResponseObjectWithTask:(ZQApiTask *)apiTask
{
    apiTask.error = [NSError errorWithDomain:ZQApiErrorDomain code:ZQApiStateResultError userInfo:@{NSLocalizedDescriptionKey: @"返回结果不正确!"}];
    /**
     *  公共返回结果验证
     */
    if ([[ZQApiManager shareApiManager].publicHandle respondsToSelector:@selector(isCorrectResponseDataWithTask:)] && ![[ZQApiManager shareApiManager].publicHandle isCorrectResponseDataWithTask:apiTask]) {
        apiTask.state = ZQApiStateResultError;
        [self requestDidFailureWithTask:apiTask];
        return;
    }
    /**
     *  返回结果验证
     */
    if ([child respondsToSelector:@selector(isCorrectResponseDataWithTask:)] && ![child isCorrectResponseDataWithTask:apiTask]) {
        apiTask.state = ZQApiStateResultError;
        [self requestDidFailureWithTask:apiTask];
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
    if ([[ZQApiManager shareApiManager].publicHandle respondsToSelector:@selector(reformResponseData:)]) {
        reformData = [[ZQApiManager shareApiManager].publicHandle reformResponseData:apiTask.responseData];
    }
    
    if ([child respondsToSelector:@selector(reformResponseData:)]) {
        reformData = [child reformResponseData:reformData ? reformData : apiTask.responseData];
    }
    apiTask.receiveData = reformData ? reformData : apiTask.responseData;
    [self requestDidSuccessWithTask:apiTask];
}

/**
 *  成功返回处理
 */
- (void)requestDidSuccessWithTask:(ZQApiTask *)apiTask
{
    apiTask.state = ZQApiStateSuccess;
    apiTask.error = nil;
    
    if (self.netRequesTag && [child respondsToSelector:@selector(saveCacheWithDatabase:task:)]) {
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
}

/**
 *  失败返回处理
 */
- (void)requestDidFailureWithTask:(ZQApiTask *)apiTask
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
}

- (void)cancel
{
    [self.currentTasks makeObjectsPerformSelector:@selector(cancel)];
}

- (void)resume
{
    [self.currentTasks makeObjectsPerformSelector:@selector(resume)];
}

@end
