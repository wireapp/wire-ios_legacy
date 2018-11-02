// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "SketchColorPickerController.h"

#import "SketchColorCollectionViewCell.h"
@import PureLayout;
@import WireExtensionComponents;

static NSString* ZMLogTag ZM_UNUSED = @"UI";

/// Used only as fallback in case no brush width is set
static NSUInteger const SketchColorPickerDefaultBrushWidth = 6;


@interface SketchColorPickerController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) NSMutableDictionary *colorToBrushWidthMapper;
@property (nonatomic) UICollectionView *colorsCollectionView;
@property (nonatomic) UICollectionViewFlowLayout *colorsCollectionViewLayout;

@end

@implementation SketchColorPickerController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.brushWidths = @[@6, @12, @18];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpColorsCollectionView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.colorsCollectionViewLayout invalidateLayout];
}

- (void)setUpColorsCollectionView
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(44, 40);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
    self.colorsCollectionViewLayout = flowLayout;
    
    self.colorsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    self.colorsCollectionView.showsHorizontalScrollIndicator = NO;
    self.colorsCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.colorsCollectionView.backgroundColor = [UIColor  wr_colorFromColorScheme:ColorSchemeColorBackground];
    [self.view addSubview:self.colorsCollectionView];
    
    [self.colorsCollectionView registerClass:[SketchColorCollectionViewCell class] forCellWithReuseIdentifier:@"SketchColorCollectionViewCell"];
    self.colorsCollectionView.dataSource = self;
    self.colorsCollectionView.delegate = self;
    
    ALEdgeInsets insets = (ALEdgeInsets){0, 0, 0, 0};
    [self.colorsCollectionView autoPinEdgesToSuperviewEdgesWithInsets:insets];
}

- (void)setSketchColors:(NSArray *)sketchColors
{
    if (sketchColors == _sketchColors) {
        return;
    }
    
    _sketchColors = [sketchColors copy];

    [self resetColorToBrushWidthMapper];
    
    [self.colorsCollectionView reloadData];
    [self.colorsCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedColorIndex inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    
}

- (void)setSelectedColorIndex:(NSUInteger)selectedColorIndex
{
    _selectedColorIndex = selectedColorIndex;
    
    NSAssert(selectedColorIndex < self.sketchColors.count, @"Colors out of bounds");
    
    [self.colorsCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedColorIndex inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    
    UIColor *selectedColor = self.sketchColors[selectedColorIndex];
    [self.delegate sketchColorPickerController:self changedSelectedColor:selectedColor];
}

- (UIColor *)selectedColor
{
    UIColor *selectedColor = self.sketchColors[self.selectedColorIndex];
    return selectedColor;
}

- (void)setBrushWidths:(NSArray *)brushWidths
{
    if (brushWidths == _brushWidths) {
        return;
    }
    _brushWidths = [brushWidths copy];
    
    [self resetColorToBrushWidthMapper];
}

- (void)resetColorToBrushWidthMapper
{
    NSUInteger brushWidth = SketchColorPickerDefaultBrushWidth;
    id firstBrushWidth = [self.brushWidths firstObject];
    if ([firstBrushWidth isKindOfClass:[NSNumber class]]) {
        brushWidth = [firstBrushWidth unsignedIntegerValue];
    }
    NSMutableDictionary *colorToBrushWidthMapper = [NSMutableDictionary new];
    for (UIColor *color in self.sketchColors) {
        NSAssert([color isKindOfClass:[UIColor class]], @"Given object has wrong class. Expected UIColor");
        [colorToBrushWidthMapper setObject:@(brushWidth) forKey:color];
    }
    
    self.colorToBrushWidthMapper = colorToBrushWidthMapper;
    _selectedColorIndex = 0;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.colorsCollectionViewLayout invalidateLayout];
    } completion:nil];
}

- (NSUInteger)brushWidthForColor:(UIColor *)color
{
    if (! color) {
        ZMLogError(@"Returning fallback brush for unset color key");
        return SketchColorPickerDefaultBrushWidth;
    }
    NSNumber *number = [self.colorToBrushWidthMapper objectForKey:color];
    return [number unsignedIntegerValue];
}

/// Iterates throught brush width in ring 6 -> 12 -> 18 -> 6 -> 12 etc.
- (NSUInteger)bumpBrushWidthForColor:(UIColor *)color
{
    NSUInteger count = self.brushWidths.count;
    NSNumber *currentValue = [self.colorToBrushWidthMapper objectForKey:color];
    NSAssert(currentValue, @"Brush width not defined for color");
    NSUInteger index = [self.brushWidths indexOfObject:currentValue];
    NSUInteger nextIndex = ((index + 1) % count);
    NSNumber *nextValue = [self.brushWidths objectAtIndex:nextIndex];
    [self.colorToBrushWidthMapper setObject:nextValue forKey:color];
    
    return [nextValue unsignedIntegerValue];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (NSInteger)self.colorToBrushWidthMapper.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = [self.sketchColors objectAtIndex:indexPath.row];
    NSAssert(color, @"Color not set");
    NSNumber *brushWidth = [self.colorToBrushWidthMapper objectForKey:color];
    SketchColorCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SketchColorCollectionViewCell" forIndexPath:indexPath];
    cell.sketchColor = color;
    cell.brushWidth = [brushWidth unsignedIntegerValue];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = [self.sketchColors objectAtIndex:indexPath.row];
    NSAssert(color, @"Color not set");
    if (self.selectedColor == color) {
        // The color is already selected -> Change the brush size for this color
        NSUInteger brushWidth = [self bumpBrushWidthForColor:color];
        SketchColorCollectionViewCell *cell = (id)[collectionView cellForItemAtIndexPath:indexPath];
        cell.brushWidth = brushWidth;
    }
    
    self.selectedColorIndex = [self.sketchColors indexOfObject:color];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfItems = [self.sketchColors count];
    CGFloat contentWidth = numberOfItems * self.colorsCollectionViewLayout.itemSize.width + (MAX(numberOfItems - 1, 0)) * self.colorsCollectionViewLayout.minimumInteritemSpacing;
    CGFloat frameWidth = self.colorsCollectionView.frame.size.width;
    
    if (contentWidth < frameWidth) {
        // All items are included, just use the default item box
        return self.colorsCollectionViewLayout.itemSize;
    } else {
        // Some items dont fit, so we increase the item box to make the last
        // item visible for the half of its width, to give the user a hint that
        // he can scroll
        CGFloat itemWidth = contentWidth / numberOfItems;
        NSUInteger numberOfItemsVisible = round(frameWidth / itemWidth);
        CGFloat leftOver = frameWidth - (numberOfItemsVisible * itemWidth);
        leftOver += itemWidth / 2.0;
        return (CGSize){self.colorsCollectionViewLayout.itemSize.width + (leftOver / numberOfItemsVisible), self.colorsCollectionViewLayout.itemSize.height};
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    NSInteger numberOfItems = [self.sketchColors count];
    CGFloat contentWidth = numberOfItems * self.colorsCollectionViewLayout.itemSize.width + (MAX(numberOfItems - 1, 0)) * self.colorsCollectionViewLayout.minimumInteritemSpacing;
    CGFloat frameWidth = self.colorsCollectionView.frame.size.width;
    
    UIEdgeInsets contentInsets;
    if (contentWidth < frameWidth) {
        // Align content in center of frame
        CGFloat horizontalInset = frameWidth - contentWidth;
        contentInsets = UIEdgeInsetsMake(0, horizontalInset / 2, 0, horizontalInset / 2);
    } else {
        contentInsets = UIEdgeInsetsZero;
    }
    
    return contentInsets;
}

@end
