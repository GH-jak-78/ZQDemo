//
//  LHYPublicApiManager.m
//  OOLaGongYi
//
//  Created by ZhaoQu on 16/9/28.
//  Copyright © 2016年 GZ Leihou Software Development CO.,LTD. All rights reserved.
//

#import "LHYPublicApiManager.h"
#import <CommonCrypto/CommonDigest.h>

@implementation LHYPublicApiManager

- (void)configureDatabase:(FMDatabase *)database
{
    [database executeStatements:@"CREATE TABLE IF NOT EXISTS t_setting (id integer PRIMARY KEY AUTOINCREMENT, setting_type text NOT NULL, user_id integer, setting_data blob NOT NULL);"];

}

- (void)configureParams:(NSMutableDictionary *)params withTask:(ZQApiTask *)task
{
    params[@"date"] = [NSNumber numberWithInteger:[NSDate date].timeIntervalSince1970];
    
    [params removeObjectForKey:@"kParamsMD5"];
    
    NSMutableString * paramsString = [NSMutableString string];
    NSMutableArray *array = [params.allKeys mutableCopy];
    [array sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    for (NSUInteger i = 0; i < array.count; i++)
    {
        [paramsString appendFormat:@"%@=%@&",array[i], params[array[i]]];
    }
    [paramsString appendString:@"Oola_6d689f26128004186cea1b31686a4436"];
    
    params[@"kParamsMD5"] = [self md5:paramsString];
}

- (BOOL)isCorrectParamsWithTask:(ZQApiTask *)task errorInfo:(NSMutableDictionary *)errorInfo
{
    return YES;
}

- (BOOL)isCorrectResponseDataWithTask:(ZQApiTask *)task errorInfo:(NSMutableDictionary *)errorInfo
{
    NSDictionary *dict = task.responseData;
    if ([dict[@"status"] isEqualToString:@"true"]) {
        return YES;
    }
    else {
        errorInfo[@"message"] = @"用户自定义错误信息";
        return NO;
    }
}

- (id)reformResponseData:(id)responseData withTask:(ZQApiTask *)task
{
    return responseData[@"info"];
}

- (void)requestDidSuccessWithTask:(ZQApiTask *)task
{
    NSLog(@"Public:请求成功");
}

- (void)requestDidFailureWithTask:(ZQApiTask *)task
{
    NSLog(@"Public:请求失败");
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

@end
