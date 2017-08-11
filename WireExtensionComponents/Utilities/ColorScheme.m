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


#import "ColorScheme.h"
#import "UIColor+Mixing.h"
#import "UIColor+WAZExtensions.h"


NSString * const ColorSchemeColorAccent = @"accent-current";
NSString * const ColorSchemeColorAccentDimmed = @"accent-current-dimmed";
NSString * const ColorSchemeColorAccentDimmedFlat = @"accent-current-dimmed-flat";
NSString * const ColorSchemeColorAccentDarken = @"accent-current-darken";

NSString * const ColorSchemeColorSeparator = @"separator";
NSString * const ColorSchemeColorBackground = @"background";
NSString * const ColorSchemeColorBarBackground = @"bar-background";
NSString * const ColorSchemeColorConversationBackground = @"conversation-background";
NSString * const ColorSchemeColorBackgroundOverlay = @"background-overlay";
NSString * const ColorSchemeColorBackgroundOverlayWithoutPicture = @"background-overlay-without-picture";

NSString * const ColorSchemeColorTextForeground = @"text-foreground";
NSString * const ColorSchemeColorTextBackground = @"text-background";
NSString * const ColorSchemeColorTextDimmed = @"text-dimmed";
NSString * const ColorSchemeColorTextPlaceholder = @"text-placeholder";

NSString * const ColorSchemeColorIconNormal = @"icon-normal";
NSString * const ColorSchemeColorIconSelected = @"icon-selected";
NSString * const ColorSchemeColorIconHighlighted = @"icon-highlighted";
NSString * const ColorSchemeColorIconBackgroundSelected = @"icon-background-selected";
NSString * const ColorSchemeColorIconBackgroundSelectedNoAccent = @"icon-background-selected-no-accent";

NSString * const ColorSchemeColorPopUpButtonOverlayShadow = @"popup-button-overlay-shadow";

NSString * const ColorSchemeColorButtonHighlighted = @"button-highlighted";
NSString * const ColorSchemeColorButtonEmptyText = @"button-empty-text";

NSString * const ColorSchemeColorIconShadow = @"icon-shadow";
NSString * const ColorSchemeColorIconHighlight = @"icon-hightlight";

NSString * const ColorSchemeColorTabNormal = @"tab-normal";
NSString * const ColorSchemeColorTabSelected = @"tab-selected";
NSString * const ColorSchemeColorTabHighlighted = @"tab-highlighted";

NSString * const ColorSchemeColorCallBarBackground = @"call-bar-background";
NSString * const ColorSchemeColorCallBarSeparator = @"call-bar-separator";

NSString * const ColorSchemeColorAvatarBorder = @"avatar-border";
NSString * const ColorSchemeColorListAvatarInitials = @"list-avatar-initials";

NSString * const ColorSchemeColorContactSectionBackground = @"contact-section-background";

NSString * const ColorSchemeColorPlaceholderBackground = @"placeholder-background";
NSString * const ColorSchemeColorPaleSeparator = @"separator-pale";

NSString * const ColorSchemeColorAudioButtonOverlay = @"audio-button-overlay";

NSString * const ColorSchemeColorLoadingDotActive = @"loading-dot-active";
NSString * const ColorSchemeColorLoadingDotInactive = @"loading-dot-inactive";

NSString * const ColorSchemeColorNameAccentPrefix = @"name-accent";

NSString * const ColorSchemeColorGraphite = @"graphite";
NSString * const ColorSchemeColorLightGraphite = @"graphite-light";

NSString * const ColorSchemeColorSectionBackground = @"section-background";
NSString * const ColorSchemeColorSectionText = @"section-text";

NSString * const ColorSchemeColorTokenFieldBackground = @"token-field-background";
NSString * const ColorSchemeColorTokenFieldTextPlaceHolder = @"token-field-text-placeholder";

/// Generates the key name for the accent color that can be used to display the username.
static NSString * ColorSchemeNameAccentColorForColor(ZMAccentColor color);

