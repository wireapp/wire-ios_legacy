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
@import WireSystem;
@import WireUtilities;
@import WireTesting;
@import WireTransport;

#import "ZMWebSocketHandshake.h"


@interface ZMWebSocketHandshakeTests : ZMTBaseTest

@property (nonatomic) DataBuffer *buffer;
@property (nonatomic) ZMWebSocketHandshake *sut;

@end

@implementation ZMWebSocketHandshakeTests

- (void)setUp {
    [super setUp];
    self.buffer = [[DataBuffer alloc] init];
    self.sut = [[ZMWebSocketHandshake alloc] initWithDataBuffer:self.buffer];
}

- (void)tearDown {
    [super tearDown];
}


- (void)testThatItParsesAHandshake
{
    // given
    [self fillBufferWithString:[[@[@"HTTP/1.1 101",
                                   @"Connection: upgrade",
                                   @"Upgrade: websocket",
                                   @"Sec-WebSocket-Accept: websocket"
                                   ]
                                 componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"]];
    
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];
    
    // then
    XCTAssertNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeCompleted);
}

- (void)testThatItParsesAHandshakeIntoAnHTTPURLResponse
{
    // given
    [self fillBufferWithString:[[@[@"HTTP/1.1 101",
                                   @"Connection: upgrade",
                                   @"Upgrade: websocket",
                                   @"Sec-WebSocket-Accept: websocket"
                                   ]
                                 componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"]];
    
    
    // when
    NSError *error;
    (void) [self.sut parseAndClearBufferIfComplete:NO error:&error];
    NSHTTPURLResponse *response = self.sut.response;
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.statusCode, 101);
    NSDictionary *expectedHeaders = @{@"Connection": @"upgrade",
                                      @"Upgrade": @"websocket",
                                      @"Sec-WebSocket-Accept": @"websocket"};
    XCTAssertEqualObjects(response.allHeaderFields, expectedHeaders);
    
}

- (void)testThatItParsesA_429_IntoAnHTTPURLResponse
{
    // given
    [self fillBufferWithString:[[@[@"HTTP/1.1 429",
                                   @"Content-Type: text/html",
                                   @"Retry-After: 3600",
                                   ]
                                 componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"]];
    
    
    // when
    NSError *error;
    (void) [self.sut parseAndClearBufferIfComplete:NO error:&error];
    NSHTTPURLResponse *response = self.sut.response;
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.statusCode, 429);
    NSDictionary *expectedHeaders = @{@"Content-Type": @"text/html",
                                      @"Retry-After": @"3600"};
    XCTAssertEqualObjects(response.allHeaderFields, expectedHeaders);
}

- (void)testThatItDoesNotParseAnEmptyBuffer {
    // given
    [self fillBufferWithString:@""];
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];
    
    // then
    XCTAssertNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeNeedsMoreData);
}


- (void)testThatTheOrderOfHeaderFieldsAfterHTTPDoesNotMatter {
    
    // given
    [self fillBufferWithString:[[@[@"HTTP/1.1 101",
                                   @"Upgrade: websocket",
                                   @"Sec-WebSocket-Accept: websocket",
                                   @"Connection: upgrade"
                                   ]
                                 componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"]];
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];
    
    // then
    XCTAssertNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeCompleted);
}

- (void)testThatParsingFailsIfFirstLineIsNotHTTP {
    // given
    [self fillBufferWithString:[[@[@"Upgrade: websocket",
                                   @"Sec-WebSocket-Accept: websocket",
                                   @"HTTP/1.1 101",
                                   @"Connection: upgrade"
                                   ]
                                 componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"]];
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];

    
    // then
    XCTAssertNotNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeError);
}


- (void)testThatParsingFailsIfThereIsFaultyHeader {
    // given
    [self fillBufferWithString:[[@[@"HTTP/1.1 101",
                                   @"Upgrade: websocket",
                                   @"Sec-WebSocket-Accept: websocket",
                                   @"Connection: FAIL--FAIL--FAIL--FAIL"
                                   ]
                                 componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"]];
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];
    
    // then
    XCTAssertNotNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeError);
}

- (void)testThatParsingFailsIfTheStatusIsNot101 {
    // given
    [self fillBufferWithString:[[@[@"HTTP/1.1 404",
                                   @"Connection: upgrade",
                                   @"Upgrade: websocket",
                                   @"Sec-WebSocket-Accept: websocket"
                                   ]
                                 componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"]];
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];
    
    // then
    XCTAssertNotNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeError);
}

- (void)testThatParsingIsCaseInsensitive {
    
    // given
    [self fillBufferWithString:[[@[@"http/1.1 101",
                                   @"upgrade: websocket",
                                   @"sec-webSocket-accEPt: weBSOcket",
                                   @"coNNECtion: upgrADE"
                                   ]
                                 componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"]];
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];
    
    // then
    XCTAssertNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeCompleted);
}


- (void)testThatItCancelsParsingWhenTheHTTPResponseIsTooLong
{
    // We expect the response to be somewhere around 220 bytes.
    
    // given
    NSString *failHeader = [@"" stringByPaddingToLength:507 withString: @"X" startingAtIndex:0];
    [self fillBufferWithString:failHeader];
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];
    
    // then
    XCTAssertNotNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeError);
}


- (void)testThatItClearsTheHeaderFromBufferWhenRequested {
    
    // given
    NSString *expectedRemainingString = @"Remaining frame data";
    [self fillBufferWithString:[@[@"HTTP/1.1 101",
                                   @"Connection: upgrade",
                                   @"Upgrade: websocket",
                                   @"Sec-WebSocket-Accept: websocket",
                                   @"",
                                   expectedRemainingString
                                   ]
                                 componentsJoinedByString:@"\r\n"]];
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:YES error:&error];
    
    // then
    XCTAssertNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeCompleted);
    
    dispatch_data_t expectedRemainingData = [expectedRemainingString dataUsingEncoding:NSUTF8StringEncoding].dispatchData;
    XCTAssertEqualObjects(self.buffer.objcData, expectedRemainingData);
}


- (void)testThatItDoesNotClearTheHeaderFromBufferWhenNotRequestedTo {
    
    // given
    NSString *allData = [@[@"HTTP/1.1 101",
                            @"Connection: upgrade",
                            @"Upgrade: websocket",
                            @"Sec-WebSocket-Accept: websocket",
                            @"",
                            @"Additional data"
                            ]
                          componentsJoinedByString:@"\r\n"];
    
    [self fillBufferWithString:allData];
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];
    
    // then
    XCTAssertNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeCompleted);
    
    dispatch_data_t expectedRemainingData = [allData dataUsingEncoding:NSUTF8StringEncoding].dispatchData;
    XCTAssertEqualObjects(self.buffer.objcData, expectedRemainingData);
}



- (void)testThatItDoesNotParseAHandshakeIfTheHTTPResponseIsNotComplete {
    
    // given
    [self fillBufferWithString:[[@[@"HTTP/1.1 101",
                                   @"Connection: upgrade",
                                   @"Upgrade: websocket",
                                   @"Sec-WebSocket-Accept: websocket"
                                   ]
                                 componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r"]];
    
    
    // when
    NSError *error;
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];
    
    // then
    XCTAssertNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeNeedsMoreData);
}


- (void)testThatItActuallySetsTheErrorToNilIfThereIsNoError {
    // given
    [self fillBufferWithString:@""];
    
    // when
    NSError *error = [NSError errorWithDomain:@"test" code:0 userInfo:@{}];
    ZMWebSocketHandshakeResult didComplete = [self.sut parseAndClearBufferIfComplete:NO error:&error];
    
    // then
    XCTAssertNil(error);
    XCTAssertEqual(didComplete, ZMWebSocketHandshakeNeedsMoreData);
}


- (void)fillBufferWithString:(NSString *)stringData {
    dispatch_data_t data = [stringData dataUsingEncoding:NSUTF8StringEncoding].dispatchData;
    [self.buffer appendData:data];
}

@end
