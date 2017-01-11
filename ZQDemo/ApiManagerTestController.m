//
//  ApiManagerTestController.m
//  ZQDemo
//
//  Created by ZhaoQu on 17/1/10.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import "ApiManagerTestController.h"
#import "LHYMyPointApiManager.h"

@interface ApiManagerTestController ()

@property (copy, nonatomic) NSArray *datas;

@property (strong, nonatomic) LHYMyPointApiManager *getMyPointApiManager;

@end

@implementation ApiManagerTestController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"ZQApiManager";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    
    
    self.getMyPointApiManager = [LHYMyPointApiManager apiManagerWithSuccess:^(ZQApiTask *task) {
        NSLog(@"%@", task.receiveData);
    } failure:^(ZQApiTask *task) {
        NSLog(@"%@", task.error.localizedDescription);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = self.datas[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
        {
            [self.getMyPointApiManager loadData];
            break;
        }
        case 1:
        {
            for (NSInteger i = 0; i < 10; i++) {
                [self.getMyPointApiManager loadData];
            }
            break;
        }
        case 2:
        {
            [self.getMyPointApiManager cancelCurrentTasks];
            break;
        }
        case 3:
        {
            [self.getMyPointApiManager changeRequestPolicy:ZQApiRequestPolicyParallel];
            break;
        }
        case 4:
        {
            [self.getMyPointApiManager changeRequestPolicy:ZQApiRequestPolicyCancelPrevious];
            break;
        }
        case 5:
        {
            [self.getMyPointApiManager changeRequestPolicy:ZQApiRequestPolicyCancelCurrent];
            break;
        }
        case 6:
        {
            [self.getMyPointApiManager changeRequestPolicy:ZQApiRequestPolicySerialize];
            break;
        }
        default:
            break;
    }
}

- (NSArray *)datas
{
    if (_datas == nil) {
        _datas = @[@"发起一个请求", @"发起多个请求", @"取消所有请求", @"ZQApiRequestPolicyParallel", @"ZQApiRequestPolicyCancelPrevious", @"ZQApiRequestPolicyCancelCurrent", @"ZQApiRequestPolicySerialize"];
    }
    return _datas;
}

@end
