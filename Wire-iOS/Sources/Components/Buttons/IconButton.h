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

#import "ButtonWithLargerHitArea.h"
#import "ZetaIconTypes.h"
#import "ColorScheme.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, IconButtonStyle) {
    IconButtonStyleDefault,
    IconButtonStyleCircular,
    IconButtonStyleNavigation
};

@interface IconButton : ButtonWithLargerHitArea

@property (nonatomic) BOOL circular;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) BOOL roundCorners;
@property (nonatomic) BOOL adjustsTitleWhenHighlighted;
@property (nonatomic) BOOL adjustsBorderColorWhenHighlighted;
@property (nonatomic) BOOL adjustBackgroundImageWhenHighlighted;
@property (nonatomic) CGFloat titleImageSpacing;

- (instancetype)initWithStyle:(IconButtonStyle)style variant:(ColorSchemeVariant)variant;
- (instancetype)initWithStyle:(IconButtonStyle)style;

/// Default rendering mode is @c UIImageRenderingModeAlwaysTemplate
- (void)setIcon:(ZetaIconType)icon withSize:(ZetaIconSize)iconSize forState:(UIControlState)state;
- (void)setIcon:(ZetaIconType)icon withSize:(ZetaIconSize)iconSize forState:(UIControlState)state renderingMode:(UIImageRenderingMode)renderingMode;
- (ZetaIconType)iconTypeForState:(UIControlState)state;
- (void)setIconColor:(UIColor *)color forState:(UIControlState)state;
- (nullable UIColor *)iconColorForState:(UIControlState)state;
- (void)setBackgroundImageColor:(UIColor *)color forState:(UIControlState)state;
- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state;
- (void)setTitleImageSpacing:(CGFloat)titleImageSpacing horizontalMargin:(CGFloat)horizontalMargin;

@end

NS_ASSUME_NONNULL_END
