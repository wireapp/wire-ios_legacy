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


#import <XCTest/XCTest.h>
#import "NSString+Fingerprint.h"



@interface NSString_FingerprintTests : XCTestCase

@end

@implementation NSString_FingerprintTests

- (void)testFingerprintAttributes {
    NSDictionary *regularAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:[UIFont systemFontSize]]};
    NSDictionary *boldAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:[UIFont systemFontSize]]};
    NSAttributedString *attributedString = [self.fingerprintString fingerprintStringWithAttributes:regularAttributes
                                                                                    boldAttributes:boldAttributes];
    
    __block BOOL bold = YES;
   [attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length)
                                      options:0
                                   usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
                                       NSString *stringInRange = [[attributedString.string substringWithRange:range] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                       if (stringInRange.length == 0) {
                                           return;
                                       }
                                       XCTAssertEqualObjects(attrs, bold ? boldAttributes : regularAttributes);
                                       bold = !bold;
   }];
}

#pragma mark - Helper

- (NSString *)fingerprintString
{
    return @"05 1c f4 ca 74 4b 80";
}

@end
