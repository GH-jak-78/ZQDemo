// 
// ZQApiManager.h
// 
// Created by ZhaoQu on 16/9/27.
// Copyright © 2016年 GZ Leihou Software Development CO.,LTD. All rights reserved.
// 

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "FMDB.h"

#pragma mark - 定义

extern NSString * const ZQNetStatusKey;
extern NSString * const ZQNetReachabilityStatusNotification;

extern NSString * const ZQApiErrorDomain;
extern NSString * const ZQApiErrorCodeKey;
extern NSString * const ZQApiErrorMessageKey;

extern NSString * const NSLocalizedDescriptionKey;

#define ZQDatabasePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject]stringByAppendingPathComponent:@"ZQApiManager.sqlite"]

typedef NS_ENUM(NSInteger, ZQNetReachabilityStatus)
{
    ZQNetReachabilityStatusUnknown          = -1,
    ZQNetReachabilityStatusNotReachable     = 0,
    ZQNetReachabilityStatusReachableViaWWAN = 1,
    ZQNetReachabilityStatusReachableViaWiFi = 2,
};

typedef NS_ENUM (NSInteger, ZQApiState)
{
    ZQApiStateDefault,       // 没有产生过API请求，这个是manager的默认状态。
    ZQApiStateSuccess,       // API请求成功且返回数据正确，此时manager的数据是可以直接拿来使用的。
    ZQApiStateResultError,   // API请求成功但返回数据不正确。如果回调数据验证函数返回值为NO，manager的状态就会是这个。
    ZQApiStateParamsError,   // 参数错误，此时manager不会调用API，因为参数验证是在调用API之前做的。
    ZQApiStateTimeout,       // 请求超时。具体超时时间的设置根据不同需求而有所差别。
    ZQApiStateNoNetWork,     // 网络不通。在调用API之前会判断一下当前网络是否通畅，这个也是在调用API之前验证的，和上面超时的状态是有区别的。
    ZQApiStateCancel,        // 请求取消
    ZQApiStateOther
};

typedef NS_ENUM (NSInteger, ZQApiDataSourceType)
{
    ZQApiDataSourceTypeDefault,    // 未定义
    ZQApiDataSourceTypeNet,          // 网络
    ZQApiDataSourceTypeCache         // 缓存
};

typedef NS_ENUM (NSInteger, ZQApiRequestType)
{
    ZQApiRequestTypeGet,        // Get方式请求数据
    ZQApiRequestTypePost,       // Post方式请求数据(默认)
    ZQApiRequestTypePostFile    // Post方式上传文件
};

typedef NS_OPTIONS (NSInteger, ZQApiRequestPolicy)  // 请求策略 (默认并发请求,优先请求网络)
{
    ZQApiRequestTacticsParallel          = 1 << 0,   // 并发请求
    ZQApiRequestTacticsSerialize         = 1 << 1,   // 串行化(顺序)请求
    ZQApiRequestTacticsUnique            = 1 << 2,   // 唯一性
    ZQApiRequestTacticsCancelPrevious    = 1 << 3,   // 并发时取消前一次请求
    ZQApiRequestTacticsCancelCurrent     = 1 << 4,   // 并发时取消当前请求
    
    ZQApiRequestTacticsPreferredNet      = 1 << 5,   // 优先读取缓存
    ZQApiRequestTacticsPreferredCache    = 1 << 6,   // 优先读取缓存
    
    ZQApiRequestTacticsAutoResume        = 1 << 7    // 无网络失败时,网络正常后自动重新请求
};


@interface ZQApiTask : NSObject
/**
 *  请求Url
 */
@property (copy, nonatomic, readonly) NSString *urlString;
/**
 *  请求参数列表
 */
@property (strong, nonatomic, readonly) NSDictionary *params;
/**
 *  接口状态
 */
@property (assign, nonatomic, readonly) ZQApiState state;
/**
 *  请求方式
 */
@property (assign, nonatomic, readonly) ZQApiRequestType requestType;
/**
 *  请求策略
 */
@property (assign, nonatomic, readonly) ZQApiRequestPolicy requestPolicy;
/**
 *  数据来源
 */
@property (assign, nonatomic, readonly) ZQApiDataSourceType dataSource;
/**
 *  原始数据
 */
@property (strong, nonatomic, readonly) id responseData;
/**
 *  返回数据
 */
@property (strong, nonatomic, readonly) id receiveData;
/**
 *  错误
 */
@property (strong, nonatomic, readonly) NSError *error;

/**
 *  取消请求
 */
- (void)cancel;
/**
 *  重新请求
 */
- (void)resume;

@end


#pragma mark - 协议

@class ZQBaseApiManager;

// 接口请求回调代理
@protocol ZQApiManagerDelegate <NSObject>

// 可选的
@optional

