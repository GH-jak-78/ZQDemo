//
//  ZQClassesView.h
//  ShiXingBang
//
//  Created by ZhaoQu on 16/7/14.
//  Copyright © 2016年 ZhaoQu. All rights reserved.
//

#import <UIKit/UIKit.h>

#define VerticalCellW 84.0
#define VerticalCellH 44.0

@class ZQClasses;
@class ZQClassesView;

@protocol ZQClassesViewDelegate <NSObject>

@optional
- (void)classesView:(ZQClassesView *)classesView itemDidTouchWith:(ZQClasses *)classes;

@end


@interface ZQClassesView : UIView

@property (assign, nonatomic) id<ZQClassesViewDelegate> delegate;

@property (strong, nonatomic, readonly) UITableView *verticalView;
@property (strong, nonatomic, readonly) UICollectionView *contentView;

@property (copy, nonatomic) NSArray *classes;

@end


@interface ZQClasses : NSObject

@property (copy, nonatomic) NSString *title;

@property (copy, nonatomic) NSString *iconUrl;

@property (copy, nonatomic) NSString *descString;

@property (copy, nonatomic) NSArray *childClasses;

@end


@interface ZQClassesVerticalCell : UITableViewCell

@property (strong, nonatomic) UILabel *titleLabel;

@end


@interface ZQClassesVerticalFooterView : UITableViewHeaderFooterView

@property (strong, nonatomic) UILabel *titleLabel;

@end


@interface ZQClassesContentCell : UICollectionViewCell

@property (strong, nonatomic) ZQClasses *classes;

@end


@interface ZQClassesContentHeaderView : UICollectionReusableView

@property (strong, nonatomic) UILabel *titleLabel;

@end
