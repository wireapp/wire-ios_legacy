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

@import UIKit;
@import WireSyncEngine;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ColorSchemeVariant) {
    ColorSchemeVariantLight,
    ColorSchemeVariantDark
};

@interface ColorScheme : NSObject

@property (nonatomic, readonly) NSDictionary *colors;
@property (nonatomic, readonly) UIKeyboardAppearance keyboardAppearance;

@property (nonatomic) ColorSchemeVariant variant;

@property (class, readonly, strong) ColorScheme *defaultColorScheme;
@property (strong, nonatomic) UIColor *accentColor;

+ (UIKeyboardAppearance)keyboardAppearanceForVariant:(ColorSchemeVariant)variant;

- (BOOL)isCurrentAccentColor:(UIColor *)accentColor;
@end

@interface UIColor (ColorScheme)

/// Creates UIColor instance with color corresponding to @p accentColor that can be used to display the name.
+ (UIColor *)nameColorForZMAccentColor:(ZMAccentColor)accentColor variant:(ColorSchemeVariant)variant;

@end

NS_ASSUME_NONNULL_END
