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

typedef NSString *const ColorSchemeColor NS_STRING_ENUM;

extern ColorSchemeColor ColorSchemeColorTextForeground;
extern ColorSchemeColor ColorSchemeColorTextBackground;
extern ColorSchemeColor ColorSchemeColorTextDimmed;
extern ColorSchemeColor ColorSchemeColorTextPlaceholder;

extern ColorSchemeColor ColorSchemeColorIconNormal;
extern ColorSchemeColor ColorSchemeColorIconSelected;
extern ColorSchemeColor ColorSchemeColorIconHighlighted;
extern ColorSchemeColor ColorSchemeColorIconBackgroundSelected;
extern ColorSchemeColor ColorSchemeColorIconBackgroundSelectedNoAccent;
extern ColorSchemeColor ColorSchemeColorIconShadow;
extern ColorSchemeColor ColorSchemeColorIconHighlight;
extern ColorSchemeColor ColorSchemeColorIconGuest;

extern ColorSchemeColor ColorSchemeColorPopUpButtonOverlayShadow;

extern ColorSchemeColor ColorSchemeColorChatHeadBackground;
extern ColorSchemeColor ColorSchemeColorChatHeadBorder;
extern ColorSchemeColor ColorSchemeColorChatHeadTitleText;
extern ColorSchemeColor ColorSchemeColorChatHeadSubtitleText;

extern ColorSchemeColor ColorSchemeColorButtonHighlighted;
extern ColorSchemeColor ColorSchemeColorButtonFaded;

extern ColorSchemeColor ColorSchemeColorTabNormal;
extern ColorSchemeColor ColorSchemeColorTabSelected;
extern ColorSchemeColor ColorSchemeColorTabHighlighted;

extern ColorSchemeColor ColorSchemeColorBackground;
extern ColorSchemeColor ColorSchemeColorContentBackground;
extern ColorSchemeColor ColorSchemeColorBarBackground;
extern ColorSchemeColor ColorSchemeColorSearchBarBackground;
extern ColorSchemeColor ColorSchemeColorSeparator;
extern ColorSchemeColor ColorSchemeColorCellSeparator;
extern ColorSchemeColor ColorSchemeColorBackgroundOverlay;
extern ColorSchemeColor ColorSchemeColorBackgroundOverlayWithoutPicture;
extern ColorSchemeColor ColorSchemeColorPlaceholderBackground;
extern ColorSchemeColor ColorSchemeColorAvatarBorder;
extern ColorSchemeColor ColorSchemeColorLoadingDotActive;
extern ColorSchemeColor ColorSchemeColorLoadingDotInactive;

extern ColorSchemeColor ColorSchemeColorPaleSeparator;
extern ColorSchemeColor ColorSchemeColorListAvatarInitials;
extern ColorSchemeColor ColorSchemeColorAudioButtonOverlay;

extern ColorSchemeColor ColorSchemeColorNameAccentPrefix;

extern ColorSchemeColor ColorSchemeColorGraphite;
extern ColorSchemeColor ColorSchemeColorLightGraphite;

extern ColorSchemeColor ColorSchemeColorSectionBackground;
extern ColorSchemeColor ColorSchemeColorSectionText;

extern ColorSchemeColor ColorSchemeColorTokenFieldBackground;
extern ColorSchemeColor ColorSchemeColorTokenFieldTextPlaceHolder;

extern ColorSchemeColor ColorSchemeColorSelfMentionHighlight;

typedef NS_ENUM(NSUInteger, ColorSchemeVariant) {
    ColorSchemeVariantLight,
    ColorSchemeVariantDark
};

@interface ColorScheme : NSObject

@property (nonatomic, readonly) NSDictionary *colors;
@property (nonatomic, readonly) UIKeyboardAppearance keyboardAppearance;
@property (nonatomic, readonly) UIBlurEffectStyle blurEffectStyle;

@property (nonatomic) ColorSchemeVariant variant;

@property (class, readonly, strong) ColorScheme *defaultColorScheme;

+ (UIKeyboardAppearance)keyboardAppearanceForVariant:(ColorSchemeVariant)variant;
+ (UIBlurEffectStyle)blurEffectStyleForVariant:(ColorSchemeVariant)variant;

- (UIColor *)colorWithName:(ColorSchemeColor)colorName NS_SWIFT_NAME(color(named:));
- (UIColor *)colorWithName:(ColorSchemeColor)colorName variant:(ColorSchemeVariant)variant NS_SWIFT_NAME(color(named:variant:));

- (UIColor *)nameAccentForColor:(ZMAccentColor)color variant:(ColorSchemeVariant)variant;

- (void)setAccentColor:(UIColor *)accentColor;
- (BOOL)isCurrentAccentColor:(UIColor *)accentColor;
@end

@interface UIColor (ColorScheme)

/// Creates UIColor instance with color corresponding to @p accentColor that can be used to display the name.
+ (UIColor *)nameColorForZMAccentColor:(ZMAccentColor)accentColor variant:(ColorSchemeVariant)variant;

@end

NS_ASSUME_NONNULL_END
