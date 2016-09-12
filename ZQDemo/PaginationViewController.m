//
//  PaginationViewController.m
//  ZQDemo
//
//  Created by ZhaoQu on 16/9/9.
//  Copyright © 2016年 ZQ. All rights reserved.
//

#import "PaginationViewController.h"
#import "Masonry.h"

@interface PaginationViewController ()

@end

@implementation PaginationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.itemsView];
    
    
//    self.itemsView.frame = CGRectMake(0, 0, 300, 44.0);
    
    [self.itemsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(0);
        make.left.right.offset(0);
        make.height.offset(44);
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
