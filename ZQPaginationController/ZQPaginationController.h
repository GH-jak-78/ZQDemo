//
//  LHYSelectPageController.h
//  ShiXingBang
//
//  Created by ZhaoQu on 16/7/11.
//  Copyright © 2016年 ZhaoQu. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LHYItemsViewLineH 2.0

@class LHYSelectPageController;

@protocol LHYSelectPageControllerDelegate <NSObject>

@optional
- (void)selectPageController:(LHYSelectPageController *)selectPageController didChangedPageAtIndex:(NSInteger)index;
- (void)selectPageController:(LHYSelectPageController *)selectPageController willChangePageAtIndex:(NSInteger)index;

@end

@interface LHYSelectPageController : UIViewController

@property (weak, nonatomic) id<LHYSelectPageControllerDelegate> delegate;

@property (strong, nonatomic) UIColor *itemTextColor;
@property (strong, nonatomic) UIFont *itemTextFont;
@property (strong, nonatomic) UIColor *backLineColor;
@property (strong, nonatomic) UIColor *selectLineColor;

@property (strong, nonatomic, readonly) UIView *itemsView;

- (instancetype)initWithChildControllers:(NSArray *)childControllers;

- (void)selectPageAtIndex:(NSInteger)index;

@end
