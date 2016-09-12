
#import <UIKit/UIKit.h>

#define LHYItemsViewLineH 2.0

@class ZQPaginationController;

@protocol ZQPaginationControllerDelegate <NSObject>

@optional
- (void)paginationController:(ZQPaginationController *)paginationController didChangedPageAtIndex:(NSInteger)index;
- (void)paginationController:(ZQPaginationController *)paginationController willChangePageAtIndex:(NSInteger)index;

@end

@interface ZQPaginationController : UIViewController

@property (weak, nonatomic) id<ZQPaginationControllerDelegate> delegate;

// 导航View
@property (strong, nonatomic, readonly) UIView *itemsView;
// 定制itemView
@property (strong, nonatomic) UIColor *itemTextColor;
@property (strong, nonatomic) UIFont *itemTextFont;
@property (strong, nonatomic) UIColor *backLineColor;
@property (strong, nonatomic) UIColor *selectLineColor;

@property (assign, nonatomic, getter=isAnimateChangedItem) BOOL animateChangedItem; // 默认YES
@property (assign, nonatomic, getter=isAnimateChangedPage) BOOL animateChangedPage; // 默认YES

- (instancetype)initWithChildControllers:(NSArray *)childControllers;

- (void)selectPageAtIndex:(NSInteger)index;

@end
