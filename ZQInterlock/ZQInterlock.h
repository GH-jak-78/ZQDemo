

#import <UIKit/UIKit.h>

@class ZQInterlock;

@protocol ZQInterlockDelegate <NSObject>

@optional
- (void)interlock:(ZQInterlock *)interlock didTranslationWithTranslationHeight:(CGFloat)translationHeight;

@end

@interface ZQInterlock : NSObject

@property (weak, nonatomic) id<ZQInterlockDelegate> delegate;

@property (weak, nonatomic) UIView *sourceView;
@property (weak, nonatomic) UIView *targetView;

@property (assign, nonatomic) CGFloat translationHeight;

@property (assign, nonatomic, readonly) BOOL isTop;
@property (assign, nonatomic, readonly) BOOL isBottom;

- (void)registerScrollViews:(NSArray<UIScrollView *> *)scrollViews;

- (instancetype)initWithSourceView:(UIView *)sourceView targetView:(UIView *)targetView translationHeight:(CGFloat)translationHeight;

@end
