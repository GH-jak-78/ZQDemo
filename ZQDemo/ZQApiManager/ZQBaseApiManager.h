
#import <Foundation/Foundation.h>
#import "ZQApiManager.h"

@interface ZQBaseApiManager : NSObject
{
@protected
    
    /**
     *  请求URL字符串
     */
    NSString *urlString;
    /**
     *  请求参数列表
     */
    NSMutableDictionary *params;
    /**
     *  超时时间
     */
    NSTimeInterval timeoutInterval;
    /**
     *  请求方式(默认为ZQApiRequestTypePost)
     */
    ZQApiRequestType requestType;
    /**
     *  请求策略(默认为ZQApiRequestPolicyParallel)
     */
    ZQApiRequestPolicy requestPolicy;
    /**
     *  优先请求数据来源(默认为ZQApiDataSourceTypeNet,未定义时也优先请求网络)
     */
    ZQApiDataSourceType preferredRequestSourceType;
    /**
     *  下次请求数据来源(默认为ZQApiDataSourceTypeDefault)
     */
    ZQApiDataSourceType nextRequestSourceType;
    /**
     *  无网络失败时,网络正常后自动重新请求(默认为NO)
     */
    BOOL autoResume;
}

/**
 *  代理
 */
@property (weak, nonatomic) id<ZQApiManagerDelegate> delegate;

/**
 *  请求成功回调Block
 */
@property (copy, nonatomic) void (^successBlock)(ZQApiTask *task);
/**
 *  请求失败回调Block
 */
@property (copy, nonatomic) void (^failureBlock)(ZQApiTask *task);
/**
 *  上传进度回调Block
 */
@property (copy, nonatomic) void (^progressBlock)(NSProgress *uploadProgress);
/**
 *  设置上传进度回调Block
 */
- (void)setProgressBlock:(void (^)(NSProgress *uploadProgress))progressBlock;

/**
 *  请求起飞点,重写配置请求参数
 */
- (ZQApiTask *)loadData;
/**
 *  取消当前任务列表的请求
 */
- (void)cancelCurrentTasks;
/**
 *  取消某个请求
 */
- (void)cancelWithTask:(ZQApiTask *)apiTask;
/**
 *  重新开启某个请求
 */
- (ZQApiTask *)resumeWithTask:(ZQApiTask *)apiTask;

+ (instancetype)apiManagerWithSuccess:(void (^)(ZQApiTask *task))success failure:(void (^)(ZQApiTask *task))failure;
- (instancetype)initWithSuccess:(void (^)(ZQApiTask *task))success failure:(void (^)(ZQApiTask *task))failure;

@end
