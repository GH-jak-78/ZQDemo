//
//  ZQDataSource.m
//  ZQDemo
//
//  Created by ZhaoQu on 16/12/14.
//  Copyright © 2016年 ZQ. All rights reserved.
//

#import "ZQDataSource.h"

@implementation ZQDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.numberOfSections ? self.numberOfSections() : (self.isDataSourceMapSections ? self.dataSource.count : 1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.numberOfRowsInSection) {
        return self.numberOfRowsInSection(section);
    }
    return self.numberOfRowsInSection ? self.numberOfRowsInSection(section) : (self.isDataSourceMapSections ? 1 : self.dataSource.count);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger dataIndex = self.dataIndexAtIndexPath ? self.dataIndexAtIndexPath(indexPath) : (self.isDataSourceMapSections ? indexPath.section : indexPath.row);
    Class cellClass = self.cellClassAtIndexPath ? self.cellClassAtIndexPath(indexPath) : nil;
    NSString *identifier = cellClass ? NSStringFromClass(cellClass) : @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[cellClass alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    if (self.initializeCellBlock) {
        self.initializeCellBlock(cell, indexPath, self.dataSource[dataIndex]);
    }
    
    return cell;
}
- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}
- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}
- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return nil;
}
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return 0;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    
}

- (NSMutableArray *)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

@end
