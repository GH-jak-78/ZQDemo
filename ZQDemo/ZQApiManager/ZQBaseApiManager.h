//
//  ZQBaseApiManager.h
//  OOLaGongYi
//
//  Created by ZhaoQu on 16/9/27.
//  Copyright © 2016年 GZ Leihou Software Development CO.,LTD. All rights reserved.
//

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
     *  请求策略
     */
    ZQApiRequestPolicy requestPolicy;
    /**
     *  符合ZQApiManagerProtocol协议的self本身
     */
    __weak id<ZQApiManagerProtocol> child;
}

/**
 *  代理
 */
@property (weak, nonatomic) id<ZQApiManagerDelegate> delegate;

/**
 *  超时时间
 */
@property (assign, nonatomic) NSTimeInterval timeoutInterval;
/**
 *  下次请求数据来源
 */
@property (assign, nonatomic) ZQApiDataSourceType nextRequestSourceType;


@property (copy, nonatomic) void (^progressBlock)(NSProgress *uploadProgress);
@property (copy, nonatomic) void (^successBlock)(ZQApiTask *task);
@property (copy, nonatomic) void (^failureBlock)(ZQApiTask *task);

- (void)setProgressBlock:(void (^)(NSProgress *uploadProgress))progressBlock;

/**
 *  请求起飞点
 */
- (void)loadData;

+ (instancetype)apiManagerWithSuccess:(void (^)(ZQApiTask *task))success failure:(void (^)(ZQApiTask *task))failure;
- (instancetype)initWithSuccess:(void (^)(ZQApiTask *task))success failure:(void (^)(ZQApiTask *task))failure;

@end
