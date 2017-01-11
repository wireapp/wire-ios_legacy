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


#import "NSString+Fingerprint.h"

@implementation NSString (Fingerprint)

- (NSArray *)splitEvery:(NSUInteger)character
{
    NSAssert(character != 0, @"Cannot split every 0 char");
    
    NSMutableArray *result = [NSMutableArray array];
    
    NSUInteger pointer = 0;
    
    while (pointer < self.length) {
        [result addObject:[self substringWithRange:NSMakeRange(pointer, MIN(self.length - pointer, character))]];
        
        pointer+= character;
    }
    
    return result;
}

- (NSString *)fingerprintStringWithSpaces
{
    return [[self splitEvery:2] componentsJoinedByString:@" "];
}

- (NSAttributedString *)fingerprintStringWithAttributes:(NSDictionary *)attributes boldAttributes:(NSDictionary *)boldAttributes
{
    __block NSMutableAttributedString *mutableFingerprintString = [[NSMutableAttributedString alloc] initWithString:self];
    __block BOOL bold = YES;
    
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length)
                             options:NSStringEnumerationByWords
                          usingBlock:^(__unused NSString * _Nullable substring, NSRange substringRange,__unused NSRange enclosingRange,__unused BOOL * _Nonnull stop) {
                              [mutableFingerprintString addAttributes:bold ? boldAttributes : attributes
                                                                range:substringRange];
                              bold = !bold;
                          }];
    
    return [[NSAttributedString alloc] initWithAttributedString:mutableFingerprintString];
}

@end
