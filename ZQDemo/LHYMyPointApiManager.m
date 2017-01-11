//
//  LHYMyPointApiManager.m
//  OOLaGongYi
//
//  Created by YueHui on 16/10/25.
//  Copyright © 2016年 GZ Leihou Software Development CO.,LTD. All rights reserved.
//

#import "LHYMyPointApiManager.h"

@implementation LHYMyPointApiManager

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    urlString = @"my/my-credits";
//    requestType = ZQApiRequestTypePostFile;
    
    return self;
}

- (ZQApiTask *)loadData
{
    params[@"token"] = @"d05912a76843cc391d8960fc1c058a2d";
    
    [self setProgressBlock:^(NSProgress *uploadProgress) {
        NSLog(@"%f", uploadProgress.fractionCompleted);
    }];
    autoResume = YES;
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
