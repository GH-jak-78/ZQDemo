//
//  LHYClassesView.m
//  ShiXingBang
//
//  Created by ZhaoQu on 16/7/14.
//  Copyright © 2016年 ZhaoQu. All rights reserved.
//

#import "LHYClassesView.h"

#define VerticalCellW 84.0
#define VerticalCellH 45.0

@interface LHYClassesView () <UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UITableView *verticalView;
@property (strong, nonatomic) UICollectionView *contentView;

@property (assign, nonatomic) NSInteger currentIndex;

@end

@implementation LHYClassesView

- (void)dealloc
{
    LHYLog(@"");
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
//    self.backgroundColor = LHYColorBg;
    
    [self addSubview:[UIView new]]; // 不添加会引起UICollectionView异常

    [self addSubview:self.verticalView];
    [self addSubview:self.contentView];

    [self.verticalView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.left.equalTo(self);
        make.width.offset(VerticalCellW);
        make.bottom.equalTo(self);
    }];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.left.equalTo(self.verticalView.mas_right);
        make.bottom.equalTo(self);
        make.right.equalTo(self);
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{

    LHYClasses *classes = self.classes[self.currentIndex];
    return classes.childClasses.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    LHYClasses *classes = self.classes[self.currentIndex];
    LHYClasses *childClasses = classes.childClasses[indexPath.item];
    switch (self.contentType) {
        case LHYClassesContentTypeRecycleBrand:
        {
            LHYClassesContent1Cell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LHYClassesContent1Cell" forIndexPath:indexPath];
            cell.titleLabel.text = childClasses.title;
            cell.iconView.image = [UIImage imageNamed:@"Default_Middle_Icon"];
            return cell;
            break;
        }
        case LHYClassesContentTypeStoreProduct:
        {
            LHYClassesContent2Cell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LHYClassesContent2Cell" forIndexPath:indexPath];
            cell.titleLabel.text = childClasses.title;
            cell.iconView.image = [UIImage imageNamed:@"Default_Middle_Icon"];
            cell.scoreLabel.text = @"2321";
            return cell;
            break;
        }
    }
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    LHYClassesContentHeaderView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"LHYClassesContentHeaderView" forIndexPath:indexPath];
    view.titleLabel.text = @"品牌";
    return view;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    LHYClasses *classes = self.classes[self.currentIndex];
    LHYClasses *childClasses = classes.childClasses[indexPath.item];
    if ([self.delegate respondsToSelector:@selector(classesView:itemDidTouchWith:)]) {
        [self.delegate classesView:self itemDidTouchWith:childClasses];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.contentType) {
        case LHYClassesContentTypeRecycleBrand:
            return CGSizeMake((LHYScreenW - VerticalCellW - 24.0) / 3.0, (LHYScreenW - VerticalCellW - 96.0) / 3.0 + 24.0 + 13.0 + 10.0);
            break;
        case LHYClassesContentTypeStoreProduct:
            return CGSizeMake((LHYScreenW - VerticalCellW - 36.0) / 2.0, (LHYScreenW - VerticalCellW - 84.0) * 0.5 + 24.0 + 13.0 * 2 + 10.0 * 2);
            break;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    switch (self.contentType) {
        case LHYClassesContentTypeRecycleBrand:
            return CGSizeMake(LHYScreenW - VerticalCellW, VerticalCellH);
            break;
        case LHYClassesContentTypeStoreProduct:
            return CGSizeZero;
            break;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    switch (self.contentType) {
        case LHYClassesContentTypeRecycleBrand:
            return 0.0;
            break;
        case LHYClassesContentTypeStoreProduct:
            return 12.0;
            break;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    switch (self.contentType) {
        case LHYClassesContentTypeRecycleBrand:
            return 0.0;
            break;
        case LHYClassesContentTypeStoreProduct:
            return 12.0;
            break;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.classes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"LHYClassesVerticalCell";
    
    LHYClassesVerticalCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[LHYClassesVerticalCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    LHYClasses *cls = self.classes[indexPath.row];
    cell.titleLabel.text = cls.title;
    
    return cell;
}

//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//    LHYClassesVerticalFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"LHYClassesVerticalFooterView"];
//    if (!view) {
//        view = [[LHYClassesVerticalFooterView alloc]initWithReuseIdentifier:@"LHYClassesVerticalFooterView"];
//    }
//    return view;
//}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentIndex = indexPath.row;
    [self.contentView setContentOffset:CGPointZero];
    [self.contentView reloadData];
    
}

#pragma mark - getter/setter

- (UITableView *)verticalView
{
    if (_verticalView == nil) {
        _verticalView = [[UITableView alloc]init];
        _verticalView.backgroundColor = LHYColorFg;
        _verticalView.dataSource = self;
        _verticalView.delegate = self;
        _verticalView.rowHeight = VerticalCellH;
        _verticalView.sectionFooterHeight = VerticalCellH;
        _verticalView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _verticalView.showsVerticalScrollIndicator = NO;
    }
    return _verticalView;
}

- (UICollectionView *)contentView
{
    if (_contentView == nil) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.sectionInset = UIEdgeInsetsMake(0.0, 12.0, 0.0, 12.0);
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
//        layout.estimatedItemSize = CGSizeMake(100, 100);
        
        _contentView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        _contentView.backgroundColor = LHYColorBg;
        _contentView.dataSource = self;
        _contentView.delegate = self;
        _contentView.showsHorizontalScrollIndicator = NO;
        _contentView.showsVerticalScrollIndicator = YES;
        _contentView.bounces = YES;
        _contentView.scrollEnabled = YES;
        _contentView.allowsSelection = YES;
        _contentView.alwaysBounceVertical = YES;
        
        [_contentView registerClass:[LHYClassesContent1Cell class] forCellWithReuseIdentifier:@"LHYClassesContent1Cell"];
        [_contentView registerClass:[LHYClassesContent2Cell class] forCellWithReuseIdentifier:@"LHYClassesContent2Cell"];
        [_contentView registerClass:[LHYClassesContentHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"LHYClassesContentHeaderView"];
    }
    return _contentView;
}

- (void)setClasses:(NSArray *)classes
{
    _classes = [classes copy];
    
    [self.verticalView reloadData];
    [self.contentView reloadData];
    
    [self.verticalView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

@end



@implementation LHYClasses

@end

@implementation LHYClassesVerticalCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        UIView * selectedBackgroundView = [[UIView alloc]init];
        selectedBackgroundView.backgroundColor = LHYColorBg;
        UIView *rect = [[UIView alloc]init];
        rect.backgroundColor = LHYColorY;
        [selectedBackgroundView addSubview:rect];
        self.selectedBackgroundView = selectedBackgroundView;
        [rect mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.offset(0.0);
            make.left.offset(0.0);
            make.bottom.offset(0.0);
            make.width.offset(3.0);
        }];
        
        [self.contentView addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_offset(UIEdgeInsetsZero);
        }];
        
        UIView *bottomLine = [[UIView alloc]init];
        bottomLine.backgroundColor = LHYColorLine;
        [self.contentView addSubview:bottomLine];
        
        [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(0.0);
            make.right.offset(0.0);
            make.bottom.offset(0.0);
            make.height.offset(0.5);
        }];
        
    }
    return self;
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.font = LHYFontText;
        _titleLabel.textColor = LHYColorText;
        _titleLabel.highlightedTextColor = LHYColorY;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

@end

@implementation LHYClassesVerticalFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_offset(UIEdgeInsetsZero);
        }];
    }
    return self;
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.backgroundColor = LHYColorFg;
        _titleLabel.font = LHYFontDescText;
        _titleLabel.textColor = LHYColorDescText;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"没有更多分类";
    }
    return _titleLabel;
}

