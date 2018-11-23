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
#import <WireExtensionComponents/WireExtensionComponents-Swift.h>

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

- (BOOL)isCurrentAccentColor:(UIColor *)accentColor
{
    return [self.accentColor isEqualTo:accentColor];
}

- (void)setVariant:(ColorSchemeVariant)variant
{
    _variant = variant;
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
 
    assert(accentColor <= ZMAccentColorMax);
    
    const CGFloat *coefficientsArray = variant == ColorSchemeVariantDark ? accentColorNameColorBlendingCoefficientsDark : accentColorNameColorBlendingCoefficientsLight;
    const CGFloat coefficient = coefficientsArray[accentColor];
    
    UIColor *background = variant == ColorSchemeVariantDark ? [UIColor blackColor] : [UIColor whiteColor];
    return [background mix:[[UIColor alloc] initWithColorForZMAccentColor:accentColor] amount:coefficient];
}

@end
