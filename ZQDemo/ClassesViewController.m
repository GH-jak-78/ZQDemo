//
//  ClassesViewController.m
//  ZQDemo
//
//  Created by ZhaoQu on 16/9/13.
//  Copyright © 2016年 ZQ. All rights reserved.
//

#import "ClassesViewController.h"

#import "ZQInterlock.h"
#import "Masonry.h"
#import "ZQClassesView.h"

#import "UINavigationBar+BackgroundAlpha.h"

@interface ClassesViewController () <ZQClassesViewDelegate, ZQInterlockDelegate>

@property (strong, nonatomic) ZQInterlock *interlock;
@property (strong, nonatomic) ZQClassesView *classesView;

@property (copy, nonatomic) NSArray *classes;

@end

@implementation ClassesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    self.classesView = [[ZQClassesView alloc]init];
    self.classesView.delegate = self;
    self.classesView.classes = self.classes;
    
    UIImageView *headerView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"img_01"]];
    
    self.interlock = [[ZQInterlock alloc]initWithSourceView:self.classesView targetView:headerView translationHeight:200.0 - 64.0];
    self.interlock.delegate = self;
    [self.interlock registerScrollViews:@[self.classesView.verticalView, self.classesView.contentView]];
    
    [self.view addSubview:headerView];
    [self.view addSubview:self.classesView];
    
    [headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.offset(0.0);
        make.height.offset(200.0);
    }];
    [self.classesView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(headerView.mas_bottom);
        make.left.right.offset(0.0);
        make.height.offset([UIScreen mainScreen].bounds.size.height - 64.0);
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self interlock:self.interlock didTranslationWithTranslationHeight:self.interlock.currentTranslationHeight];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar resetBackgroundAlpha];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)interlock:(ZQInterlock *)interlock didTranslationWithTranslationHeight:(CGFloat)translationHeight
{
    [self.navigationController.navigationBar setBackgroundAlpha:translationHeight / (200.0 - 64.0)];
}

- (void)classesView:(ZQClassesView *)classesView itemDidTouchWith:(ZQClasses *)classes
{
    NSLog(@"%@", classes.title);
}

