
#import "ZQDetect.h"
#import <CoreMotion/CoreMotion.h>


@interface ZQDetectView ()

@property (weak, nonatomic) AVCaptureVideoPreviewLayer * previewLayer;
@property (weak, nonatomic) AVCaptureMetadataOutput * output;

@property (assign, nonatomic) ZQCameraPosition cameraPosition;

@property (assign, nonatomic) CGRect detectRect;

@end

@implementation ZQDetectView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.previewLayer) {
        self.previewLayer.frame = self.bounds;
    }
    if (!CGRectIsEmpty(self.detectRect)) {
        CGRect rect;
        if (self.cameraPosition == ZQCameraPositionBack) {
            rect = CGRectMake(self.detectRect.origin.y / self.previewLayer.frame.size.height,
                              1 - CGRectGetMaxX(self.detectRect) / self.previewLayer.frame.size.width,
                              self.detectRect.size.height / self.previewLayer.frame.size.height,
                              self.detectRect.size.width / self.previewLayer.frame.size.width);
        }
        else {
            rect = CGRectMake(self.detectRect.origin.y / self.previewLayer.frame.size.height,
                              self.detectRect.origin.x / self.previewLayer.frame.size.width,
                              self.detectRect.size.height / self.previewLayer.frame.size.height,
                              self.detectRect.size.width / self.previewLayer.frame.size.width);
        }
        self.output.rectOfInterest = rect;
    }
//    NSLog(@"%@", NSStringFromCGRect(self.output.rectOfInterest));
}

- (void)setCameraPosition:(ZQCameraPosition)cameraPosition
{
    _cameraPosition = cameraPosition;
    
    [self setNeedsLayout];
}

@end



@interface ZQDetect () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer * previewLayer;

@property (strong, nonatomic) ZQDetectView *detectView;

@property (copy, nonatomic) NSArray *detectTypes;

@property (strong, nonatomic) UIImage *faceImage;

@property (assign, nonatomic) BOOL taking;

@property (assign, nonatomic) UIInterfaceOrientation interfaceOrientation;
@property (assign, nonatomic) UIDeviceOrientation deviceOrientation;

@property (strong, nonatomic) NSMutableDictionary *faceViews;

@property (strong, nonatomic) CMMotionManager *motionManager;

@end

@implementation ZQDetect

- (instancetype)init
{
    return [self initWithDetectTypes:@[AVMetadataObjectTypeFace]];
}

