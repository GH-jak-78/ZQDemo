//
//  ZQDataSource.h
//  ZQDemo
//
//  Created by ZhaoQu on 16/12/14.
//  Copyright © 2016年 ZQ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZQDataSource : NSObject <UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray *dataSource;

// 当为YES时,即dataSource里的Object序列对应section序列,默认为NO
@property (assign, nonatomic, getter=isDataSourceMapSections) BOOL dataSourceMapSections;

@property (copy, nonatomic) NSInteger (^numberOfSections)();

@property (copy, nonatomic) NSInteger (^numberOfRowsInSection)(NSInteger section);

@property (copy, nonatomic) NSInteger (^dataIndexAtIndexPath)(NSIndexPath *indexPath);

@property (copy, nonatomic) Class (^cellClassAtIndexPath)(NSIndexPath *indexPath);

@property (copy, nonatomic) void (^initializeCellBlock)(UITableViewCell *cell, NSIndexPath *indexPath, id data);

@end
