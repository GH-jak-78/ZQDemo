//
//  ViewController.m
//  ZQDemo
//
//  Created by ZhaoQu on 16/9/7.
//  Copyright © 2016年 ZQ. All rights reserved.
//

#import "ViewController.h"
#import "PaginationViewController.h"
#import "InterLockViewController.h"
#import "ClassesViewController.h"
#import "DetectController.h"

@interface ViewController ()

@property (copy, nonatomic) NSArray *datas;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Demo";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = self.datas[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
        {
            UIViewController *vc1 = [[UIViewController alloc]init];
            vc1.title = @"vc1";
            vc1.view.backgroundColor = [UIColor redColor];
            UIViewController *vc2 = [[UIViewController alloc]init];
            vc2.title = @"vc2";
            vc2.view.backgroundColor = [UIColor blueColor];
            UIViewController *vc3 = [[UIViewController alloc]init];
            vc3.title = @"vc3";
            vc3.view.backgroundColor = [UIColor greenColor];
            
            PaginationViewController *pvc = [[PaginationViewController alloc]initWithChildControllers:@[vc1, vc2, vc3]];
            [self.navigationController pushViewController:pvc animated:YES];
            break;
        }
        case 1:
        {
            InterLockViewController *vc = [[InterLockViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
            
            break;
        }
        case 2:
        {
            ClassesViewController *vc = [[ClassesViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
            
            break;
        }
        case 3:
        {
            DetectController *vc = [[DetectController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
            
            break;
        }
        default:
            break;
    }
}

- (NSArray *)datas
{
    if (_datas == nil) {
        _datas = @[@"分页导航", @"悬浮Tab效果", @"分类视图", @"检测人脸/二维码/条码"];
    }
    return _datas;
}

@end