static NSString * ColorSchemeNameAccentColorForColor(ZMAccentColor color) {
    static NSArray *colorNames = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // NB! Order of the elements and it's position should be in order with ZMAccentColor enum
        colorNames = @[@"undefined",
                       @"strong-blue",
                       @"strong-lime-green",
                       @"bright-yellow",
                       @"vivid-red",
                       @"bright-orange",
                       @"soft-pink",
                       @"violet"];
    });

    assert(color < colorNames.count);
    
    return [NSString stringWithFormat:@"%@-%@", ColorSchemeColorNameAccentPrefix, colorNames[color]];
}

static NSString* dark(NSString *colorString) {
    return [NSString stringWithFormat:@"%@-dark", colorString];
}

static NSString* light(NSString *colorString) {
    return [NSString stringWithFormat:@"%@-light", colorString];
}



@interface ColorScheme ()

@property (nonatomic) NSDictionary *colors;

@end



@implementation ColorScheme

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _variant = ColorSchemeVariantLight;
        _accentColor = [UIColor redColor];
        [self updateColors];
    }
    
    return self;
}

- (UIKeyboardAppearance)keyboardAppearance
{
    return [self.class keyboardAppearanceForVariant:self.variant];
}

+ (UIKeyboardAppearance)keyboardAppearanceForVariant:(ColorSchemeVariant)variant
{
    return variant == ColorSchemeVariantLight ? UIKeyboardAppearanceLight : UIKeyboardAppearanceDark;
}

- (UIBlurEffectStyle)blurEffectStyle
{
    return [self.class blurEffectStyleForVariant:self.variant];
}

+ (UIBlurEffectStyle)blurEffectStyleForVariant:(ColorSchemeVariant)variant
{
    return variant == ColorSchemeVariantLight ? UIBlurEffectStyleLight : UIBlurEffectStyleDark;
}

- (void)setAccentColor:(UIColor *)accentColor
{
    _accentColor = accentColor;
    [self updateColors];
}

- (void)setVariant:(ColorSchemeVariant)variant
{
    _variant = variant;
    [self updateColors];
}

- (void)updateColors
{
    self.colors = [self colorSchemeColorsWithAccentColor:self.accentColor colorSchemeVariant:self.variant];
}

+ (instancetype)defaultColorScheme
{
    static ColorScheme *defaultColorScheme = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultColorScheme = [[self alloc] init];
    });
    
    return defaultColorScheme;
}

- (UIColor *)colorWithName:(NSString *)colorName
{
    return [self.colors objectForKey:colorName];
}

- (UIColor *)colorWithName:(NSString *)colorName variant:(ColorSchemeVariant)variant
{
    return [self.colors objectForKey:variant == ColorSchemeVariantLight ? light(colorName) : dark(colorName)];
}

- (UIColor *)nameAccentForColor:(ZMAccentColor)color variant:(ColorSchemeVariant)variant
{
    NSString *colorName = ColorSchemeNameAccentColorForColor(color);
    
    return [self colorWithName:colorName variant:variant];
}

