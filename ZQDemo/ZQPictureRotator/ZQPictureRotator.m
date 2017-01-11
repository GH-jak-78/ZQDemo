//
//  ZQPictureRotator.m
//  OOLaGongYi
//
//  Created by ZhaoQu on 16/8/22.
//  Copyright © 2016年 GZ Leihou Software Development CO.,LTD. All rights reserved.
//

#import "ZQPictureRotator.h"
#import "UIKit+AFNetworking.h"

@interface ZQPictureCell : UICollectionViewCell

@property (strong, nonatomic) UIImageView *imageView;

@end
@implementation ZQPictureCell


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    self.imageView = [[UIImageView alloc]init];
    
    [self.contentView addSubview:self.imageView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}

@end


@interface ZQPictureRotator () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) UIImageView *bgView;

@property (assign, nonatomic) NSInteger totalPage;
@property (assign, nonatomic) NSInteger currentPage;

@end

@implementation ZQPictureRotator

- (void)dealloc
{
//    NSLog(@"ZQPictureRotator-dealloc");
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.bgView.frame = self.bounds;
    self.collectionView.frame = self.bounds;
    ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).itemSize = self.bounds.size;
    
    
    switch (self.pageControlStyle) {
        case ZQPageControlStyleNone:
            self.pageControl.hidden = YES;
            break;
        case ZQPageControlStyleCenter:
            self.pageControl.hidden = NO;
            self.pageControl.frame = CGRectMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(self.pageControl.bounds)) * 0.5, CGRectGetHeight(self.bounds) - 20.0, 0.0, 0.0);
            break;
        case ZQPageControlStyleLeft:
            self.pageControl.hidden = NO;
            self.pageControl.frame = CGRectMake(0.0, CGRectGetHeight(self.bounds) - 20.0, 0.0, 0.0);
            break;
        case ZQPageControlStyleRight:
            self.pageControl.hidden = NO;
            self.pageControl.frame = CGRectMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(self.pageControl.bounds)), CGRectGetHeight(self.bounds) - 20.0, 0.0, 0.0);
            break;
    }
}

- (void)setup
{
    self.transitionTimeInterval = 5.0;
    self.autoTransition = YES;
    self.pageControlStyle = ZQPageControlStyleCenter;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureRecognizer:)];
    [self addGestureRecognizer:tapGesture];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    layout.minimumLineSpacing = 0.0;
    layout.minimumInteritemSpacing = 0.0;
    layout.itemSize = self.bounds.size;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.pagingEnabled = YES;
    collectionView.bounces = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    [collectionView registerClass:[ZQPictureCell class] forCellWithReuseIdentifier:NSStringFromClass([ZQPictureCell class])];
    self.collectionView = collectionView;
    
    self.bgView = [[UIImageView alloc]init];
    
    UIPageControl *pageControl = [[UIPageControl alloc]init];
    pageControl.hidden = YES;
    self.pageControl = pageControl;
    
    [self addSubview:self.bgView];
    [self addSubview:collectionView];
    [self addSubview:pageControl];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview) {
        [self timerStart];
        [self scrollViewDidEndDecelerating:self.collectionView];
    }
    else {
        [self timerStop];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.pictures.count * 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZQPictureCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ZQPictureCell class]) forIndexPath:indexPath];
    [self updatePictureWithIndex:indexPath.item % self.totalPage imageView:cell.imageView];
    return cell;
}

#pragma mark - UICollectionViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger page = (scrollView.contentOffset.x + scrollView.frame.size.width * 0.5) / scrollView.frame.size.width;
    NSInteger index = page % self.totalPage;
    if (index != self.pageControl.currentPage) {
        self.currentPage = self.pageControl.currentPage = index;
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self timerStop];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self timerStart];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.x / scrollView.frame.size.width;
    NSInteger index = page % self.totalPage;
    if (page <= self.totalPage || page >= self.totalPage * 9) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.totalPage * 3 + index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
}

#pragma mark - 私有方法

-(void)timerStart
{
    if (self.timer.isValid) {
        [self.timer invalidate];
        self.timer = nil;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.transitionTimeInterval target:self selector:@selector(nextPicture) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
}
-(void)timerStop
{
    [self.timer invalidate];
    self.timer = nil;
}

-(void)nextPicture
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.collectionView.indexPathsForVisibleItems.firstObject.item + 1 inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollViewDidEndDecelerating:self.collectionView];
    });
}

- (void)updatePictureWithIndex:(NSInteger)index imageView:(UIImageView *)imageView
{
    NSString *imageName = self.pictures[index];
    if ([imageName hasPrefix:@"http://"] || [imageName hasPrefix:@"https://"]) {
        [imageView setImageWithURL:[NSURL URLWithString:imageName] placeholderImage:self.placeholderImage];
    }
    else {
        imageView.image = [UIImage imageNamed:imageName];
    }
}

- (void)tapGestureRecognizer:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if ([self.delegate respondsToSelector:@selector(pictureRotator:didTouchWithCurrentPage:)]) {
        [self.delegate pictureRotator:self didTouchWithCurrentPage:self.currentPage];
    }
}

#pragma mark - getter/setter方法

- (void)setPictures:(NSArray *)pictures
{
    _pictures = [pictures copy];

    if (pictures.count == 0) {
        return;
    }
    
    self.pageControl.numberOfPages = self.totalPage = pictures.count;
    self.pageControl.currentPage = self.currentPage = 0;
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage
{
    _placeholderImage = placeholderImage;
    
    self.bgView.image = placeholderImage;
}

@end
