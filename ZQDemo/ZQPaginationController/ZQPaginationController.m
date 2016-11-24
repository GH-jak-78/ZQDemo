
#import "ZQPaginationController.h"

@interface ZQPaginationController () <UIScrollViewDelegate>

@property (strong, nonatomic) UIView *itemsView;
@property (strong, nonatomic) NSMutableArray *items;
@property (weak, nonatomic) UIView *backLineView;
@property (weak, nonatomic) UIView *selectLineView;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) NSInteger currentIndex;

@property (strong, nonatomic) NSLayoutConstraint *selectLineViewLeftConstraint;

@end

@implementation ZQPaginationController

- (void)dealloc
{
    for (UIViewController *childController in self.childViewControllers) {
        [childController removeObserver:self forKeyPath:@"title"];
    }
//    LHYLog(@"");
}

- (instancetype)initWithChildControllers:(NSArray *)childControllers
{
    if (self = [super init]) {
        for (UIViewController *childController in childControllers) {
            [self addChildViewController:childController];
            [childController addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
        }
        
        _itemTextColor = [UIColor blackColor];
        _itemTextFont = [UIFont systemFontOfSize:16.0];
        _backLineColor = [UIColor lightGrayColor];
        _selectLineColor = [UIColor yellowColor];
        
        self.animateChangedItem = YES;
        self.animateChangedPage = YES;
        [self setupItemsView];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self setupScrollView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.scrollView.contentSize = CGSizeMake(self.childViewControllers.count * self.view.bounds.size.width, self.view.bounds.size.height);
    [self selectPageAtIndex:0];
}

- (void)setupScrollView
{
    UIScrollView *scrollView = [[UIScrollView alloc]init];
    scrollView.delegate = self;
    scrollView.bounces = NO;
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    [scrollView.panGestureRecognizer addTarget:self action:@selector(panGestureRecognizer:)];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    
    [self.view addConstraints:@[topConstraint, leftConstraint, bottomConstraint, rightConstraint]];
    
    self.scrollView = scrollView;
}

- (void)setupItemsView
{
    self.itemsView = [[UIView alloc]init];
    self.itemsView.backgroundColor = [UIColor whiteColor];
    self.items = [NSMutableArray arrayWithCapacity:self.childViewControllers.count];
    
    UIView *lastView = nil;
    for (NSInteger i = 0; i < self.childViewControllers.count; i++) {
        UIViewController *childController = self.childViewControllers[i];
        UIButton *itemButton = [UIButton buttonWithType:UIButtonTypeCustom];
        itemButton.tag = i;
        [itemButton setTitle:childController.title forState:UIControlStateNormal];
        [itemButton setTitleColor:self.itemTextColor forState:UIControlStateNormal];
        [itemButton.titleLabel setFont:self.itemTextFont];
        [itemButton addTarget:self action:@selector(itemDidTouch:) forControlEvents:UIControlEventTouchUpInside];
        [self.itemsView addSubview:itemButton];
        [self.items addObject:itemButton];
        
        itemButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:itemButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.itemsView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:itemButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.itemsView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        [self.itemsView addConstraints:@[topConstraint, bottomConstraint]];
        
        if (lastView) {
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:itemButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:lastView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
            NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:itemButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:lastView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
            [self.itemsView addConstraints:@[leftConstraint, widthConstraint]];
        }
        if (i == 0) {
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:itemButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.itemsView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
            [self.itemsView addConstraint:leftConstraint];
        }
        if (i == self.childViewControllers.count - 1) {
            NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:itemButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.itemsView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
            [self.itemsView addConstraint:rightConstraint];
        }

        lastView = itemButton;
        
        UIView *backLineView = [[UIView alloc]init];
        backLineView.backgroundColor = self.backLineColor;
        [self.itemsView addSubview:backLineView];
        backLineView.translatesAutoresizingMaskIntoConstraints = NO;
        self.backLineView = backLineView;
        
        {
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:backLineView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.itemsView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
            NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:backLineView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.itemsView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
            NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:backLineView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.itemsView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
            NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:backLineView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.itemsView attribute:NSLayoutAttributeHeight multiplier:0.0 constant:LHYItemsViewLineH];
            
            [self.itemsView addConstraints:@[leftConstraint, rightConstraint, bottomConstraint, heightConstraint]];
        }
        
        UIView *selectLineView = [[UIView alloc]init];
        selectLineView.backgroundColor = self.selectLineColor;
        [self.itemsView addSubview:selectLineView];
        selectLineView.translatesAutoresizingMaskIntoConstraints = NO;
        self.selectLineView = selectLineView;
        
        {
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:selectLineView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.itemsView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
            NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:selectLineView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.itemsView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
            NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:selectLineView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:lastView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
            NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:selectLineView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.backLineView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
            
            [self.itemsView addConstraints:@[leftConstraint, bottomConstraint, widthConstraint, heightConstraint]];
            self.selectLineViewLeftConstraint = leftConstraint;
        }
    }
}

- (void)itemDidTouch:(UIButton *)button
{
    [self willChangePageAtIndex:button.tag];
    self.currentIndex = button.tag;
    
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.bounds.size.width * button.tag, self.scrollView.contentOffset.y) animated:self.animateChangedPage];
    
    if ([self.delegate respondsToSelector:@selector(paginationController:didChangedPageAtIndex:)]) {
        [self.delegate paginationController:self didChangedPageAtIndex:self.currentIndex];
    }
}

