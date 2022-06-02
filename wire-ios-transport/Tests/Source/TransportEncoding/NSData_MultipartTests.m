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


@import XCTest;
@import WireTransport;

@interface NSData_MultipartTests : XCTestCase

@end

@implementation NSData_MultipartTests


- (void)testThatItReturnsComponentsSeparatedByData
{
    NSData *data1 = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data2 = [@"2" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data3 = [@"3" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *separator = [@"-" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *fullData = [@"1-2-3" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *components = [fullData componentsSeparatedByData:separator];
    NSArray *expectedComponents = @[data1, data2, data3];
    XCTAssertEqualObjects(components, expectedComponents);
}

- (void)testThatItReturnsComponentsSeparatedByDataWithTralingSeparator
{
    NSData *data1 = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data2 = [@"2" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *separator = [@"-" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *fullData = [@"1-2-" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *components = [fullData componentsSeparatedByData:separator];
    NSArray *expectedComponents = @[data1, data2];
    XCTAssertEqualObjects(components, expectedComponents);
}

- (void)testThatItReturnsComponentsSeparatedByDataWithHeadingSeparator
{
    NSData *data1 = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data2 = [@"2" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *separator = [@"-" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *fullData = [@"-1-2" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *components = [fullData componentsSeparatedByData:separator];
    NSArray *expectedComponents = @[data1, data2];
    XCTAssertEqualObjects(components, expectedComponents);
}

- (void)testThatItDoesNotReturnEmptyComponent
{
    NSData *data1 = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data2 = [@"2" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *separator = [@"-" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *fullData = [@"---1--2--" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *components = [fullData componentsSeparatedByData:separator];
    NSArray *expectedComponents = @[data1, data2];
    XCTAssertEqualObjects(components, expectedComponents);
}

- (void)testThatItReturnsFullDataIfThereIsNoSeparator
{
    NSData *separator = [@"-" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *fullData = [@"123" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *components = [fullData componentsSeparatedByData:separator];
    NSArray *expectedComponents = @[fullData];
    XCTAssertEqualObjects(components, expectedComponents);
}

- (void)testThatItReturnsNoItemsForEmptyData
{
    NSData *separator = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *fullData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *components = [fullData componentsSeparatedByData:separator];
    NSArray *expectedComponents = @[];
    XCTAssertEqualObjects(components, expectedComponents);
}

- (void)testThatItReturnsLines
{
    NSData *data1 = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *separator = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *fullData = [@"1\r\n23\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *components = [fullData componentsSeparatedByData:separator];
    NSArray *expectedComponents = @[data1, [@"23" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertEqualObjects(components, expectedComponents);
}

- (void)testThatItCreatesDataFromItems
{
    // given
    NSData *data1 = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data2 = [@"2" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *contentType = @"text";
    NSDictionary *headers = @{@"key": @"value"};
    ZMMultipartBodyItem *item1 = [[ZMMultipartBodyItem alloc] initWithData:data1 contentType:contentType headers:headers];
    ZMMultipartBodyItem *item2 = [[ZMMultipartBodyItem alloc] initWithData:data2 contentType:contentType headers:headers];
    NSData *separator = [@"--boundary" dataUsingEncoding:NSUTF8StringEncoding];

    // expect
    NSArray *itemsContentData = @[data1, data2];
    NSArray *contentLengths = @[
                                [NSString stringWithFormat:@"Content-Length: %lu", (unsigned long)data1.length],
                                [NSString stringWithFormat:@"Content-Length: %lu", (unsigned long)data2.length]
                                ];
    NSString *expectedContentType = [NSString stringWithFormat:@"Content-Type: %@", contentType];
    NSString *expectedHeader = [NSString stringWithFormat:@"%@: %@", headers.allKeys.firstObject, headers.allValues.firstObject];
    
    // when
    NSData *multipartData = [NSData multipartDataWithItems:@[item1, item2] boundary:@"boundary"];
    NSArray *components = [multipartData componentsSeparatedByData:separator];
    
    // then
    XCTAssertEqual(components.count, 3u);
    XCTAssertEqualObjects(components.lastObject, [@"--\r\n" dataUsingEncoding:NSUTF8StringEncoding]);
    NSArray *itemsData = [components subarrayWithRange:NSMakeRange(0, 2)];
    
    NSUInteger index = 0;
    for (NSData *itemData in itemsData) {
        NSArray *lines = [itemData lines];
        XCTAssertEqual(lines.count, 4u);
        XCTAssertEqualObjects(lines.lastObject, itemsContentData[index]);
        NSString *itemContentType = [[NSString alloc] initWithData:lines[0] encoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects(itemContentType, expectedContentType);
        NSString *itemContentLength = [[NSString alloc] initWithData:lines[1] encoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects(itemContentLength, contentLengths[index]);
        NSString *header = [[NSString alloc] initWithData:lines[2] encoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects(header, expectedHeader);
        index++;
    }
}

- (void)testThatItReturnsItemsFromData
{
    NSData *data1 = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data2 = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *contentType = @"text";
    NSDictionary *headers = @{@"key": @"value"};
    ZMMultipartBodyItem *item1 = [[ZMMultipartBodyItem alloc] initWithData:data1 contentType:contentType headers:headers];
    ZMMultipartBodyItem *item2 = [[ZMMultipartBodyItem alloc] initWithData:data2 contentType:contentType headers:headers];
    
    NSString *boundary = @"boundary";
    NSData *multipartData = [NSData multipartDataWithItems:@[item1, item2] boundary:boundary];
    NSArray *items = [multipartData multipartDataItemsSeparatedWithBoundary:boundary];
    XCTAssertEqual(items.count, 2u);
    XCTAssertEqualObjects([items firstObject], item1);
    XCTAssertEqualObjects([items lastObject], item2);
}

@end


@interface ZMMultipartBodyItemTests : XCTestCase

@end

@implementation ZMMultipartBodyItemTests

- (void)testThatItCorrectlyInitializeMultipartBodyItemWithMultipartData
{
    NSData *data = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *contentType = @"text";
    NSDictionary *headers = @{@"key": @"value"};
    ZMMultipartBodyItem *item = [[ZMMultipartBodyItem alloc] initWithData:data contentType:contentType headers:headers];
    
    NSString *boundary = @"boundary";
    NSData *multipartData = [NSData multipartDataWithItems:@[item] boundary:boundary];
    NSData *itemData = [[multipartData componentsSeparatedByData:[[NSString stringWithFormat:@"--%@", boundary] dataUsingEncoding:NSUTF8StringEncoding]] firstObject];
    
    ZMMultipartBodyItem *createdItem = [[ZMMultipartBodyItem alloc] initWithMultipartData:itemData];
    XCTAssertEqualObjects(createdItem, item);
}

- (void)testThatItIgnoresMalformattedHeaderValues
{
    // given
    NSString *boundary = @"--boundary";
    NSData *data = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *malformedMultipartData = [NSMutableData data];
    [malformedMultipartData appendData:[boundary dataUsingEncoding:NSUTF8StringEncoding]];
    [malformedMultipartData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [malformedMultipartData appendData:[@"Content-Length: 1" dataUsingEncoding:NSUTF8StringEncoding]];
    [malformedMultipartData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [malformedMultipartData appendData:[@"good: header" dataUsingEncoding:NSUTF8StringEncoding]];
    [malformedMultipartData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [malformedMultipartData appendData:[@"bad:header" dataUsingEncoding:NSUTF8StringEncoding]];
    [malformedMultipartData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [malformedMultipartData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [malformedMultipartData appendData:data];
    [malformedMultipartData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // when
    ZMMultipartBodyItem *createdItem = [[ZMMultipartBodyItem alloc] initWithMultipartData:malformedMultipartData];
    
    // then
    XCTAssertEqual(createdItem.headers.count, 1u);
    XCTAssertEqualObjects(createdItem.headers[@"good"], @"header");
    XCTAssertEqualObjects(createdItem.data, data);
}

@end
