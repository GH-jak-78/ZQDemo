/**
 *  ZQApiManager 接口框架
 *
 *  用法:从ZQBaseApiManager继承出一个必须遵守ZQApiManagerProtocol协议的接口类,由loadData()发起请求
 *
 *  注意:
 *      1.同时实现协议缓存和开启自动缓存的情况下,如在优先缓存时间内则读取自动缓存,不在其内则读取协议缓存.
 *
 */

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "FMDB.h"

#pragma mark - 定义

extern NSString * const ZQNetStatusKey; // 网络状态键
extern NSString * const ZQNetReachabilityStatusNotification; // 网络连接状态改变通知

extern NSString * const ZQApiErrorDomain;   // 自定义的接口错误域,错误code为接口状态码

/**
 *  数据库位置
 */
#define ZQDatabasePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject]stringByAppendingPathComponent:@"ZQApiManager.sqlite"]
/**
 *  网络连通状态
 */
typedef NS_ENUM(NSInteger, ZQNetReachabilityStatus)
{
    ZQNetReachabilityStatusUnknown          = -1,   // 未确定
    ZQNetReachabilityStatusNotReachable     = 0,    // 无网络
    ZQNetReachabilityStatusReachableViaWWAN = 1,    // 蜂窝移动
    ZQNetReachabilityStatusReachableViaWiFi = 2,    // wifi
};
/**
 *  接口状态
 */
typedef NS_ENUM (NSInteger, ZQApiState)
{
    ZQApiStateDefault,       // 没有产生过API请求,这个是manager的默认状态.
    ZQApiStateLoading,       // 网络请求中...
    ZQApiStateSuccess,       // API请求成功且返回数据正确,此时manager的数据是可以直接拿来使用的.
    ZQApiStateResultError,   // API请求成功但返回数据不正确.如果回调数据验证函数返回值为NO,manager的状态就会是这个.
    ZQApiStateParamsError,   // 参数错误,此时manager不会调用API,因为参数验证是在调用API之前做的.
    ZQApiStateTimeout,       // 请求超时.具体超时时间的设置根据不同需求而有所差别.
    ZQApiStateNoNetWork,     // 网络不通.在调用API之前会判断一下当前网络是否通畅,这个也是在调用API之前验证的,和上面超时的状态是有区别的.
    ZQApiStateCancel,        // 请求取消
    ZQApiStateOther          // 其它错误
};
/**
 *  请求方法
 */
typedef NS_ENUM (NSInteger, ZQApiRequestType)
{
    ZQApiRequestTypeGet,        // Get方式请求数据
    ZQApiRequestTypePost,       // Post方式请求数据(默认)
    ZQApiRequestTypePostFile    // Post方式上传文件
};
/**
 *  接口数据来源类型
 */
typedef NS_ENUM (NSInteger, ZQApiDataSourceType)
{
    ZQApiDataSourceTypeDefault, // 未定义
    ZQApiDataSourceTypeNet,     // 网络
    ZQApiDataSourceTypeCache    // 缓存
};
/**
 *  请求策略
 */
typedef NS_ENUM (NSInteger, ZQApiRequestPolicy)
{
    ZQApiRequestPolicyParallel,         // 并发请求(默认)
    ZQApiRequestPolicyCancelCurrent,    // 并发时取消当前请求
    ZQApiRequestPolicyCancelPrevious,   // 并发时取消之前请求
    ZQApiRequestPolicySerialize,        // 并发时串行化(顺序)请求
};

/**
 *  请求任务类
 */
@interface ZQApiTask : NSObject
/**
 *  请求Url
 */
@property (copy, nonatomic, readonly) NSString *urlString;
/**
 *  请求参数列表
 */
@property (copy, nonatomic, readonly) NSDictionary *params;
/**
 *  接口状态
 */
@property (assign, nonatomic, readonly) ZQApiState state;
/**
 *  数据来源
 */
@property (assign, nonatomic, readonly) ZQApiDataSourceType dataSourceType;
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
- (ZQApiTask *)resume;

@end


#pragma mark - 协议

@class ZQBaseApiManager;

/**
 *  接口请求回调代理
 */
@protocol ZQApiManagerDelegate <NSObject>

@optional   // 可选的

/**
 *  请求成功时回调
 *
 *  @param apiManager 接口管理对象
 *  @param task       请求任务
 */
- (void)apiManager:(ZQBaseApiManager *)apiManager didSuccessedWithTask:(ZQApiTask *)task;

/**
 *  请求失败时回调
 *
 *  @param apiManager 接口管理对象
 *  @param task       请求任务
 */
- (void)apiManager:(ZQBaseApiManager *)apiManager didFailedWithTask:(ZQApiTask *)task;

/**
 *  上传文件进度回调
 *
 *  @param apiManager 接口管理对象
 *  @param task       请求任务
 *  @param progress   进度对象
 */
- (void)apiManager:(ZQBaseApiManager *)apiManager uploadWithTask:(ZQApiTask *)task progress:(NSProgress *)progress;

@end

/**
 *  文件上传操作协议
 */
@protocol ZQMultipartFormData <AFMultipartFormData>

@end


/**
 *  ZQBaseApiManager派生类必须遵守的协议
 */
@protocol ZQApiManagerProtocol <NSObject>

@optional   // 可选的
/**
 *  ApiManager初始化
 */
- (void)initialize;
/**
 *  配置参数 (一般用在publicHandle中统一处理参数,接口类可直接用成员变量)
 *
 *  @param params 参数字典
 *  @param task   请求任务
 */
