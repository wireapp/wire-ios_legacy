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

@interface IconButton : ButtonWithLargerHitArea

@property (nonatomic) BOOL circular;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) BOOL adjustsTitleWhenHighlighted;
@property (nonatomic) CGFloat titleImageSpacing;

+ (instancetype)iconButtonDefault;
+ (instancetype)iconButtonCircularLight;
+ (instancetype)iconButtonCircularDark;
+ (instancetype)iconButtonCircular;

/// Default rendering mode is @c UIImageRenderingModeAlwaysTemplate
- (void)setIcon:(ZetaIconType)icon withSize:(ZetaIconSize)iconSize forState:(UIControlState)state;
- (void)setIcon:(ZetaIconType)icon withSize:(ZetaIconSize)iconSize forState:(UIControlState)state renderingMode:(UIImageRenderingMode)renderingMode;
- (ZetaIconType)iconTypeForState:(UIControlState)state;
- (void)setIconColor:(UIColor *)color forState:(UIControlState)state;
- (UIColor *)iconColorForState:(UIControlState)state;
- (void)setBackgroundImageColor:(UIColor *)color forState:(UIControlState)state;
- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state;
- (void)setTitleImageSpacing:(CGFloat)titleImageSpacing horizontalMargin:(CGFloat)horizontalMargin;

@end
