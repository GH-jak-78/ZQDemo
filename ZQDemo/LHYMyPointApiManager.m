//
//  LHYMyPointApiManager.m
//  OOLaGongYi
//
//  Created by YueHui on 16/10/25.
//  Copyright © 2016年 GZ Leihou Software Development CO.,LTD. All rights reserved.
//

#import "LHYMyPointApiManager.h"

@implementation LHYMyPointApiManager

- (void)initialize
{
    urlString = @"my/my-credits";
    
    // requestType = ZQApiRequestTypePostFile;
    [self setProgressBlock:^(NSProgress *uploadProgress) {
        NSLog(@"%f", uploadProgress.fractionCompleted);
    }];
    autoCache = YES;
    preferredAutoCacheTimeInterval = 5.0;
    taskIdentifierBlock = ^(ZQApiTask *task) {
        return task.urlString;
    };
}

- (ZQApiTask *)loadData
{
    params[@"token"] = @"d05912a76843cc391d8960fc1c058a2d";

    return [super loadData];
}

- (void)postFileWithFormData:(id<ZQMultipartFormData>)formData
{
    NSData *data = UIImagePNGRepresentation([UIImage imageNamed:@"img_01"]);
    [formData appendPartWithFileData:data name:@"fdf" fileName:@"fdfd" mimeType:@"image/png"];
}

- (void)changeRequestPolicy:(ZQApiRequestPolicy)apiRequestPolicy
{
    requestPolicy = apiRequestPolicy;
}

- (BOOL)isCorrectParamsWithTask:(ZQApiTask *)task errorInfo:(NSMutableDictionary *)errorInfo
{
    return YES;
}

- (BOOL)isCorrectResponseDataWithTask:(ZQApiTask *)task errorInfo:(NSMutableDictionary *)errorInfo
{
    return YES;
}

@end