// 请求成功时回调
- (void)apiManager:(ZQBaseApiManager *)apiManager didSuccessedWithTask:(ZQApiTask *)task;

// 请求失败时回调
- (void)apiManager:(ZQBaseApiManager *)apiManager didFailedWithTask:(ZQApiTask *)task;

@end


// 文件上传协议
@protocol ZQMultipartFormData <AFMultipartFormData>
@end


// ZQBaseApiManager派生类必须遵守的协议
@protocol ZQApiManagerProtocol <NSObject>

// 必须的
@required

// 可选的
@optional

/**
 *  上传文件
 *
 *  @param formData 上传操作对象
 */
- (void)postFileWithFormData:(id<ZQMultipartFormData>)formData;

/*
 验证:比如邮箱地址或是手机号码等等，我们可以在这里判断邮箱或者电话是否符合规则，比如描述是否超过十个字。
 从而manager在调用API之前可以验证这些参数，通过manager的回调函数告知上层controller。避免无效的API请求。加快响应速度，也可以多个manager共用.
 所以不要以为这个params验证不重要。当调用API的参数是来自用户输入的时候，验证是很必要的。
 当调用API的参数不是来自用户输入的时候，这个方法可以写成直接返回true。反正哪天要真是参数错误，QA那一关肯定过不掉。
 不过我还是建议认真写完这个参数验证，这样能够省去将来代码维护者很多的时间。
 */
- (BOOL)isCorrectParamsWithWithTask:(ZQApiTask *)task;

/*
 验证:所有的receiveData数据都应该在这个函数里面进行检查，事实上，到了回调delegate的函数里面是不需要再额外验证返回数据是否为空的。
 因为判断逻辑都在这里做掉了。
 而且本来判断返回数据是否正确的逻辑就应该交给manager去做，不要放到回调到controller的delegate方法里面去做。
 */
- (BOOL)isCorrectResponseDataWithTask:(ZQApiTask *)task;
/**
 *  请求成功处理
 */
- (void)requestDidSuccessWithTask:(ZQApiTask *)task;
/**
 *  请求失败处理
 */
- (void)requestDidFailureWithTask:(ZQApiTask *)task;

/**
 *  格式化返回的数据
 *
 *  @param responseObject 请求返回的原数据
 *
 *  @return 格式化后的数据(一般用在模型化)
 */
- (id)reformResponseData:(id)responseData;

/**
 *  配置数据库(建表等),一般在publicHandle中处理
 */
- (void)configureDatabase:(FMDatabase *)database;
/**
 *  读取缓存
 *
 *  @return 返回请求的缓存数据,没有返回nil
 */
/**
 *  读取缓存
 *
 *  @param database     数据库
 *  @param isNeedReform 返回的缓存是否要reform(默认为YES)
 *
 *  @return 返回读取到的缓存数据
 */
- (id)readCacheWithDatabase:(FMDatabase *)database task:(ZQApiTask *)task isNeedReform:(BOOL *)isNeedReform;
/**
 *  将新数据持久化
 *
 *  @param reformData 转换格式后的请求数据
 */
- (void)saveCacheWithDatabase:(FMDatabase *)database task:(ZQApiTask *)task;

@end


#pragma mark - ZQApiManager

@interface ZQApiManager : NSObject

+ (instancetype)shareApiManager;

@property (strong, nonatomic) id<ZQApiManagerProtocol> publicHandle;

@property (strong, nonatomic, readonly) FMDatabase *database;
@property (strong, nonatomic, readonly) AFHTTPSessionManager *manager;

@property (assign, nonatomic, readonly) ZQNetReachabilityStatus netReachabilityStatus;

/**
 *  支持处理的的数据类型,例:@"text/html",@"text/json",@"application/json"等
 */
@property (strong, nonatomic) NSSet *acceptableContentTypes;
/**
 *  默认请求超时时间
 */
@property (assign, nonatomic) NSTimeInterval shareTimeoutInterval;
/**
 *  取消所有请求
 */
- (void)cancelAllRequest;
/**
 *  开始监测网络变化
 */
- (void)startMonitoring;

/**
 *  停止监测网络变化
 */
- (void)stopMonitoring;

/**
 *  请求网络
 *
 *  @param url     请求Url
 *  @param params  参数
 *  @param progress  进度回调
 *  @param success 成功回调
 *  @param failure 失败回调
 */
- (NSURLSessionDataTask *)get:(NSString *)url
                       params:(id)params
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

- (NSURLSessionDataTask *)post:(NSString *)url
                        params:(id)params
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

- (NSURLSessionDataTask *)post:(NSString *)url
                        params:(id)params
     constructingBodyWithBlock:(void (^)(id<ZQMultipartFormData> formData))block
                      progress:(void (^)(NSProgress *uploadProgress))progress
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end
