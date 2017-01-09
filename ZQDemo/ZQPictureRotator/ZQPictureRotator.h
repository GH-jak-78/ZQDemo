//
//  ZQPictureRotator.h
//  OOLaGongYi
//
//  Created by ZhaoQu on 16/8/22.
//  Copyright © 2016年 GZ Leihou Software Development CO.,LTD. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ZQPageControlStyle)
{
    ZQPageControlStyleNone,
    ZQPageControlStyleLeft,
    ZQPageControlStyleCenter,  // 默认
    ZQPageControlStyleRight,
};

@class ZQPictureRotator;

@protocol ZQPictureRotatorDelegate <NSObject>

@optional
- (void)pictureRotator:(ZQPictureRotator *)pictureRotator didTouchWithCurrentPage:(NSInteger)currentPage;

@end

@interface ZQPictureRotator : UIView

@property (weak, nonatomic) id<ZQPictureRotatorDelegate> delegate;

@property (strong, nonatomic, readonly) UICollectionView *collectionView;
@property (strong, nonatomic, readonly) UIPageControl *pageControl;

@property (strong, nonatomic) UIImage *placeholderImage;

@property (copy, nonatomic) NSArray *pictures;

@property (assign, nonatomic) BOOL autoTransition;                      // 默认YES
@property (assign, nonatomic) NSTimeInterval transitionTimeInterval;    // 默认5秒
@property (assign, nonatomic) ZQPageControlStyle pageControlStyle;      // 默认居中

@end
