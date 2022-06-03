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


#import "ZMTFailureRecorder.h"

@interface ZMTFailureRecorder ()

@property (nonatomic) XCTestCase *testCase;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic) NSUInteger lineNumber;

@end


@implementation ZMTFailureRecorder

- (instancetype)initWithTestCase:(XCTestCase *)testCase filePath:(const char *)filePath lineNumber:(NSUInteger)lineNumber;
{
    self = [super init];
    if (self != nil) {
        self.testCase = testCase;
        self.filePath = [NSString stringWithUTF8String:filePath];
        self.lineNumber = lineNumber;
    }
    return self;
}

- (void)recordFailure:(NSString *)format, ...;
{
    va_list ap;
    va_start(ap, format);
    NSString *d = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    [self.testCase recordFailureWithDescription:d inFile:self.filePath atLine:self.lineNumber expected:YES];
}

@end
