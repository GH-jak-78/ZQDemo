

#import "ZQInterlock.h"

@interface ZQInterlock ()

@property (assign, nonatomic) BOOL isTop;
@property (assign, nonatomic) BOOL isBottom;

@property (assign, nonatomic) CGFloat contentOffsetY;
@property (assign, nonatomic) CGFloat panTranslationY;

@property (weak, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (weak, nonatomic) UIScrollView *currentScrollView;

@property (strong, nonatomic) NSMutableArray *scrollViews;

@end

@implementation ZQInterlock

- (void)dealloc
{
    for (UIScrollView *scrollView in self.scrollViews) {
        [scrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
}

- (instancetype)initWithSourceView:(UIView *)sourceView targetView:(UIView *)targetView translationHeight:(CGFloat)translationHeight
{
    if (self = [super init]) {
        self.sourceView = sourceView;
        self.targetView = targetView;
        self.translationHeight = translationHeight;
        self.scrollViews = [NSMutableArray array];
    }
    return self;
}

- (void)registerScrollViews:(NSArray<UIScrollView *> *)scrollViews
{
    for (UIScrollView *scrollView in scrollViews) {
        scrollView.bounces = YES;
        scrollView.alwaysBounceVertical = YES;
        [scrollView.panGestureRecognizer addTarget:self action:@selector(scrollViewPanGestureRecognizer:)];
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
    [self.scrollViews addObjectsFromArray:scrollViews];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    [self scrollViewDidScroll:object];
}

- (void)scrollViewPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
{
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.currentScrollView = (UIScrollView *)panGestureRecognizer.view;
        self.contentOffsetY = self.currentScrollView.contentOffset.y;
    }
}

- (void)targetViewPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
{
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.panTranslationY = 0.0;
    }
    else {
        CGFloat panY = [panGestureRecognizer translationInView:panGestureRecognizer.view].y;
        [self setTranslationHeight:self.panTranslationY - panY];
        self.panTranslationY = panY;
    }
}

- (void)setTranslationHeight:(CGFloat)translationInterval
{
    CGFloat translationHeight = -self.targetView.transform.ty + translationInterval;
    
    if (translationHeight < 0.0) {
        translationHeight = 0.0;
        self.isBottom = YES;
    }
    else {
        self.isBottom = NO;
    }
    if (translationHeight > self.translationHeight) {
        translationHeight = self.translationHeight;
        self.isTop = YES;
        if (self.currentScrollView.isDragging) {
            self.panGestureRecognizer.enabled = NO;
        }
    }
    else {
        self.isTop = NO;
        if (self.currentScrollView.isDragging) {
            self.panGestureRecognizer.enabled = YES;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(interlock:didTranslationWithTranslationHeight:)]) {
        [self.delegate interlock:self didTranslationWithTranslationHeight:translationHeight];
    }
    
    self.targetView.transform = CGAffineTransformMakeTranslation(0.0, -translationHeight);
    self.sourceView.transform = CGAffineTransformMakeTranslation(0.0, -translationHeight);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (![scrollView isEqual:self.currentScrollView]) {
        return;
    }
    CGFloat translationDistance = scrollView.contentOffset.y - self.contentOffsetY;

    if (translationDistance == 0.0) {
        return;
    }
    if ((!self.isTop && !self.isBottom && (translationDistance > 0.0 || scrollView.contentOffset.y < 0.0))
        || (self.isTop && translationDistance < 0.0 && scrollView.contentOffset.y < 0.0)
        || (self.isBottom && translationDistance > 0.0 && scrollView.contentOffset.y > 0.0)) {
        
        [self setTranslationHeight:translationDistance];
        [scrollView setContentOffset:CGPointMake(0.0, self.contentOffsetY)];
    }
    self.contentOffsetY = scrollView.contentOffset.y;
}

- (void)setTargetView:(UIView *)targetView
{
    _targetView = targetView;
    
    if (self.panGestureRecognizer) {
        [self.panGestureRecognizer.view removeGestureRecognizer:self.panGestureRecognizer];
    }
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(targetViewPanGestureRecognizer:)];
    [targetView addGestureRecognizer:panGestureRecognizer];
    self.panGestureRecognizer = panGestureRecognizer;
}

@end