- (NSDictionary *)colorSchemeColorsWithAccentColor:(UIColor *)accentColor colorSchemeVariant:(ColorSchemeVariant)variant
{
    UIColor *clear = [UIColor clearColor];
    UIColor *white = [UIColor whiteColor];
    UIColor *white97 = [UIColor colorWithWhite:0.97 alpha:1];
    UIColor *white98 = [UIColor colorWithWhite:0.98 alpha:1];
    UIColor *whiteAlpha16 = [UIColor wr_colorFromString:@"rgb(255, 255, 255, 0.16)"];
    UIColor *whiteAlpha24 = [UIColor wr_colorFromString:@"rgb(255, 255, 255, 0.24)"];
    UIColor *whiteAlpha40 = [UIColor wr_colorFromString:@"rgb(255, 255, 255, 0.40)"];
    UIColor *whiteAlpha80 = [UIColor wr_colorFromString:@"rgb(255, 255, 255, 0.80)"];
    UIColor *black = [UIColor blackColor];
    UIColor *blackAlpha4 = [UIColor wr_colorFromString:@"rgb(0, 0, 0, 0.04)"];
    UIColor *blackAlpha8 = [UIColor wr_colorFromString:@"rgb(0, 0, 0, 0.08)"];
    UIColor *blackAlpha24 = [UIColor wr_colorFromString:@"rgb(0, 0, 0, 0.24)"];
    UIColor *blackAlpha48 = [UIColor wr_colorFromString:@"rgb(0, 0, 0, 0.48)"];
    UIColor *blackAlpha40 = [UIColor colorWithWhite:0 alpha:0.4];
    UIColor *blackAlpha80 = [UIColor wr_colorFromString:@"rgb(0, 0, 0, 0.80)"];
    UIColor *backgroundGraphite = [UIColor wr_colorFromString:@"rgb(22, 24, 25)"];
    UIColor *backgroundLightGraphite = [UIColor wr_colorFromString:@"rgb(30, 32, 33)"];
    UIColor *graphite = [UIColor wr_colorFromString:@"rgb(51, 55, 58)"];
    UIColor *graphiteAlpha16 = [UIColor wr_colorFromString:@"rgb(51, 55, 58, 0.16)"];
    UIColor *graphiteAlpha40 = [UIColor wr_colorFromString:@"rgb(51, 55, 58, 0.40)"];
    UIColor *lightGraphite = [UIColor wr_colorFromString:@"rgb(141, 152, 159)"];
    UIColor *lightGraphiteAlpha8 = [UIColor wr_colorFromString:@"rgb(141, 152, 159, 0.08)"];
    UIColor *lightGraphiteAlpha24 = [UIColor wr_colorFromString:@"rgb(141, 152, 159, 0.24)"];
    UIColor *lightGraphiteAlpha48 = [UIColor wr_colorFromString:@"rgb(141, 152, 159, 0.48)"];
    UIColor *lightGraphiteAlpha64 = [UIColor wr_colorFromString:@"rgb(141, 152, 159, 0.64)"];
    
    
    NSMutableDictionary *lightColors = [NSMutableDictionary dictionaryWithDictionary:
                                @{ ColorSchemeColorAccent: accentColor,
                                   ColorSchemeColorAccentDimmed: [accentColor colorWithAlphaComponent:0.16],
                                   ColorSchemeColorAccentDimmedFlat: [[accentColor colorWithAlphaComponent:0.16] removeAlphaByBlendingWithColor:white],
                                   ColorSchemeColorAccentDarken: [[accentColor mix:[UIColor blackColor] amount:0.1] colorWithAlphaComponent:0.32],
                                   ColorSchemeColorTextForeground: graphite,
                                   ColorSchemeColorTextBackground: white,
                                   ColorSchemeColorTextDimmed: lightGraphite,
                                   ColorSchemeColorTextPlaceholder: lightGraphiteAlpha64,
                                   ColorSchemeColorSeparator: lightGraphiteAlpha48,
                                   ColorSchemeColorBarBackground: white,
                                   ColorSchemeColorBackground: white,
                                   ColorSchemeColorConversationBackground: white97,
                                   ColorSchemeColorIconNormal: graphite,
                                   ColorSchemeColorIconSelected: white,
                                   ColorSchemeColorIconHighlighted: white,
                                   ColorSchemeColorIconShadow: blackAlpha8,
                                   ColorSchemeColorIconHighlight: white,
                                   ColorSchemeColorIconBackgroundSelected: accentColor,
                                   ColorSchemeColorIconBackgroundSelectedNoAccent: graphite,
                                   ColorSchemeColorPopUpButtonOverlayShadow: blackAlpha24,
                                   ColorSchemeColorButtonHighlighted: whiteAlpha24,
                                   ColorSchemeColorButtonEmptyText: accentColor,
                                   ColorSchemeColorTabNormal: blackAlpha48,
                                   ColorSchemeColorTabSelected: graphite,
                                   ColorSchemeColorTabHighlighted: lightGraphite,
                                   ColorSchemeColorCallBarBackground: white,
                                   ColorSchemeColorCallBarSeparator: lightGraphiteAlpha48,
                                   ColorSchemeColorBackgroundOverlay: blackAlpha24,
                                   ColorSchemeColorBackgroundOverlayWithoutPicture: blackAlpha80,
                                   ColorSchemeColorAvatarBorder: blackAlpha8,
                                   ColorSchemeColorContactSectionBackground: whiteAlpha80,
                                   ColorSchemeColorAudioButtonOverlay: lightGraphiteAlpha24,
                                   ColorSchemeColorPlaceholderBackground: [lightGraphiteAlpha8 removeAlphaByBlendingWithColor:white98],
                                   ColorSchemeColorLoadingDotActive: graphiteAlpha40,
                                   ColorSchemeColorLoadingDotInactive: graphiteAlpha16,
                                   ColorSchemeColorGraphite: graphite,
                                   ColorSchemeColorLightGraphite: lightGraphite,
                                   ColorSchemeColorPaleSeparator: lightGraphiteAlpha24,
                                   ColorSchemeColorListAvatarInitials: blackAlpha40,
                                   ColorSchemeColorSectionBackground: UIColor.clearColor,
                                   ColorSchemeColorSectionText: blackAlpha40,
                                   ColorSchemeColorTokenFieldBackground: blackAlpha4,
                                   ColorSchemeColorTokenFieldTextPlaceHolder: graphiteAlpha40
                                   }];
    
    for (ZMAccentColor color = ZMAccentColorMin; color <= ZMAccentColorMax; color++) {
        UIColor *nameAccentColor = [UIColor nameColorForZMAccentColor:color variant:ColorSchemeVariantLight];
        [lightColors setObject:nameAccentColor forKey:ColorSchemeNameAccentColorForColor(color)];
    }
    
    NSMutableDictionary *darkColors = [NSMutableDictionary dictionaryWithDictionary:
                               @{ ColorSchemeColorAccent: accentColor,
                                  ColorSchemeColorAccentDimmed: [accentColor colorWithAlphaComponent:0.16],
                                  ColorSchemeColorAccentDimmedFlat: [[accentColor colorWithAlphaComponent:0.16] removeAlphaByBlendingWithColor:backgroundGraphite],
                                  ColorSchemeColorAccentDarken: [[accentColor mix:[UIColor blackColor] amount:0.1] colorWithAlphaComponent:0.32],
                                  ColorSchemeColorTextForeground: white,
                                  ColorSchemeColorTextBackground: backgroundGraphite,
                                  ColorSchemeColorTextDimmed: lightGraphite,
                                  ColorSchemeColorTextPlaceholder: lightGraphiteAlpha64,
                                  ColorSchemeColorSeparator: lightGraphiteAlpha24,
                                  ColorSchemeColorBarBackground: backgroundLightGraphite,
                                  ColorSchemeColorBackground: backgroundGraphite,
                                  ColorSchemeColorConversationBackground: backgroundGraphite,
                                  ColorSchemeColorIconNormal: white,
                                  ColorSchemeColorIconSelected: black,
                                  ColorSchemeColorIconHighlighted: white,
                                  ColorSchemeColorIconShadow: blackAlpha24,
                                  ColorSchemeColorIconHighlight: whiteAlpha16,
                                  ColorSchemeColorIconBackgroundSelected: white,
                                  ColorSchemeColorIconBackgroundSelectedNoAccent: white,
                                  ColorSchemeColorPopUpButtonOverlayShadow: black,
                                  ColorSchemeColorButtonHighlighted: blackAlpha24,
                                  ColorSchemeColorButtonEmptyText: white,
                                  ColorSchemeColorTabNormal: lightGraphite,
                                  ColorSchemeColorTabSelected: white,
                                  ColorSchemeColorTabHighlighted: lightGraphiteAlpha48,
                                  ColorSchemeColorCallBarBackground: black,
                                  ColorSchemeColorCallBarSeparator: clear,
                                  ColorSchemeColorBackgroundOverlay: blackAlpha48,
                                  ColorSchemeColorBackgroundOverlayWithoutPicture: blackAlpha80,
                                  ColorSchemeColorAvatarBorder: whiteAlpha16,
                                  ColorSchemeColorContactSectionBackground: blackAlpha80,
                                  ColorSchemeColorAudioButtonOverlay: lightGraphiteAlpha24,
                                  ColorSchemeColorPlaceholderBackground: [lightGraphiteAlpha8 removeAlphaByBlendingWithColor:backgroundGraphite],
                                  ColorSchemeColorLoadingDotActive: whiteAlpha40,
                                  ColorSchemeColorLoadingDotInactive: whiteAlpha16,
                                  ColorSchemeColorGraphite: graphite,
                                  ColorSchemeColorLightGraphite: lightGraphite,
                                  ColorSchemeColorPaleSeparator: lightGraphiteAlpha24,
                                  ColorSchemeColorListAvatarInitials: blackAlpha40,
                                  ColorSchemeColorSectionBackground: UIColor.clearColor,
                                  ColorSchemeColorSectionText: whiteAlpha40,
                                  ColorSchemeColorTokenFieldBackground: whiteAlpha16,
                                  ColorSchemeColorTokenFieldTextPlaceHolder: whiteAlpha40
                                  }];

    for (ZMAccentColor color = ZMAccentColorMin; color <= ZMAccentColorMax; color++) {
        UIColor *nameAccentColor = [UIColor nameColorForZMAccentColor:color variant:ColorSchemeVariantDark];
        [darkColors setObject:nameAccentColor forKey:ColorSchemeNameAccentColorForColor(color)];
    }

    NSMutableDictionary *colors = [NSMutableDictionary dictionary];
    
    [lightColors enumerateKeysAndObjectsUsingBlock:^(NSString *colorKey, UIColor *color, BOOL *stop) {
        [colors setObject:color forKey:light(colorKey)];
    }];
    
    [darkColors enumerateKeysAndObjectsUsingBlock:^(NSString *colorKey, UIColor *color, BOOL *stop) {
        [colors setObject:color forKey:dark(colorKey)];
    }];
    
    if (variant == ColorSchemeVariantLight) {
        [colors addEntriesFromDictionary:lightColors];
    } else {
        [colors addEntriesFromDictionary:darkColors];
    }
    
    return colors;
}