- (instancetype)initWithDetectTypes:(NSArray *)detectTypes
{
    if (self = [super init])
    {
        self.detectTypes = detectTypes;
        self.cameraPosition = ZQCameraPositionFront;
        self.slowLateTakePhotoInterval = 1.0;
        self.faceViews = [NSMutableDictionary dictionary];

        self.detectView = [[ZQDetectView alloc]init];
        self.detectView.previewLayer = self.previewLayer;
        self.detectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.detectView.layer insertSublayer:self.previewLayer atIndex:0];
    }
    return self;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.taking)
    {
        UIImage *image = [self makeImageWithSampleBuffer:sampleBuffer];
        self.faceImage = image;
    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //NSLog(@"%zd", metadataObjects.count);
    //NSLog(@"%zd", self.deviceOrientation);
    if (metadataObjects.count == 0)
    {
        // 检测不到人脸时取消缓时拍照
        self.taking = NO;
        for (UIView *faceView in self.faceViews.allValues)
        {
            [faceView removeFromSuperview];
        }
        [self.faceViews removeAllObjects];
        return;
    }
    if (metadataObjects.count > 1)
    {
        // 检测到多个人脸时取消缓时拍照
        self.taking = NO;
    }
    NSMutableArray *tempFaceIds = [[self.faceViews allKeys] mutableCopy];
    [metadataObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
        if ([obj isKindOfClass:[AVMetadataFaceObject class]])
        {
            // 绘制人脸框
            AVMetadataFaceObject *faceObject = (AVMetadataFaceObject *)[self.previewLayer transformedMetadataObjectForMetadataObject:obj];
            UIView *faceView = [self faceViewWithFaceId:faceObject.faceID];
            [tempFaceIds removeObject:[NSNumber numberWithInteger:faceObject.faceID]];
            [UIView animateWithDuration:0.1 animations:^{
                faceView.frame = faceObject.bounds;
            }];
            
            // 符合条件时开始缓时拍照
            if (faceObject.bounds.size.width > MIN(self.detectView.bounds.size.width, self.detectView.bounds.size.height) * 0.5)
            {
                if (self.taking)
                {
                    // 如果已开始缓时,则不再重复缓时拍照
                    return;
                }
                self.taking = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.slowLateTakePhotoInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!self.taking)
                    {
                        // 中途取消了缓时拍照
                        return;
                    }
                    // 拍照结束
                    self.taking = NO;
                    [self.session stopRunning];
                    
                    for (UIView *faceView in self.faceViews.allValues)
                    {
                        [faceView removeFromSuperview];
                    }
                    [self.faceViews removeAllObjects];
                    if ([self.delegate respondsToSelector:@selector(detect:didDetectFaceWithFaceImage:)])
                    {
                        [self.delegate detect:self didDetectFaceWithFaceImage:self.faceImage];
                    }
                });
            }
            else
            {
                // 不符合条件时取消缓时拍照
                self.taking = NO;
            }
        }
        else  // 检测的二维码或条码
        {
            if (self.taking)
            {
                // 当检测到其它目标时取消缓时拍照
                self.taking = NO;
                return;
            }
            AVMetadataMachineReadableCodeObject *codeObject = (AVMetadataMachineReadableCodeObject *)obj;
            if ([self.delegate respondsToSelector:@selector(detect:didDetectCodeWithCodeString:)])
            {
                [self.delegate detect:self didDetectCodeWithCodeString:codeObject.stringValue];
            }
            [self.session stopRunning];
            *stop = YES;
        }
    }];
    // 移除已移出屏幕的人脸视图
    for (NSNumber *faceId in tempFaceIds)
    {
        [[self faceViewWithFaceId:faceId.integerValue] removeFromSuperview];
        [self.faceViews removeObjectForKey:faceId];
    }
}

- (void)setupVideoOrientationWithInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    self.interfaceOrientation = interfaceOrientation;
    NSLog(@"-----------%zd", self.interfaceOrientation);
    switch (interfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            break;
    }
}

- (UIImageOrientation)imageOrientation
{
    UIImageOrientation orientation;
    switch (self.deviceOrientation)
    {
        case UIDeviceOrientationPortrait:
            orientation = UIImageOrientationRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = UIImageOrientationLeft;
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientation = self.cameraPosition == ZQCameraPositionBack ? UIImageOrientationUp : UIImageOrientationDown;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = self.cameraPosition == ZQCameraPositionBack ? UIImageOrientationDown : UIImageOrientationUp;
            break;
        default:
            break;
    }
    return orientation;
}

- (void)startRunning
{
    if (self.motionManager.accelerometerAvailable)
    {
        self.motionManager.accelerometerUpdateInterval = 0.5f;
        __weak typeof(self) weakSelf = self;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * motion, NSError * error) {
            double x = motion.gravity.x;
            double y = motion.gravity.y;
            if (fabs(y) >= fabs(x))
            {
                weakSelf.deviceOrientation = y >= 0 ? UIDeviceOrientationPortraitUpsideDown : UIDeviceOrientationPortrait;
            }
            else
            {
                weakSelf.deviceOrientation = x >= 0 ? UIDeviceOrientationLandscapeRight : UIDeviceOrientationLandscapeLeft;
            }
            if (weakSelf.interfaceOrientation != [UIApplication sharedApplication].statusBarOrientation) {
                [weakSelf setupVideoOrientationWithInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
            }
        }];
    }
    [self.session startRunning];
}
- (void)stopRunning
{
    self.taking = NO;
    [self.session stopRunning];
    [self.motionManager stopDeviceMotionUpdates];
    self.motionManager = nil;
}

