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


#import "NSString+TextTransform.h"

extern NSDictionary * TextTransformTable(void)
{
    return @{
             @"none" : @(TextTransformNone),
             @"upper" : @(TextTransformUpper),
             @"lower" : @(TextTransformLower),
             @"capitalize" : @(TextTransformCapitalize),
             };
}

@implementation NSString (TextTransform)

+ (NSDictionary *)textTransformTable
{
    return TextTransformTable();
}

+ (TextTransform)textTransformFromString:(NSString *)string
{
    return [self.textTransformTable[string.lowercaseString] unsignedIntegerValue];
}

- (NSString *)transformStringWithTransform:(TextTransform)transform
{
    NSString *result = nil;
    NSLocale *locale = [NSLocale currentLocale];
    switch (transform) {
        case TextTransformNone:
            result = [self copy];
            break;
        case TextTransformUpper:
            result = [self uppercaseStringWithLocale:locale];
            break;
        case TextTransformLower:
            result = [self lowercaseStringWithLocale:locale];
            break;
        case TextTransformCapitalize:
            result = [self capitalizedStringWithLocale:locale];
            break;
        default:
            NSAssert(false, @"NSString TextTransform Transform: %lu is not supported", (unsigned long)transform);
            break;
    }
    return result;
}

@end
