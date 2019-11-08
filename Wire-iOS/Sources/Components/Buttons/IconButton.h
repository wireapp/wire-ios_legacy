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

@import WireCommonComponents;

#import "ButtonWithLargerHitArea.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, IconButtonStyle) {
    IconButtonStyleDefault,
    IconButtonStyleCircular,
    IconButtonStyleNavigation
};

@interface IconDefinition : NSObject

@property (nonatomic) WRStyleKitIcon iconType;
@property (nonatomic) CGFloat iconSize;
@property (nonatomic) UIImageRenderingMode renderingMode;

@end

@interface IconButton : ButtonWithLargerHitArea

@property (nonatomic) BOOL circular;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) BOOL roundCorners;
@property (nonatomic) BOOL adjustsTitleWhenHighlighted;
@property (nonatomic) BOOL adjustsBorderColorWhenHighlighted;
@property (nonatomic) BOOL adjustBackgroundImageWhenHighlighted;
@property (nonatomic) CGFloat titleImageSpacing;

- (instancetype)initWithStyle:(IconButtonStyle)style;
- (instancetype)init;

/// Default rendering mode is @c UIImageRenderingModeAlwaysTemplate
- (void)setIcon:(WRStyleKitIcon)icon withSize:(CGFloat)iconSize forState:(UIControlState)state NS_REFINED_FOR_SWIFT;
- (void)setIcon:(WRStyleKitIcon)icon withSize:(CGFloat)iconSize forState:(UIControlState)state renderingMode:(UIImageRenderingMode)renderingMode NS_REFINED_FOR_SWIFT;
- (void)removeIconForState:(UIControlState)state;
- (nullable IconDefinition *)iconDefinitionForState:(UIControlState)state;

- (void)setIconColor:(UIColor *)color forState:(UIControlState)state;
- (nullable UIColor *)iconColorForState:(UIControlState)state;

- (void)setBackgroundImageColor:(UIColor *)color forState:(UIControlState)state;
- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state;
- (void)setTitleImageSpacing:(CGFloat)titleImageSpacing horizontalMargin:(CGFloat)horizontalMargin;

@end

NS_ASSUME_NONNULL_END