- (NSArray *)classes
{
    if (_classes == nil) {
        
        ZQClasses *cls1 = [[ZQClasses alloc]init];
        cls1.title = @"电子电器";
        
        ZQClasses *cls101 = [[ZQClasses alloc]init];
        cls101.title = @"手机";
        cls101.descString = @"产品描述";
        cls101.iconUrl = @"shouyye_img";
        ZQClasses *cls102 = [[ZQClasses alloc]init];
        cls102.title = @"平板电脑";
        cls102.descString = @"产品描述";
        cls102.iconUrl = @"shouyye_img";
        ZQClasses *cls103 = [[ZQClasses alloc]init];
        cls103.title = @"照相机";
        cls103.descString = @"产品描述";
        cls103.iconUrl = @"shouyye_img";
        ZQClasses *cls104 = [[ZQClasses alloc]init];
        cls104.title = @"照相机";
        cls104.descString = @"产品描述";
        cls104.iconUrl = @"shouyye_img";
        ZQClasses *cls105 = [[ZQClasses alloc]init];
        cls105.title = @"苹果";
        cls105.descString = @"产品描述";
        cls105.iconUrl = @"shouyye_img";
        ZQClasses *cls106 = [[ZQClasses alloc]init];
        cls106.title = @"三星";
        cls106.descString = @"产品描述";
        cls106.iconUrl = @"shouyye_img";
        ZQClasses *cls107 = [[ZQClasses alloc]init];
        cls107.title = @"手机";
        cls107.descString = @"产品描述";
        cls107.iconUrl = @"shouyye_img";
        ZQClasses *cls108 = [[ZQClasses alloc]init];
        cls108.title = @"平板电脑";
        cls108.descString = @"产品描述";
        cls108.iconUrl = @"shouyye_img";
        ZQClasses *cls109 = [[ZQClasses alloc]init];
        cls109.title = @"照相机";
        cls109.descString = @"产品描述";
        cls109.iconUrl = @"shouyye_img";
        ZQClasses *cls110 = [[ZQClasses alloc]init];
        cls110.title = @"照相机";
        cls110.descString = @"产品描述";
        cls110.iconUrl = @"shouyye_img";
        ZQClasses *cls111 = [[ZQClasses alloc]init];
        cls111.title = @"苹果";
        cls111.descString = @"产品描述";
        cls111.iconUrl = @"shouyye_img";
        ZQClasses *cls112 = [[ZQClasses alloc]init];
        cls112.title = @"三星";
        cls112.descString = @"产品描述";
        cls112.iconUrl = @"shouyye_img";
        ZQClasses *cls113 = [[ZQClasses alloc]init];
        cls113.title = @"华为";
        cls113.descString = @"产品描述";
        cls113.iconUrl = @"shouyye_img";
        ZQClasses *cls114 = [[ZQClasses alloc]init];
        cls114.title = @"OPPO";
        cls114.descString = @"产品描述";
        cls114.iconUrl = @"shouyye_img";
        ZQClasses *cls115 = [[ZQClasses alloc]init];
        cls115.title = @"小米";
        cls115.descString = @"产品描述";
        cls115.iconUrl = @"shouyye_img";
        ZQClasses *cls116 = [[ZQClasses alloc]init];
        cls116.title = @"诺基亚";
        cls116.descString = @"产品描述";
        cls116.iconUrl = @"shouyye_img";
        
        ZQClasses *cls2 = [[ZQClasses alloc]init];
        cls2.title = @"其他产品";
        ZQClasses *cls21 = [[ZQClasses alloc]init];
        cls21.title = @"cls21";
        ZQClasses *cls22 = [[ZQClasses alloc]init];
        cls22.title = @"cls22";
        ZQClasses *cls3 = [[ZQClasses alloc]init];
        cls3.title = @"其他产品";
        ZQClasses *cls31 = [[ZQClasses alloc]init];
        cls31.title = @"cls31";
        ZQClasses *cls32 = [[ZQClasses alloc]init];
        cls32.title = @"cls32";
        ZQClasses *cls4 = [[ZQClasses alloc]init];
        cls4.title = @"其他产品";
        ZQClasses *cls41 = [[ZQClasses alloc]init];
        cls41.title = @"cls41";
        ZQClasses *cls42 = [[ZQClasses alloc]init];
        cls42.title = @"cls42";
        ZQClasses *cls5 = [[ZQClasses alloc]init];
        cls5.title = @"其他产品";
        ZQClasses *cls51 = [[ZQClasses alloc]init];
        cls51.title = @"cls51";
        ZQClasses *cls52 = [[ZQClasses alloc]init];
        cls52.title = @"cls52";
        ZQClasses *cls6 = [[ZQClasses alloc]init];
        cls6.title = @"其他产品";
        ZQClasses *cls61 = [[ZQClasses alloc]init];
        cls61.title = @"cls61";
        ZQClasses *cls62 = [[ZQClasses alloc]init];
        cls62.title = @"cls62";
        ZQClasses *cls7 = [[ZQClasses alloc]init];
        cls7.title = @"其他产品";
        ZQClasses *cls71 = [[ZQClasses alloc]init];
        cls71.title = @"cls71";
        ZQClasses *cls72 = [[ZQClasses alloc]init];
        cls72.title = @"cls72";
        ZQClasses *cls8 = [[ZQClasses alloc]init];
        cls8.title = @"其他产品";
        ZQClasses *cls81 = [[ZQClasses alloc]init];
        cls81.title = @"cls81";
        ZQClasses *cls82 = [[ZQClasses alloc]init];
        cls82.title = @"cls82";
        
        
        ZQClasses *cls9 = [[ZQClasses alloc]init];
        cls9.title = @"其他产品";
        ZQClasses *cls10 = [[ZQClasses alloc]init];
        cls10.title = @"其他产品";
        ZQClasses *cls11 = [[ZQClasses alloc]init];
        cls11.title = @"其他产品";
        ZQClasses *cls12 = [[ZQClasses alloc]init];
        cls12.title = @"其他产品";
        ZQClasses *cls13 = [[ZQClasses alloc]init];
        cls13.title = @"其他产品";
        ZQClasses *cls14 = [[ZQClasses alloc]init];
        cls14.title = @"其他产品";
        ZQClasses *cls15 = [[ZQClasses alloc]init];
        cls15.title = @"其他产品";
        ZQClasses *cls16 = [[ZQClasses alloc]init];
        cls16.title = @"其他产品";
        ZQClasses *cls17 = [[ZQClasses alloc]init];
        cls17.title = @"其他产品";
        ZQClasses *cls18 = [[ZQClasses alloc]init];
        cls18.title = @"其他产品";
        ZQClasses *cls19 = [[ZQClasses alloc]init];
        cls19.title = @"其他产品";
        
        cls1.childClasses = @[cls101, cls102, cls103, cls104, cls105, cls106, cls107, cls108, cls109, cls110, cls111, cls112, cls113, cls114, cls115, cls116];
        cls2.childClasses = @[cls21, cls22];
        cls3.childClasses = @[cls31, cls32];
        cls4.childClasses = @[cls41, cls42];
        cls5.childClasses = @[cls51, cls52];
        cls6.childClasses = @[cls61, cls62];
        cls7.childClasses = @[cls71, cls72];
        cls8.childClasses = @[cls81, cls82];
        
        
        _classes = @[cls1, cls2, cls3, cls4, cls5, cls6, cls7, cls8, cls9, cls10, cls11, cls12, cls13, cls14, cls15, cls16, cls17, cls18, cls19];
    }
    return _classes;
}

@end
