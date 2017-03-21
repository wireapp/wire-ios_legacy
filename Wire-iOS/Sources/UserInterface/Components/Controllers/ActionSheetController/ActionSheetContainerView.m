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


#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>

#import "ActionSheetContainerView.h"
#import "UIView+WR_ExtendedBlockAnimations.h"


@interface ActionSheetContainerView ()

@property (nonatomic) UIEdgeInsets contentInsets;
@property (nonatomic) ActionSheetViewStyle style;

@end



@implementation ActionSheetContainerView

- (instancetype)initWithStyle:(ActionSheetViewStyle)style
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.style = style;
        self.cas_styleClass = style == ActionSheetViewStyleLight ? @"light" : @"dark";
        self.contentInsets = UIEdgeInsetsMake(30, 24, 24, 24);
        self.blurEffect = [UIBlurEffect effectWithStyle:style == ActionSheetViewStyleDark ? UIBlurEffectStyleDark : UIBlurEffectStyleLight];
        [self createViews];
        [self createInitialConstraints];
    }
    
    return self;
}

- (void)createViews
{
    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:self.blurEffect];
    self.blurEffectView.preservesSuperviewLayoutMargins = YES;
    self.blurEffectView.contentView.preservesSuperviewLayoutMargins = YES;
    self.blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.blurEffectView];
    
    self.topContainerView = [[UIView alloc] initForAutoLayout];
    [self.blurEffectView.contentView addSubview:self.topContainerView];
    
    [self createInitialConstraints];
}

- (void)createInitialConstraints
{
    [self.blurEffectView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.topContainerView autoPinEdgesToSuperviewEdgesWithInsets:self.contentInsets excludingEdge:ALEdgeBottom];
}

- (void)setSheetView:(UIView *)sheetView
{
    _sheetView = sheetView;
    self.sheetView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.blurEffectView.contentView addSubview:self.sheetView];
    [self.sheetView autoPinEdgesToSuperviewEdgesWithInsets:self.contentInsets excludingEdge:ALEdgeTop];
}

- (void)transitionFromSheetView:(UIView *)fromSheetView toSheetView:(UIView *)toSheetView completion:(void (^)(BOOL finished))completion
{
    self.sheetView = toSheetView;
    [self layoutIfNeeded];
    
    CGAffineTransform offscreenToSheet = CGAffineTransformMakeTranslation(0, self.bounds.size.height - toSheetView.frame.origin.y);
    CGAffineTransform offscreenFromSheet = CGAffineTransformMakeTranslation(0, self.bounds.size.height - fromSheetView.frame.origin.y);
    
    toSheetView.transform = offscreenToSheet;
    
    [UIView wr_animateWithEasing:RBBEasingFunctionEaseInExpo duration:0.35 delay:0 animations:^{
        fromSheetView.transform = offscreenFromSheet;
    } completion:^(BOOL finished) {
        [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutExpo duration:0.35 delay:0 animations:^{
            toSheetView.transform = CGAffineTransformIdentity;
            [fromSheetView removeFromSuperview];
        } completion:completion];
    }];
}
     

@end
