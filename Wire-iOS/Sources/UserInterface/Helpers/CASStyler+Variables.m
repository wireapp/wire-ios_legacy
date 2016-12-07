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


#import "CASStyler+Variables.h"



@implementation CASStyler (Variables)

- (void)applyDefaultColorSchemeWithAccentColor:(UIColor *)accentColor
{
    ColorScheme *colorScheme = [ColorScheme defaultColorScheme];
    colorScheme.accentColor = accentColor;
    [self applyColorScheme:colorScheme];
}

- (void)applyDefaultColorSchemeWithVariant:(ColorSchemeVariant)variant
{
    ColorScheme *colorScheme = [ColorScheme defaultColorScheme];
    colorScheme.variant = variant;
    [self applyColorScheme:colorScheme];
}

- (void)applyColorScheme:(ColorScheme *)colorScheme
{
    NSMutableDictionary *variables = [NSMutableDictionary dictionaryWithDictionary:self.variables];
    [variables addEntriesFromDictionary:[self classyColorsFromDictionary:colorScheme.colors]];
    self.variables = variables;
}

- (NSDictionary *)classyColorsFromDictionary:(NSDictionary *)colors
{
    NSMutableDictionary *classyColors = [NSMutableDictionary dictionary];
    
    [colors enumerateKeysAndObjectsUsingBlock:^(NSString *key, UIColor *color, BOOL *stop) {
        [classyColors setObject:[NSString stringWithFormat:@"#%@", [color cas_hexValueWithAlpha:YES]] forKey:[NSString stringWithFormat:@"$color-%@", key]];
    }];
    
    return classyColors;
}

@end
