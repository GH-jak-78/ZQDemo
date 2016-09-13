//
//  InterLockViewController.m
//  ZQDemo
//
//  Created by ZhaoQu on 16/9/12.
//  Copyright © 2016年 ZQ. All rights reserved.
//

#import "InterLockViewController.h"
#import "ZQPaginationController.h"
#import "TableViewController.h"
#import "ZQInterlock.h"
#import "Masonry.h"

#import "UINavigationBar+BackgroundAlpha.h"

@interface InterLockViewController () <ZQInterlockDelegate, ZQPaginationControllerDelegate>

@property (strong, nonatomic) ZQInterlock *interlock;
@property (strong, nonatomic) ZQPaginationController *paginationController;

@end

@implementation InterLockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    TableViewController *vc1 = [[TableViewController alloc]init];
    vc1.title = @"vc1";
    TableViewController *vc2 = [[TableViewController alloc]init];
    vc2.title = @"vc2";
    TableViewController *vc3 = [[TableViewController alloc]init];
    vc3.title = @"vc3";
    
    self.paginationController = [[ZQPaginationController alloc]initWithChildControllers:@[vc1, vc2, vc3]];
    self.paginationController.delegate = self;
    
    UIView *headerView = [[UIView alloc]init];
    UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"img_01"]];
    
    self.interlock = [[ZQInterlock alloc]initWithSourceView:self.paginationController.view targetView:headerView translationHeight:200.0 - 64.0];
    self.interlock.delegate = self;
    [self.interlock registerScrollViews:@[vc1.tableView, vc2.tableView, vc3.tableView]];
    
    [headerView addSubview:imageView];
    [headerView addSubview:self.paginationController.itemsView];
    
    [self.view addSubview:headerView];
    [self.view addSubview:self.paginationController.view];
    [self addChildViewController:self.paginationController];
    
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.offset(0.0);
        make.height.offset(200.0);
    }];
    [self.paginationController.itemsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.offset(0.0);
        make.height.offset(44.0);
    }];
    [headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(0.0);
        make.left.right.offset(0.0);
        make.height.offset(244.0);
    }];
    [self.paginationController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(headerView.mas_bottom);
        make.left.right.offset(0.0);
        make.height.offset([UIScreen mainScreen].bounds.size.height - 64.0 - 44.0);
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

- (void)paginationController:(ZQPaginationController *)paginationController willChangePageAtIndex:(NSInteger)index
{
    if (!self.interlock.isTop) {
        TableViewController *vc = self.paginationController.childViewControllers[index];
        [vc.tableView setContentOffset:CGPointZero];
    }
    
    
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
