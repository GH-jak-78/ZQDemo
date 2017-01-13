
#import "ZQApiManager.h"
#import "UIKit+AFNetworking.h"

NSString * const ZQNetStatusKey = @"ZQNetStatusKey";
NSString * const ZQNetReachabilityStatusNotification = @"ZQNetReachabilityStatusNotification";

NSString * const ZQApiErrorDomain = @"ZQApiErrorDomain";

@interface ZQApiManager ()

@property (strong, nonatomic) AFHTTPSessionManager *manager;
@property (strong, nonatomic) FMDatabase *database;

@end

@implementation ZQApiManager

static ZQApiManager *apiManager;

#pragma mark - 单例

- (void)dealloc
{
    [self.database close];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        apiManager = [super allocWithZone:zone];
    });
    return apiManager;
}

+ (id)copyWithZone:(struct _NSZone *)zone
{
    return apiManager;
}

+ (instancetype)shareApiManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        apiManager = [[self alloc]init];
    });
    return apiManager;
}

#pragma mark - getter/setter方法

- (AFHTTPSessionManager *)manager
{
    if (_manager == nil) {
        
        if (_baseURLString) {
            _manager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:_baseURLString]];
        }
        else {
            _manager = [AFHTTPSessionManager manager];
        }
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"text/json", @"application/json", nil];
        [_manager.requestSerializer setValue:@"ZQ" forHTTPHeaderField:@"X-RNCache"];
        
        _shareTimeoutInterval = _manager.requestSerializer.timeoutInterval = 20.0;
        self.networkActivityIndicatorEnabled = YES;
        [[ZQApiManager shareApiManager] startMonitoring];
    }
    return _manager;
}

- (FMDatabase *)database
{
    if (_database == nil) {
        _database = [FMDatabase databaseWithPath:ZQDatabasePath];
        [_database open];
        
        [_database executeStatements:@"CREATE TABLE IF NOT EXISTS t_auto_task_cache (task_id text PRIMARY KEY NOT NULL, task_date integer NOT NULL, task_cache blob NOT NULL);"];
    }
    return _database;
}

- (void)setPublicHandle:(id<ZQApiManagerProtocol>)publicHandle
{
    _publicHandle = publicHandle;
    if ([self.publicHandle respondsToSelector:@selector(initialize)]) {
        [self.publicHandle initialize];
    }
    if ([self.publicHandle respondsToSelector:@selector(configureDatabase:)]) {
        [self.publicHandle configureDatabase:self.database];
    }
}

#pragma mark - 网络状态检测

- (void)startMonitoring
{
    [[AFNetworkReachabilityManager sharedManager]setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [[NSNotificationCenter defaultCenter]postNotificationName:ZQNetReachabilityStatusNotification object:nil userInfo:@{ZQNetStatusKey : @(status)}];
    }];
    
    [[AFNetworkReachabilityManager sharedManager]startMonitoring];
}

- (void)stopMonitoring
{
    [[AFNetworkReachabilityManager sharedManager]stopMonitoring];
}

- (ZQNetReachabilityStatus)netReachabilityStatus
{
    return (NSInteger)[AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
}

#pragma mark - 请求

- (NSURLSessionDataTask *)get:(NSString *)url
                       params:(id)params
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    
    return [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(task, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(task, error);
        }
    }];
}


- (NSURLSessionDataTask *)post:(NSString *)url
                        params:(id)params
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    return [self.manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(task, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(task, error);
        }
    }];
}


- (NSURLSessionDataTask *)post:(NSString *)url
                        params:(id)params
                 formDataBlock:(void (^)(id<ZQMultipartFormData> formData))block
                      progress:(void (^)(NSProgress *uploadProgress))progress
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    
    return [self.manager POST:url parameters:params constructingBodyWithBlock:block progress:progress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(task, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(task, error);
        }
    }];
}

#pragma mark - 设置

- (void)cancelAllRequest
{
    [self.manager.tasks makeObjectsPerformSelector:@selector(cancel)];
}

- (NSSet *)acceptableContentTypes
{
    return self.manager.responseSerializer.acceptableContentTypes;
}
- (void)setAcceptableContentTypes:(NSSet *)acceptableContentTypes
{
    self.manager.responseSerializer.acceptableContentTypes = acceptableContentTypes;
}

- (void)setBaseURLString:(NSString *)baseURLString
{
    _baseURLString = [baseURLString copy];
    
    _manager = nil;
}

- (void)setNetworkActivityIndicatorEnabled:(BOOL)networkActivityIndicatorEnabled
{
    _networkActivityIndicatorEnabled = networkActivityIndicatorEnabled;
    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = networkActivityIndicatorEnabled;
}

- (NSTimeInterval)currentTimeoutInterval
{
    return self.manager.requestSerializer.timeoutInterval;
}

- (void)setCurrentTimeoutInterval:(NSTimeInterval)currentTimeoutInterval
{
    self.manager.requestSerializer.timeoutInterval = currentTimeoutInterval;
}

@end
