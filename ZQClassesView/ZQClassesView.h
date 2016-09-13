//
//  LHYClassesView.h
//  ShiXingBang
//
//  Created by ZhaoQu on 16/7/14.
//  Copyright © 2016年 ZhaoQu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LHYClasses;
@class LHYClassesView;

typedef NS_ENUM(NSInteger, LHYClassesContentType)
{
    LHYClassesContentTypeRecycleBrand,
    LHYClassesContentTypeStoreProduct,
};

@protocol LHYClassesViewDelegate <NSObject>

@optional
- (void)classesView:(LHYClassesView *)classesView itemDidTouchWith:(LHYClasses *)classes;

@end


@interface LHYClassesView : UIView

@property (assign, nonatomic) id<LHYClassesViewDelegate> delegate;

@property (strong, nonatomic, readonly) UITableView *verticalView;
@property (strong, nonatomic, readonly) UICollectionView *contentView;

@property (assign, nonatomic) LHYClassesContentType contentType;

@property (copy, nonatomic) NSArray *classes;

@end


@interface LHYClasses : NSObject

@property (copy, nonatomic) NSString *title;

@property (copy, nonatomic) NSString *urlString;

@property (copy, nonatomic) NSString *desc;

@property (copy, nonatomic) NSArray *childClasses;

@end


@interface LHYClassesVerticalCell : UITableViewCell

@property (strong, nonatomic) UILabel *titleLabel;

@end


@interface LHYClassesVerticalFooterView : UITableViewHeaderFooterView

@property (strong, nonatomic) UILabel *titleLabel;

@end


@interface LHYClassesContent1Cell : UICollectionViewCell

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIImageView *iconView;

@end

@interface LHYClassesContent2Cell : UICollectionViewCell

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) UILabel *scoreLabel;

@end


@interface LHYClassesContentHeaderView : UICollectionReusableView

@property (strong, nonatomic) UILabel *titleLabel;

@end
