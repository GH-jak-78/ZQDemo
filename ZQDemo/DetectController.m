//
//  DetectController.m
//  ZQDemo
//
//  Created by ZhaoQu on 16/9/18.
//  Copyright © 2016年 ZQ. All rights reserved.
//

#import "DetectController.h"

#import "ZQDetect.h"
#import "Masonry.h"

@interface DetectController () <ZQDetectDelegate>

@property (strong, nonatomic) ZQDetect *detect;

@end

@implementation DetectController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"切换" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonItemDidTouch)];
    
    self.detect = [[ZQDetect alloc]initWithDetectTypes:@[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code]];
    self.detect.delegate = self;
    self.detect.detectRect = CGRectMake((375 - 200), 100, 200, 100);
    self.detect.cameraPosition = ZQCameraPositionBack;
    self.detect.detectView.backgroundColor = [UIColor redColor];
    
    UIView *rectView = [[UIView alloc]initWithFrame:self.detect.detectRect];
    rectView.layer.borderWidth = 2;
    rectView.layer.borderColor = [UIColor blueColor].CGColor;
    
    
    [self.view addSubview:self.detect.detectView];
    [self.view addSubview:rectView];
    
    self.detect.detectView.frame = self.view.bounds;
//    [self.detect.detectView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.insets(UIEdgeInsetsZero);
//    }];
    
    [self.detect startRunning];
}

- (void)rightBarButtonItemDidTouch
{
    [self.detect transitionCamera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)detect:(ZQDetect *)detect didDetectCodeWithCodeString:(NSString *)codeString
{
    NSLog(@"%@", codeString);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.detect startRunning];
    });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
