
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, ZQCameraPosition)
{
    ZQCameraPositionBack                = 1,
    ZQCameraPositionFront               = 2
};

@interface ZQDetectView : UIView

@end


@class ZQDetect;

@protocol ZQDetectDelegate <NSObject>

@optional
// 稳定检测到人脸时调用
- (void)detect:(ZQDetect *)detect didDetectFaceWithFaceImage:(UIImage *)faceImage;
// 检测到二维码/条码时调用
- (void)detect:(ZQDetect *)detect didDetectCodeWithCodeString:(NSString *)codeString;

@end

@interface ZQDetect : NSObject

// 代理
@property (weak, nonatomic) id<ZQDetectDelegate> delegate;

// 检测主视图
@property (strong, nonatomic, readonly) ZQDetectView *detectView;

// 检测区域(在detectView的实际Rect) 默认是整个detectView范围
@property (assign, nonatomic) CGRect detectRect;

// 摄像头方向
@property (assign, nonatomic) ZQCameraPosition cameraPosition;

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

@end