- (void)panGestureRecognizer:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        NSInteger nextIndex = [panGesture velocityInView:panGesture.view].x > 0 ? self.currentIndex - 1 : self.currentIndex + 1;
        if (nextIndex >= 0 && nextIndex < self.childViewControllers.count) {
            [self willChangePageAtIndex:nextIndex];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // item选项动画
    if (scrollView.isDragging || scrollView.isDecelerating || // 制动选页时
        (self.animateChangedPage && self.animateChangedItem)) { // 当动画切页时,也会多次调用scrollViewDidScroll:,可以当成制动选页的情况
        self.selectLineViewLeftConstraint.constant = scrollView.contentOffset.x * (self.itemsView.bounds.size.width / self.childViewControllers.count / scrollView.bounds.size.width);
    }
    else { // 点击切页时
        
        self.selectLineViewLeftConstraint.constant = self.itemsView.bounds.size.width / self.childViewControllers.count * self.currentIndex;
        if (self.animateChangedItem) {
            [UIView animateWithDuration:0.25 animations:^{
                [self.itemsView layoutIfNeeded];
            }];
        }
    }
    
    
    if (!scrollView.isDragging) {
        return;
    }
    // 制动切页
    NSInteger page = (int)((self.scrollView.contentOffset.x + self.scrollView.bounds.size.width * 0.5) / self.scrollView.bounds.size.width);
    if (page != self.currentIndex) {
        self.currentIndex = page;
        if ([self.delegate respondsToSelector:@selector(paginationController:didChangedPageAtIndex:)]) {
            [self.delegate paginationController:self didChangedPageAtIndex:self.currentIndex];
        }
    }
}

- (void)willChangePageAtIndex:(NSInteger)index
{
    UIViewController *vc = self.childViewControllers[index];
    if (![self.scrollView.subviews containsObject:vc.view]) {
        [self.scrollView addSubview:vc.view];
        vc.view.frame = CGRectMake(self.view.bounds.size.width  * index, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    }
    if ([self.delegate respondsToSelector:@selector(paginationController:willChangePageAtIndex:)]) {
        [self.delegate paginationController:self willChangePageAtIndex:index];
    }
}

- (void)selectPageAtIndex:(NSInteger)index
{
    [self itemDidTouch:self.items[index]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    for (NSInteger i = 0; i < self.childViewControllers.count; i++) {
        if ([self.childViewControllers[i] isEqual:object]) {
            UIButton *itemButton = self.items[i];
            [itemButton setTitle:change[NSKeyValueChangeNewKey] forState:UIControlStateNormal];
            break;
        }
    }
}

- (void)setBackLineColor:(UIColor *)backLineColor
{
    _backLineColor = backLineColor;
    
    self.backLineView.backgroundColor = backLineColor;
}

- (void)setSelectLineColor:(UIColor *)selectLineColor
{
    _selectLineColor = selectLineColor;
    
    self.selectLineView.backgroundColor = selectLineColor;
}

- (void)setItemTextColor:(UIColor *)itemTextColor
{
    _itemTextColor = itemTextColor;
    
    for (UIButton *itemButton in self.items) {
        [itemButton setTitleColor:itemTextColor forState:UIControlStateNormal];
    }
}

- (void)setItemTextFont:(UIFont *)itemTextFont
{
    _itemTextFont = itemTextFont;
    
    for (UIButton *itemButton in self.items) {
        itemButton.titleLabel.font = itemTextFont;
    }
}

@end