- (void)configureParams:(NSMutableDictionary *)params withTask:(ZQApiTask *)task;

/**
 *  参数验证
 *
 *  当调用API的参数是来自用户输入的时候,验证是很必要的.比如我们可以在这里判断邮箱地址或是手机号码是否符合规则等等.
 *  在调用API之前可以验证这些参数,通过manager的回调函数告知上层controller.这样可避免无效的API请求,加快响应速度.
 *
 *  @param task      请求任务
 *  @param errorInfo 用户可定义的错误信息
 *
 *  @return 返回是否正确
 */
- (BOOL)isCorrectParamsWithTask:(ZQApiTask *)task  errorInfo:(NSMutableDictionary *)errorInfo;

/**
 *  返回数据验证
 *
 *  所有的receiveData数据都应该在这个函数里面进行检查,事实上,到了回调delegate的函数里面是不需要再额外验证返回数据是否为空的,因为判断逻辑都在这里做掉了.
 *  而且本来判断返回数据是否正确的逻辑就应该交给manager去做,不要放到回调到controller的delegate方法里面去做.
 *
 *  @param task      请求任务
 *  @param errorInfo 用户可定义的错误信息
 *
 *  @return 返回是否正确
 */
- (BOOL)isCorrectResponseDataWithTask:(ZQApiTask *)task errorInfo:(NSMutableDictionary *)errorInfo;

/**
 *  格式化返回的数据(一般用在模型化)
 *
 *  @param responseObject 请求返回的原数据
 *  @param task 请求任务
 *
 *  @return 格式化后的数据
 */
- (id)reformResponseData:(id)responseData withTask:(ZQApiTask *)task;

/**
 *  请求成功处理
 */
- (void)requestDidSuccessWithTask:(ZQApiTask *)task;
/**
 *  请求失败处理
 */
- (void)requestDidFailureWithTask:(ZQApiTask *)task;

/**
 *  上传文件
 *
 *  @param formData 上传操作对象 [formData append...]
 */
- (void)postFileWithFormData:(id<ZQMultipartFormData>)formData;

/**
 *  配置数据库(建表等),一般在publicHandle中处理
 */
- (void)configureDatabase:(FMDatabase *)database;
/**
 *  读取协议缓存
 *
 *  @param database     数据库
 *  @param isNeedReform 返回的缓存是否要reform(默认为YES)
 *
 *  @return 返回读取到的缓存数据
 */
- (id)readCacheWithDatabase:(FMDatabase *)database task:(ZQApiTask *)task isNeedReform:(BOOL *)isNeedReform;
/**
 *  保存协议缓存
 *
 *  @param reformData 转换格式后的请求数据
 */
- (void)saveCacheWithDatabase:(FMDatabase *)database task:(ZQApiTask *)task;

@end


#pragma mark - ZQApiManager

@interface ZQApiManager : NSObject
/**
 *  公共接口管理单例对象
 */
+ (instancetype)shareApiManager;
/**
 *  公共处理句柄
 */
@property (strong, nonatomic) id<ZQApiManagerProtocol> publicHandle;
/**
 *  数据库处理对象
 */
@property (strong, nonatomic, readonly) FMDatabase *database;
/**
 *  网络请求处理对象
 */
@property (strong, nonatomic, readonly) AFHTTPSessionManager *manager;
/**
 *  网络状态
 */
@property (assign, nonatomic, readonly) ZQNetReachabilityStatus netReachabilityStatus;
/**
 *  baseUrl
 */
@property (copy, nonatomic) NSString *baseURLString;
/**
 *  支持处理的的数据类型,例:@"text/html",@"text/json",@"application/json"等
 */
@property (strong, nonatomic) NSSet *acceptableContentTypes;
/**
 *  默认请求超时时间(默认为20.0)
 */
@property (assign, nonatomic) NSTimeInterval shareTimeoutInterval;
/**
 *  当前请求超时时间
 */
@property (assign, nonatomic) NSTimeInterval currentTimeoutInterval;
/**
 *  网络活动指示器开启状态(默认为YES)
 */
@property (assign, nonatomic) BOOL networkActivityIndicatorEnabled;
/**
 *  取消所有请求
 */
- (void)cancelAllRequest;
/**
 *  开始监测网络变化(默认开启)
 */
- (void)startMonitoring;

/**
 *  停止监测网络变化
 */
- (void)stopMonitoring;

/**
 *  Get请求网络
 *
 *  @param url           请求Url
 *  @param params        参数
 *  @param success       成功回调
 *  @param failure       失败回调
 *
 *  @return 返回任务
 */
- (NSURLSessionDataTask *)get:(NSString *)url
                       params:(id)params
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;
/**
 *  Post请求网络
 *
 *  @param url           请求Url
 *  @param params        参数
 *  @param success       成功回调
 *  @param failure       失败回调
 *
 *  @return 返回任务
 */
- (NSURLSessionDataTask *)post:(NSString *)url
                        params:(id)params
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;
/**
 *  Post上传文件
 *
 *  @param url           请求Url
 *  @param params        参数
 *  @param formDataBlock 文件操作回调
 *  @param progress      进度回调
 *  @param success       成功回调
 *  @param failure       失败回调
 *
 *  @return 返回任务
 */
- (NSURLSessionDataTask *)post:(NSString *)url
                        params:(id)params
                 formDataBlock:(void (^)(id<ZQMultipartFormData> formData))formDataBlock
                      progress:(void (^)(NSProgress *uploadProgress))progress
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end
