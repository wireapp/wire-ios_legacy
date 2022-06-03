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


@import WireSystem;

#import "NSString+Normalization.h"


@implementation NSString (Normalization)

- (instancetype)normalizedInternal
{
    NSMutableString *string = [self mutableCopy];

    CFRange range = CFRangeMake(0, (NSInteger)string.length);
    Boolean success = CFStringTransform((__bridge CFMutableStringRef)string, &range, (__bridge CFStringRef) @"Any-Latin; Latin-ASCII; Lower", NO);
    VerifyString(success, "Unable to normalize string");
    return string;
}

- (instancetype)normalizedEmailaddress;
{
    return [self normalizedInternal];
}

- (instancetype)normalizedForSearch
{
    NSString *string = [self stringByFoldingWithOptions:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch locale:nil];
    return string.removePunctuationCharacters;
}

- (instancetype)normalizedForMentionSearch
{
    return [self stringByFoldingWithOptions:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch locale:nil];
}

- (instancetype)normalizedString;
{
    NSString *string = [self normalizedEmailaddress];
    NSString *cleanedString = [string removeNonAlphaNumericCharacters];
    return cleanedString;
}

- (instancetype)removeNonAlphaNumericCharacters
{
    NSMutableCharacterSet *characterSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    NSCharacterSet *invertedSet = [characterSet invertedSet];
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.charactersToBeSkipped = invertedSet;
    
    NSMutableString *result = [NSMutableString string];
    while (!scanner.atEnd) {
        NSString *subString;
        if ([scanner scanCharactersFromSet:characterSet intoString:&subString]) {
            [result appendString:subString];
        }
    }
    return result;
}

- (instancetype)removePunctuationCharacters
{
    return [[self componentsSeparatedByCharactersInSet:NSCharacterSet.punctuationCharacterSet] componentsJoinedByString:@""];
}

- (BOOL)zmHasOnlyWhitespaceCharacters
{
    __block BOOL hasOnlyWhitespaceCharacters = YES;
    
    [self enumerateLinguisticTagsInRange:NSMakeRange(0, self.length) scheme:NSLinguisticTagSchemeTokenType options:NSLinguisticTaggerOmitWhitespace orthography:nil usingBlock:^(NSString *tag, NSRange __unused tokenRange, NSRange __unused sentenceRange, BOOL *stop) {
        if (tag != nil) {
            *stop = YES;
            hasOnlyWhitespaceCharacters = NO;
            return;
        }
    }];
    
    return hasOnlyWhitespaceCharacters;
}


@end