- (UIImage *)makeImageWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    size_t bitsPerCompornent = 8;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint32_t bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst;
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, bitsPerCompornent, bytesPerRow, colorSpace, bitmapInfo);
    CGImageRef imageRef = CGBitmapContextCreateImage(newContext);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:[self imageOrientation]];//UIImageOrientationRight];
    
    CGContextRelease(newContext);
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (UIView *)faceViewWithFaceId:(NSInteger)faceId
{
    NSNumber *fid = [NSNumber numberWithInteger:faceId];
    UIView *faceView = self.faceViews[fid];
    if (!faceView)
    {
        faceView = [[UIView alloc]initWithFrame:CGRectMake(CGRectGetMidX(self.detectView.bounds), CGRectGetMidY(self.detectView.bounds), 0, 0)];
        faceView.layer.borderWidth = 2.0;
        faceView.layer.borderColor = [UIColor blueColor].CGColor;
        faceView.alpha = 0.5;
        
        self.faceViews[fid] = faceView;
        [self.detectView addSubview:faceView];
    }
    return faceView;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == position)
        {
            return device;
        }
    }
    return nil;
}

- (void)transitionCamera
{
    self.cameraPosition = self.cameraPosition == ZQCameraPositionBack ? ZQCameraPositionFront : ZQCameraPositionBack;
}

- (void)setCameraPosition:(ZQCameraPosition)cameraPosition
{
    if (cameraPosition == _cameraPosition)
    {
        return;
    }
    _cameraPosition = cameraPosition;
    
    _detectView.cameraPosition = cameraPosition;
    
    if (_session)
    {
        self.taking = NO;
        BOOL running = self.session.isRunning;
        if (running)
        {
            [self.session stopRunning];
            for (UIView *faceView in self.faceViews.allValues)
            {
                [faceView removeFromSuperview];
            }
            [self.faceViews removeAllObjects];
        }
        for (AVCaptureDeviceInput *input in self.session.inputs)
        {
            [self.session removeInput:input];
        }
        AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:[self cameraWithPosition:(AVCaptureDevicePosition)_cameraPosition] error:nil];
        if ([self.session canAddInput:input])
        {
            [self.session addInput:input];
        }
        if (running)
        {
            [self.session startRunning];
        }
    }
}

- (AVCaptureSession *)session
{
    if (_session == nil)
    {
        //初始化链接对象
        _session = [[AVCaptureSession alloc]init];
        
        //获取摄像设备
        AVCaptureDevice * device = [self cameraWithPosition:(AVCaptureDevicePosition)self.cameraPosition];//AVCaptureDevicePositionFront AVCaptureDevicePositionBack
        
        //创建输入流
        AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        
        //创建输出流
        AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
        _detectView.output = output;
        //设置代理 在主线程里刷新
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        //创建输出流
        AVCaptureVideoDataOutput * videoOutput = [[AVCaptureVideoDataOutput alloc]init];
        //设置代理 在主线程里刷新
        //[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [videoOutput setVideoSettings:rgbOutputSettings];
        [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
        
        dispatch_queue_t mVideoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [videoOutput setSampleBufferDelegate:self queue:mVideoDataOutputQueue];
        
        [_session beginConfiguration];
        
        //高质量采集率
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        if ([_session canAddInput:input])
        {
            [_session addInput:input];
        }
        if ([_session canAddOutput:output])
        {
            [_session addOutput:output];
            //设置检测人脸
            output.metadataObjectTypes = self.detectTypes ? self.detectTypes : @[AVMetadataObjectTypeFace];//, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
        }
        if ([_session canAddOutput:videoOutput])
        {
            [_session addOutput:videoOutput];
        }
        [_session commitConfiguration];
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil)
    {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer.frame = self.detectView.bounds;
//        [self setupVideoOrientationWithInterfaceOrientation:UIInterfaceOrientationUnknown];
    }
    return _previewLayer;
}

- (CMMotionManager *)motionManager
{
    if (_motionManager == nil)
    {
        _motionManager = [[CMMotionManager alloc]init];
    }
    return _motionManager;
}

- (void)setDetectRect:(CGRect)detectRect
{
    _detectRect = detectRect;
    _detectView.detectRect = detectRect;
    [_detectView setNeedsLayout];
}

@end


