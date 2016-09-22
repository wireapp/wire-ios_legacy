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


#import "NSString+Wire.h"

# import <MobileCoreServices/MobileCoreServices.h>

static NSRegularExpression *slashCommandMatcher;


@implementation NSString (Wire)


- (NSString *)uppercaseStringWithCurrentLocale;
{
    return [self uppercaseStringWithLocale:[NSLocale currentLocale]];
}

- (NSString *)lowercaseStringWithCurrentLocale;
{
    return [self lowercaseStringWithLocale:[NSLocale currentLocale]];
}

- (BOOL)matchesSlashCommand
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        slashCommandMatcher = [NSRegularExpression regularExpressionWithPattern:@"^\\/" options:0 error:nil];
    });
    
    BOOL match = NO;
    
    if ([slashCommandMatcher matchesInString:self options:0 range:NSMakeRange(0, self.length)].count) {
        match = YES;
    }
    
    return match;
}


- (NSArray *)args
{
    if (self.matchesSlashCommand) {
        NSString *slashlessString = [self stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        return [slashlessString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    else {
        return [NSArray array];
    }
}

@end
