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

#import "XCTestCase+Helpers.h"


@implementation XCTestCase (Helpers)

+ (NSBundle *)bundle;
{
    return [NSBundle bundleForClass:[self class]];
}

+ (NSURL *)fileURLForResource:(NSString *)name extension:(NSString *)extension;
{
    NSURL *fileURL = [self.bundle URLForResource:name withExtension:extension];
    RequireString(fileURL != nil, "Unable to find resource '%s' with extension '%s'", name.UTF8String, extension.UTF8String);
    return fileURL;
}

- (NSURL *)fileURLForResource:(NSString *)name extension:(NSString *)extension;
{
    NSURL *fileURL = [self.class fileURLForResource:name extension:extension];
    RequireString(fileURL != nil, "Unable to find resource '%s' with extension '%s'", name.UTF8String, extension.UTF8String);
    return fileURL;
}

+ (NSData *)dataForResource:(NSString *)name extension:(NSString *)extension;
{
    NSURL *fileURL = [self fileURLForResource:name extension:extension];
    NSError *error = nil;
    NSData *result = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
    NSAssert(result, @"Unable to read test resource \"%@\": %@", fileURL.path, error);
    return result;
}

- (NSData *)dataForResource:(NSString *)name extension:(NSString *)extension;
{
    return [self.class dataForResource:name extension:extension];
}

- (NSData *)dataForJSONResource:(NSString *)name;
{
    return [self dataForResource:name extension:@"json"];
}

@end
