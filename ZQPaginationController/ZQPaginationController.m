//
//  LHYSelectPageController.m
//  ShiXingBang
//
//  Created by ZhaoQu on 16/7/11.
//  Copyright © 2016年 ZhaoQu. All rights reserved.
//

#import "LHYSelectPageController.h"

@interface LHYSelectPageController () <UIScrollViewDelegate>

@property (strong, nonatomic) UIView *itemsView;
@property (strong, nonatomic) NSMutableArray *items;
@property (weak, nonatomic) UIView *backLineView;
@property (weak, nonatomic) UIView *selectLineView;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) NSInteger currentIndex;

@end

@implementation LHYSelectPageController

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
        _itemTextColor = LHYColorText;
        _itemTextFont = LHYFontTitle;
        _backLineColor = LHYColorFg;
        _selectLineColor = LHYColorY;
        [self setupItemsView];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupScrollView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.scrollView.contentSize = CGSizeMake(self.childViewControllers.count * self.view.bounds.size.width, self.view.bounds.size.height);
    [self itemDidTouch:self.items[self.currentIndex]];
}

- (void)setupScrollView
{
//    self.automaticallyAdjustsScrollViewInsets = NO;// 设置无效
//    [self.view addSubview:[[UIView alloc]init]];// 起不让scrollView自动偏移的效果
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UIScrollView *scrollView = [[UIScrollView alloc]init];
    scrollView.delegate = self;
    scrollView.bounces = NO;
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    [scrollView.panGestureRecognizer addTarget:self action:@selector(panGestureRecognizer:)];
    
    [self.view addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsZero);
    }];
    
    self.scrollView = scrollView;
}

- (void)setupItemsView
{
    self.itemsView = [[UIView alloc]init];
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
        
        [itemButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.itemsView);
            make.bottom.equalTo(self.itemsView).offset(-LHYItemsViewLineH);
            if (lastView) {
                make.left.equalTo(lastView.mas_right);
                make.width.equalTo(lastView.mas_width);
            }
            if (i == 0) {
                make.left.equalTo(self.itemsView);
            }
            if (i == self.childViewControllers.count - 1) {
                make.right.equalTo(self.itemsView);
            }
        }];

        lastView = itemButton;
        
        UIView *backLineView = [[UIView alloc]init];
        backLineView.backgroundColor = self.backLineColor;
        [self.itemsView addSubview:backLineView];
        self.backLineView = backLineView;
        
        [backLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.itemsView);
            make.right.equalTo(self.itemsView);
            make.bottom.equalTo(self.itemsView);
            make.height.offset(LHYItemsViewLineH);
        }];
        
        UIView *selectLineView = [[UIView alloc]init];
        selectLineView.backgroundColor = self.selectLineColor;
        [self.itemsView addSubview:selectLineView];
        self.selectLineView = selectLineView;
        
        [self.selectLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(0.0);
            make.width.equalTo(lastView);
            make.bottom.equalTo(self.itemsView);
            make.height.offset(LHYItemsViewLineH);
        }];
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
    if (!scrollView.isDragging) {
        return;
    }
    [self.selectLineView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.offset(scrollView.contentOffset.x * (self.itemsView.width / self.childViewControllers.count / scrollView.width));
    }];
    [self.itemsView setNeedsLayout];
    [self.itemsView layoutIfNeeded];
    
    NSInteger page = (int)((self.scrollView.contentOffset.x + self.scrollView.bounds.size.width * 0.5) / self.scrollView.bounds.size.width);
    if (page != self.currentIndex) {
        self.currentIndex = page;
        if ([self.delegate respondsToSelector:@selector(selectPageController:didChangedPageAtIndex:)]) {
            [self.delegate selectPageController:self didChangedPageAtIndex:self.currentIndex];
        }
    }
}

- (void)itemDidTouch:(UIButton *)button
{
    self.currentIndex = button.tag;
    [self willChangePageAtIndex:self.currentIndex];
    
    [self.selectLineView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.offset(self.itemsView.width / self.childViewControllers.count * self.currentIndex);
    }];
    [self.itemsView setNeedsLayout];
    [UIView animateWithDuration:0.25 animations:^{
        [self.itemsView layoutIfNeeded];
    }];
    
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.bounds.size.width * button.tag, self.scrollView.contentOffset.y)];
    
    if ([self.delegate respondsToSelector:@selector(selectPageController:didChangedPageAtIndex:)]) {
        [self.delegate selectPageController:self didChangedPageAtIndex:self.currentIndex];
    }
}

- (void)willChangePageAtIndex:(NSInteger)index
{
    UIViewController *vc = self.childViewControllers[index];
    if (![self.scrollView.subviews containsObject:vc.view]) {
        [self.scrollView addSubview:vc.view];
        vc.view.frame = CGRectMake(self.view.bounds.size.width  * index, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    }
    if ([self.delegate respondsToSelector:@selector(selectPageController:willChangePageAtIndex:)]) {
        [self.delegate selectPageController:self willChangePageAtIndex:index];
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