@end

@implementation LHYClassesContent1Cell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = LHYColorFg;
        
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.iconView];
        
        [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.offset(12.0);
            make.left.offset(12.0);
            make.right.offset(-12.0);
//            make.width.offset((LHYScreenW - VerticalCellW - 96.0) / 3.0);
            make.height.equalTo(self.iconView.mas_width);
        }];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.iconView.mas_bottom).offset(7.0);
            make.centerX.equalTo(self.contentView);
//            make.bottom.offset(-12.0);
        }];
        
    }
    return self;
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.font = LHYFontSubText;
        _titleLabel.textColor = LHYColorSubText;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIImageView *)iconView
{
    if (_iconView == nil) {
        _iconView = [[UIImageView alloc]init];
    }
    return _iconView;
}

@end

@interface LHYClassesContent2Cell ()

@property (strong, nonatomic) UIImageView *descView;
@property (strong, nonatomic) UILabel *descLabel;

@end

@implementation LHYClassesContent2Cell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = LHYColorFg;
        
        [self.contentView addSubview:self.iconView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.descView];
        [self.contentView addSubview:self.scoreLabel];
        [self.contentView addSubview:self.descLabel];
        
        [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.offset(12.0);
            make.left.offset(12.0);
            make.right.offset(-12.0);
//            make.width.offset((LHYScreenW - VerticalCellW - 84.0) * 0.5);
            make.height.equalTo(self.iconView.mas_width);
        }];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.iconView.mas_bottom).offset(7.0);
            make.left.offset(12.0);
        }];
        [self.descView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.scoreLabel);
            make.left.offset(12.0);
            make.width.offset(13.0);
            make.height.offset(13.0);
        }];
        [self.scoreLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(7.0);
            make.left.equalTo(self.descView.mas_right).offset(5.0);
//            make.bottom.offset(-12);
        }];
        [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.scoreLabel);
            make.left.equalTo(self.scoreLabel.mas_right);
        }];
    }
    return self;
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.font = LHYFontSubText;
        _titleLabel.textColor = LHYColorText;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)scoreLabel
{
    if (_scoreLabel == nil) {
        _scoreLabel = [[UILabel alloc]init];
        _scoreLabel.font = LHYFontSubText;
        _scoreLabel.textColor = LHYColorY;
    }
    return _scoreLabel;
}

- (UILabel *)descLabel
{
    if (_descLabel == nil) {
        _descLabel = [[UILabel alloc]init];
        _descLabel.font = LHYFontSubText;
        _descLabel.textColor = LHYColorSubText;
        _descLabel.text = @"积分";
    }
    return _descLabel;
}

- (UIImageView *)iconView
{
    if (_iconView == nil) {
        _iconView = [[UIImageView alloc]init];
    }
    return _iconView;
}

- (UIImageView *)descView
{
    if (_descView == nil) {
        _descView = [[UIImageView alloc]init];
        _descView.image = [UIImage imageNamed:@"Mine_Integral_Icon_Little"];
    }
    return _descView;
}

@end

@implementation LHYClassesContentHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = LHYColorBg;
        
        [self addSubview:self.titleLabel];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_offset(UIEdgeInsetsMake(0, 12.0, 0, 12.0));
        }];
    }
    return self;
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.font = LHYFontTitle;
        _titleLabel.textColor = LHYColorSubText;
    }
    return _titleLabel;
}

@end