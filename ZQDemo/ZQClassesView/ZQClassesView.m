//
//  ZQClassesView.m
//  ShiXingBang
//
//  Created by ZhaoQu on 16/7/14.
//  Copyright © 2016年 ZhaoQu. All rights reserved.
//

#import "ZQClassesView.h"
#import "Masonry.h"

@interface ZQClassesView () <UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UITableView *verticalView;
@property (strong, nonatomic) UICollectionView *contentView;

@property (assign, nonatomic) NSInteger currentIndex;

@end

@implementation ZQClassesView

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

    ZQClasses *classes = self.classes[self.currentIndex];
    return classes.childClasses.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZQClasses *classes = self.classes[self.currentIndex];
    
    ZQClassesContentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ZQClassesContentCell" forIndexPath:indexPath];
    cell.classes = classes.childClasses[indexPath.item];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    ZQClassesContentHeaderView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"ZQClassesContentHeaderView" forIndexPath:indexPath];
    view.titleLabel.text = @"分项";
    return view;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZQClasses *classes = self.classes[self.currentIndex];
    ZQClasses *childClasses = classes.childClasses[indexPath.item];
    if ([self.delegate respondsToSelector:@selector(classesView:itemDidTouchWith:)]) {
        [self.delegate classesView:self itemDidTouchWith:childClasses];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    return CGSizeMake(([UIScreen mainScreen].bounds.size.width - VerticalCellW - 36.0) / 2.0,
//                      ([UIScreen mainScreen].bounds.size.width - VerticalCellW - 84.0) * 0.5 + 24.0 + 13.0 * 2 + 10.0 * 2);
//}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake([UIScreen mainScreen].bounds.size.width - VerticalCellW - 24.0, 44.0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 12.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 12.0;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.classes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"ZQClassesVerticalCell";
    
    ZQClassesVerticalCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[ZQClassesVerticalCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    ZQClasses *cls = self.classes[indexPath.row];
    cell.titleLabel.text = cls.title;
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    ZQClassesVerticalFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ZQClassesVerticalFooterView"];
    if (!view) {
        view = [[ZQClassesVerticalFooterView alloc]initWithReuseIdentifier:@"ZQClassesVerticalFooterView"];
    }
    return view;
}

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
        _verticalView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _verticalView.backgroundColor = [UIColor whiteColor];
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
        layout.estimatedItemSize = CGSizeMake(100, 100);
        
        _contentView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        _contentView.backgroundColor = [UIColor lightGrayColor];
        _contentView.dataSource = self;
        _contentView.delegate = self;
        _contentView.showsHorizontalScrollIndicator = NO;
        _contentView.showsVerticalScrollIndicator = YES;
        _contentView.bounces = YES;
        _contentView.scrollEnabled = YES;
        _contentView.allowsSelection = YES;
        _contentView.alwaysBounceVertical = YES;
        
        [_contentView registerClass:[ZQClassesContentCell class] forCellWithReuseIdentifier:@"ZQClassesContentCell"];
        [_contentView registerClass:[ZQClassesContentHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"ZQClassesContentHeaderView"];
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



@implementation ZQClasses

@end

@implementation ZQClassesVerticalCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        UIView * selectedBackgroundView = [[UIView alloc]init];
        selectedBackgroundView.backgroundColor = [UIColor lightGrayColor];
        UIView *rect = [[UIView alloc]init];
        rect.backgroundColor = [UIColor greenColor];
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
            make.edges.insets(UIEdgeInsetsZero);
        }];
        
        UIView *bottomLine = [[UIView alloc]init];
        bottomLine.backgroundColor = [UIColor lightGrayColor];
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
        _titleLabel.font = [UIFont systemFontOfSize:16.0];
        _titleLabel.textColor = [UIColor grayColor];
        _titleLabel.highlightedTextColor = [UIColor greenColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

@end

@implementation ZQClassesVerticalFooterView

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
        _titleLabel.backgroundColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:13.0];
        _titleLabel.textColor = [UIColor lightGrayColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"没有更多分类";
    }
    return _titleLabel;
}

@end

@interface ZQClassesContentCell ()

@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *descLabel;

@end

@implementation ZQClassesContentCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        
        [self.contentView addSubview:self.iconView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.descLabel];
        
        [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.offset(12.0);
            make.left.offset(12.0);
            make.right.offset(-12.0);
            make.width.offset(([UIScreen mainScreen].bounds.size.width - VerticalCellW - 84.0) * 0.5);
            make.height.equalTo(self.iconView.mas_width);
        }];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.iconView.mas_bottom).offset(7.0);
            make.left.offset(12.0);
        }];
        [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(7.0);
            make.left.offset(12.0);
            make.bottom.offset(-12);
        }];
    }
    return self;
}

- (UIImageView *)iconView
{
    if (_iconView == nil) {
        _iconView = [[UIImageView alloc]init];
    }
    return _iconView;
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.font = [UIFont systemFontOfSize:14.0];
        _titleLabel.textColor = [UIColor grayColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)descLabel
{
    if (_descLabel == nil) {
        _descLabel = [[UILabel alloc]init];
        _descLabel.font = [UIFont systemFontOfSize:13.0];
        _descLabel.textColor = [UIColor lightGrayColor];
    }
    return _descLabel;
}

- (void)setClasses:(ZQClasses *)classes
{
    _classes = classes;
    
    self.titleLabel.text = classes.title;
    self.descLabel.text = classes.descString;
    self.iconView.image = [UIImage imageNamed:classes.iconUrl];
}

@end

@implementation ZQClassesContentHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor lightGrayColor];
        
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
        _titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
        _titleLabel.textColor = [UIColor grayColor];
    }
    return _titleLabel;
}

@end