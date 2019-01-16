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


#import "UIColor+Mixing.h"


static CGFloat mix(CGFloat value0, CGFloat value1, double progress)
{
    return (CGFloat) (value0 * (1 - progress) + value1 * progress);
}



@implementation UIColor (Mixing)


- (UIColor *)mix:(UIColor *)color amount:(double)progress
{
    CGFloat red0, green0, blue0, alpha0,
            red1, green1, blue1, alpha1;
    [self getRed:&red0 green:&green0 blue:&blue0 alpha:&alpha0];
    [color getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
    CGFloat red = mix(red0, red1, progress);
    CGFloat green = mix(green0, green1, progress);
    CGFloat blue = mix(blue0, blue1, progress);
    CGFloat alpha = mix(alpha0, alpha1, progress);

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (UIColor *)removeAlphaByBlendingWithColor:(UIColor *)color
{
    CGFloat red0, green0, blue0, alpha0;
    [self getRed:&red0 green:&green0 blue:&blue0 alpha:&alpha0];
    
    CGFloat red1, green1, blue1;
    [color getRed:&red1 green:&green1 blue:&blue1 alpha:nil];
    
    CGFloat red = mix(red1, red0, alpha0);
    CGFloat green = mix(green1, green0, alpha0);
    CGFloat blue = mix(blue1, blue0, alpha0);
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
}

+ (UIColor *)wr_colorFromString:(NSString *)string
{
    NSScanner *scanner = [NSScanner scannerWithString:string];
    
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"rgba(), "];
    
    float r = 0, g = 0, b = 0, a = 1;
    [scanner scanFloat:&r];
    [scanner scanFloat:&g];
    [scanner scanFloat:&b];
    [scanner scanFloat:&a];
    
    if (scanner.atEnd) {
        return [UIColor colorWithRed:r / 255 green:g / 255 blue:b / 255 alpha:a];
    } else {
        return nil;
    }
}

@end
