//
//  LHYFaceDetectView.h
//  人脸识别
//
//  Created by ZhaoQu on 16/1/25.
//  Copyright © 2016年 ZhaoQu. All rights reserved.
//


#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LHYCameraPosition)
{
    LHYCameraPositionBack                = 1,
    LHYCameraPositionFront               = 2
};

@class LHYDetect;

@protocol LHYDetectDelegate <NSObject>

@optional
// 稳定检测到人脸时调用
- (void)detect:(LHYDetect *)detect didDetectFaceWithFaceImage:(UIImage *)faceImage;
// 检测到二维码/条码时调用
- (void)detect:(LHYDetect *)detect didDetectCodeWithCodeString:(NSString *)codeString;

@end

@interface LHYDetect : NSObject

// 代理
@property (weak, nonatomic) id<LHYDetectDelegate> delegate;

// 检测主视图
@property (strong, nonatomic, readonly) UIView *detectView;

// 最后检测到人脸的拍照
@property (strong, nonatomic, readonly) UIImage *faceImage;

// 摄像头方向
@property (assign, nonatomic) LHYCameraPosition cameraPosition;

// 缓时拍照时间
@property (assign, nonatomic) NSTimeInterval slowLateTakePhotoInterval;

// 开始检测
- (void)startRunning;
// 结束检测
- (void)stopRunning;

// 切换前后摄像头
- (void)transitionCamera;

// 根据检测类型初始化, init默认为人脸检测
// 支持检测的数据类型 AVMetadataObjectTypeFace AVMetadataObjectTypeQRCode AVMetadataObjectTypeEAN13Code AVMetadataObjectTypeEAN8Code AVMetadataObjectTypeCode128Code
- (instancetype)initWithDetectTypes:(NSArray *)detectTypes;

// 如果支持转屏,需在控制器的同名方法中调用此方法
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;

@end
