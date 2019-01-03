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


#import "NSString+EmoticonSubstitution.h"
#import "EmoticonSubstitutionConfiguration.h"

//@implementation NSString (EmoticonSubstitution)
//
//- (NSString *)stringByResolvingEmoticonShortcuts
//{
//    NSMutableString *resultString = [self mutableCopy];
//    [resultString resolveEmoticonShortcuts];
//    return resultString;
//}
//
//@end



@implementation NSMutableString (EmoticonSubstitution)

//- (void)resolveEmoticonShortcutsInRange:(NSRange)range
//{
//    EmoticonSubstitutionConfiguration *configuration = [EmoticonSubstitutionConfiguration sharedInstance];
//    NSArray *shortcuts = configuration.shortcuts;
//    for (NSString *shortcut in shortcuts) {
//        NSString *emoticon = [configuration emoticonForShortcut:shortcut];
//        NSUInteger howManyTimesReplaced = [self replaceOccurrencesOfString:shortcut
//                                                                withString:emoticon
//                                                                   options:NSLiteralSearch
//                                                                     range:range];
//        if (howManyTimesReplaced) {
//            range = NSMakeRange(range.location, MAX(range.length - (shortcut.length - emoticon.length) * howManyTimesReplaced,  0UL));
//        }
//    }
//}

//- (void)resolveEmoticonShortcuts
//{
//    [self resolveEmoticonShortcutsInRange:NSMakeRange(0, self.length)];
//}

@end