- (BOOL)brightColor:(UIColor *)color
{
    CGFloat red, green, blue, alpha;
    if ([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
        // Check if color is brighter then a threshold
        return ((red + green + blue) / 3.0f) > 0.55f;
    }

    return NO;
}

@end

@implementation UIColor (ColorScheme)

/// Creates UIColor instance with color corresponding to @p accentColor that can be used to display the name.
+ (UIColor *)nameColorForZMAccentColor:(ZMAccentColor)accentColor variant:(ColorSchemeVariant)variant
{
    // NB: the order of coefficients must match ZMAccentColor enum ordering
    static const CGFloat accentColorNameColorBlendingCoefficientsDark[] = {0.0f, 0.8f, 0.72f, 1.0f, 0.8f, 0.8f, 0.8f, 0.64f};
    static const CGFloat accentColorNameColorBlendingCoefficientsLight[] = {0.0f, 0.8f, 0.72f, 1.0f, 0.8f, 0.8f, 0.64f, 1.0f};
 
    assert(accentColor < ZMAccentColorMax);
    
    const CGFloat *coefficientsArray = variant == ColorSchemeVariantDark ? accentColorNameColorBlendingCoefficientsDark : accentColorNameColorBlendingCoefficientsLight;
    const CGFloat coefficient = coefficientsArray[accentColor];
    
    UIColor *background = variant == ColorSchemeVariantDark ? [UIColor blackColor] : [UIColor whiteColor];
    
    return [background mix:[UIColor colorForZMAccentColor:accentColor] amount:coefficient];
}

@end

