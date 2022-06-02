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
@import WireTesting;
@import OCMock;
@import WireTransport;

#import "ZMWebSocket.h"
#import "WireTransport_ios_tests-Swift.h"


@interface ZMWebSocketTests : ZMTBaseTest <ZMWebSocketConsumer>

@property (nonatomic) NSURL *URL;
@property (nonatomic) ZMWebSocket<NetworkSocketDelegate> *sut;
@property (nonatomic) NSMutableArray *receivedData;
@property (nonatomic) NSMutableArray *receivedText;
@property (nonatomic) NSInteger closeCounter;
@property (nonatomic) NetworkSocket *networkSocketMock;
@property (nonatomic) NSInteger openCounter;
@property (nonatomic) NSHTTPURLResponse *openResponse;
@property (nonatomic) NSHTTPURLResponse *closeResponse;
@property (nonatomic) NSError *closeError;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) MockCertificateTrust *trustProvider;

@end

@interface ZMWebSocketTests (Handshake)
@end
@interface ZMWebSocketTests (NetworkSocket)
@end

@implementation ZMWebSocketTests

- (void)webSocket:(ZMWebSocket *)webSocket didReceiveFrameWithData:(NSData *)data;
{
    XCTAssertEqual(webSocket, self.sut);
    [self.receivedData addObject:data];
}

- (void)webSocket:(ZMWebSocket *)webSocket didReceiveFrameWithText:(NSString *)text;
{
    XCTAssertEqual(webSocket, self.sut);
    [self.receivedText addObject:text];
}

- (void)webSocketDidClose:(ZMWebSocket *)webSocket HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *)error;
{
    XCTAssertEqual(webSocket, self.sut);
    ++self.closeCounter;
    self.closeResponse = response;
    self.closeError = error;
}

- (void)webSocketDidCompleteHandshake:(ZMWebSocket *)webSocket HTTPResponse:(NSHTTPURLResponse *)response
{
    XCTAssertEqual(webSocket, self.sut);
    ++self.openCounter;
    self.openResponse = response;
}

- (void)setUp {
    [super setUp];
    self.networkSocketMock = [OCMockObject niceMockForClass:NetworkSocket.class];
    [self verifyMockLater:self.networkSocketMock];
    self.queue = dispatch_get_main_queue();
    self.trustProvider = [[MockCertificateTrust alloc] init];
    self.URL = [NSURL URLWithString:@"wss://echo.websocket.org"];
    self.sut = (id)[[ZMWebSocket alloc] initWithConsumer:self
                                                   queue:self.queue
                                                   group:self.fakeUIContext.dispatchGroup
                                           networkSocket:self.networkSocketMock
                                      networkSocketQueue:nil
                                                     url:self.URL
                                           trustProvider:self.trustProvider
                                  additionalHeaderFields:nil];
    self.receivedData = [NSMutableArray array];
    self.receivedText = [NSMutableArray array];
    self.closeCounter = 0;
    self.openCounter = 0;
}

- (void)tearDown
{
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.5);
    self.sut = nil;
    self.networkSocketMock = nil;
    self.URL = nil;
    self.receivedData = nil;
    self.receivedText = nil;
    self.closeCounter = 0;
    self.openCounter = 0;
    [super tearDown];
}

- (void)testThatItNotifiesItsConsumerWhenItIsClosing
{
    WaitForAllGroupsToBeEmpty(0.5);
    // when
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.closeCounter, 1);
}

- (void)testThatItNotifiesItsConsumerOnlyOnceWhenItIsClosing
{
    WaitForAllGroupsToBeEmpty(0.5);
    // when
    [self.sut close];
    [self.sut close];
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.closeCounter, 1);
}

- (void)testThatItAnswersAPingWithAPong
{
    // given
    XCTestExpectation *expectation = [self expectationWithDescription:@"didReceiveData"];
    NSString *stringData = [[@[@"HTTP/1.1 101", @"Connection: upgrade", @"Upgrade: websocket", @"Sec-WebSocket-Accept: websocket"] componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"];
    [self.fakeUIContext performGroupedBlock:^{
        [self.sut networkSocketDidOpen:self.networkSocketMock];
    }];
    void(^sendDataToWebSocket)(id i) = ^(id ZM_UNUSED i){
        [self.fakeUIContext performGroupedBlock:^{
            [self.sut didReceiveData:[stringData dataUsingEncoding:NSUTF8StringEncoding] networkSocket:self.networkSocketMock];
            [expectation fulfill];
        }];
    };
    [[[(id) self.networkSocketMock expect] andDo:sendDataToWebSocket] writeData:OCMOCK_ANY];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5 handler:nil]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    dispatch_data_t pingData = dispatch_data_create(((uint8_t []){0x89, 0x80, 0x00, 0x00, 0x00, 0x00}), 6, NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    dispatch_data_t pongData = dispatch_data_create(((uint8_t []){0x8a, 0x80, 0x00, 0x00, 0x00, 0x00}), 6, NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    
    // expect
    [(NetworkSocket *)[(id) self.networkSocketMock expect] writeData:(NSData *)pongData];
    
    // when
    [self.sut didReceiveData:(NSData *)pingData networkSocket:self.networkSocketMock];
}

- (void)testThatItSendsAPing;
{
    // given
    NSString *stringData = [[@[@"HTTP/1.1 101", @"Connection: upgrade", @"Upgrade: websocket", @"Sec-WebSocket-Accept: websocket"] componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"didReceiveData"];
    [self.fakeUIContext performGroupedBlock:^{
        [self.sut networkSocketDidOpen:self.networkSocketMock];
    }];
    void(^sendDataToWebSocket)(id i) = ^(id ZM_UNUSED i){
        [self.fakeUIContext performGroupedBlock:^{
            [self.sut didReceiveData:[stringData dataUsingEncoding:NSUTF8StringEncoding] networkSocket:self.networkSocketMock];
            [expectation fulfill];
        }];
    };
    [[[(id) self.networkSocketMock expect] andDo:sendDataToWebSocket] writeData:OCMOCK_ANY];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    dispatch_data_t pingData = dispatch_data_create(((uint8_t []){0x89, 0x80, 0x00, 0x00, 0x00, 0x00}), 6, NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    
    // expect
    [(NetworkSocket *)[(id) self.networkSocketMock expect] writeData:(NSData *)pingData];
    
    // when
    [self.sut sendPingFrame];
}

@end



@implementation ZMWebSocketTests (Handshake)

- (void)testThatItSendsTheHandshakeRequest;
{
    // given
    __block NSData *sentData;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Did receive data."];
    [[(id) self.networkSocketMock expect] writeData:[OCMArg checkWithBlock:^BOOL(id obj) {
        [expectation fulfill];
        sentData = obj;
        return YES;
    }]];
    
    // when
    [self.fakeUIContext performGroupedBlock:^{
        [self.sut networkSocketDidOpen:self.networkSocketMock];
    }];

    
    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    // (check request)
    XCTAssertNotNil(sentData);
    CFHTTPMessageRef message = CFHTTPMessageCreateEmpty(NULL, YES);
    XCTAssertTrue(CFHTTPMessageAppendBytes(message, sentData.bytes, (CFIndex) sentData.length));
    XCTAssertEqualObjects(CFBridgingRelease(CFHTTPMessageCopyRequestMethod(message)), @"GET");
    NSDictionary *expectedHeaders = @{@"Upgrade": @"websocket",
                                      @"Host": self.URL.host,
                                      @"Connection": @"upgrade",
                                      @"Sec-WebSocket-Version": @"13"};
    [expectedHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *expectedValue, BOOL * ZM_UNUSED stop) {
        XCTAssertEqualObjects([CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(message, (__bridge CFStringRef) field)) lowercaseString],
                              expectedValue);
    }];
}

- (void)testThatItSendsTheHandshakeRequestWithExtraHeaderFields
{
    // given
    NSDictionary *extraHeaders = @{@"Authentication": @"foo", @"X-Baz": @"123"};
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.5);
    self.receivedData = [NSMutableArray array];
    self.receivedText = [NSMutableArray array];
    self.closeCounter = 0;
    self.openCounter = 0;
    
    self.sut = (id)[[ZMWebSocket alloc] initWithConsumer:self
                                                   queue:self.queue
                                                   group:self.fakeUIContext.dispatchGroup
                                           networkSocket:self.networkSocketMock
                                      networkSocketQueue:nil
                                                     url:self.URL
                                           trustProvider:self.trustProvider
                                  additionalHeaderFields:extraHeaders];
    __block NSData *sentData;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Did receive data."];
    [[(id) self.networkSocketMock expect] writeData:[OCMArg checkWithBlock:^BOOL(id obj) {
        [expectation fulfill];
        sentData = obj;
        return YES;
    }]];
    
    // when
    [self.fakeUIContext performGroupedBlock:^{
        [self.sut networkSocketDidOpen:self.networkSocketMock];
    }];
    
    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:1.0]);
    // (check request)
    XCTAssertNotNil(sentData);
    CFHTTPMessageRef message = CFHTTPMessageCreateEmpty(NULL, YES);
    XCTAssertTrue(CFHTTPMessageAppendBytes(message, sentData.bytes, (CFIndex) sentData.length));
    XCTAssertEqualObjects(CFBridgingRelease(CFHTTPMessageCopyRequestMethod(message)), @"GET");
    NSMutableDictionary *expectedHeaders = [@{@"Upgrade": @"websocket",
                                              @"Host": self.URL.host,
                                              @"Connection": @"upgrade",
                                              @"Sec-WebSocket-Version": @"13"} mutableCopy];
    [expectedHeaders addEntriesFromDictionary:extraHeaders];
    [expectedHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *expectedValue, BOOL * ZM_UNUSED stop) {
        XCTAssertEqualObjects([CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(message, (__bridge CFStringRef) field)) lowercaseString],
                              expectedValue);
    }];
}

- (void)testThatItSendsTheHandshakeRequestAndTheFirstFrame;
{
    // given
    NSMutableArray *sentData = [NSMutableArray array];
    
    NSData *httpResponse = [@"HTTP/1.1 101 Web Socket Protocol Handshake\r\n"
                            @"Upgrade: WebSocket\r\n"
                            @"Connection: Upgrade\r\n"
                            @"Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n"
                            @"Server: Kaazing Gateway\r\n"
                            @"Date: Fri, 04 Jul 2014 11:43:52 GMT\r\n"
                            @"\r\n"
                            @"\r\n"
                            @"\r\n"
                            @"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *dataToBeSent = [NSData dataWithBytes:((char []){'A', 'B'}) length:2];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Did receive data."];
    [[(id) self.networkSocketMock stub] writeData:[OCMArg checkWithBlock:^BOOL(id obj) {
        [sentData addObject:obj];
        if (sentData.count == 2) {
            [expectation fulfill];
        }
        else if(sentData.count == 1) {
            [self.sut didReceiveData:httpResponse networkSocket:self.networkSocketMock];
        }
        return YES;
    }]];
    
    // when
    [self.sut sendBinaryFrameWithData:dataToBeSent];
    [self.fakeUIContext performGroupedBlock:^{
        [self.sut networkSocketDidOpen:self.networkSocketMock];
    }];
    
    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    // (check request)
    XCTAssertEqual(sentData.count, 2u);
    NSData *requestData = sentData[0];
    CFHTTPMessageRef message = CFHTTPMessageCreateEmpty(NULL, YES);
    XCTAssertTrue(CFHTTPMessageAppendBytes(message, requestData.bytes, (CFIndex) requestData.length));
    XCTAssertEqualObjects(CFBridgingRelease(CFHTTPMessageCopyRequestMethod(message)), @"GET");
    
    NSData *frameData = [NSData dataWithBytes:((char unsigned []){0x81, 0x02, 'A', 'B'}) length:4];
    XCTAssertEqualObjects(sentData[1], frameData);
}

- (void)testThatItCompletesHandshake
{
    // given
    NSString *stringData = [[@[@"HTTP/1.1 101", @"Connection: upgrade", @"Upgrade: websocket", @"Sec-WebSocket-Accept: websocket"] componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"didReceiveData"];

    // when
    [self.fakeUIContext performGroupedBlock:^{
        [self.sut networkSocketDidOpen:self.networkSocketMock];
    }];
    void(^sendDataToWebSocket)(id i) = ^(id ZM_UNUSED i){
        [self.fakeUIContext performGroupedBlock:^{
            [self.sut didReceiveData:[stringData dataUsingEncoding:NSUTF8StringEncoding] networkSocket:self.networkSocketMock];
            [expectation fulfill];
        }];
    };
    [[[(id) self.networkSocketMock expect] andDo:sendDataToWebSocket] writeData:OCMOCK_ANY];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.openCounter, 1);
    XCTAssertNotNil(self.openResponse);
    XCTAssertNil(self.closeResponse);
    XCTAssertEqual(self.openResponse.statusCode, 101);
}

- (void)testThatItDoesNotCompletesHandshakeIfItDoesNotReceiveAFullRequest
{
    // given
    NSString *stringData = [[@[@"HTTP/1.1 101", @"Connection: upgrade", @"Upgrade: websocket", @"Sec-WebSocket-Accept: websocket"] componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"didReceiveData"];

    // when
    [self.fakeUIContext performGroupedBlock:^{
        [self.sut networkSocketDidOpen:self.networkSocketMock];
    }];
    void(^sendDataToWebSocket)(id i) = ^(id ZM_UNUSED i){
        [self.fakeUIContext performGroupedBlock:^{
            [self.sut didReceiveData:[stringData dataUsingEncoding:NSUTF8StringEncoding] networkSocket:self.networkSocketMock];
            [expectation fulfill];
        }];
    };
    [[[(id) self.networkSocketMock expect] andDo:sendDataToWebSocket] writeData:OCMOCK_ANY];
    WaitForAllGroupsToBeEmpty(0.1);
    
    // then
    XCTAssertEqual(self.openCounter, 0);
    XCTAssertNil(self.openResponse);
    XCTAssertNil(self.closeResponse);
}

- (void)testThatItClearsTheResponseBeforeCallingClose;
{
    // given
    NSString *stringData = [[@[@"HTTP/1.1 101", @"Connection: upgrade", @"Upgrade: websocket", @"Sec-WebSocket-Accept: websocket"] componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"];
    
    // when
    // (1) open
    [self.fakeUIContext performGroupedBlock:^{
        [self.sut networkSocketDidOpen:self.networkSocketMock];
    }];
    void(^sendDataToWebSocket)(id i) = ^(id ZM_UNUSED i){
        [self.fakeUIContext performGroupedBlock:^{
            [self.sut didReceiveData:[stringData dataUsingEncoding:NSUTF8StringEncoding] networkSocket:self.networkSocketMock];
        }];
    };
    [[[(id) self.networkSocketMock expect] andDo:sendDataToWebSocket] writeData:OCMOCK_ANY];
    WaitForAllGroupsToBeEmpty(0.5);
    // (2) close
    [self.sut networkSocketDidClose:self.networkSocketMock];
    
    XCTAssert([self waitOnMainLoopUntilBlock:^BOOL{
        return (0 < self.closeCounter);
    } timeout:0.5]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.openCounter, 1);
    XCTAssertNotNil(self.openResponse);
    XCTAssertNil(self.closeResponse);
    XCTAssertEqual(self.closeCounter, 1);
}


- (void)testThatItNotifiesTheConsumerIfTheHandshakeFails
{
    // given
    NSString *stringData = [[@[@"HTTP/1.1 400", @"Server: Apache"] componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n\r\n"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"didReceiveData"];

    // when
    [self performIgnoringZMLogError:^{
        [self.fakeUIContext performGroupedBlock:^{
            [self.sut networkSocketDidOpen:self.networkSocketMock];
        }];
        void(^sendDataToWebSocket)(id i) = ^(id ZM_UNUSED i){
            [self.fakeUIContext performGroupedBlock:^{
                [self.sut didReceiveData:[stringData dataUsingEncoding:NSUTF8StringEncoding] networkSocket:self.networkSocketMock];
                [expectation fulfill];
            }];
        };
        [[[(id) self.networkSocketMock expect] andDo:sendDataToWebSocket] writeData:OCMOCK_ANY];
        
        XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
        WaitForAllGroupsToBeEmpty(0.5);
    }];
    
    // then
    XCTAssertEqual(self.closeCounter, 1);
    XCTAssertNil(self.openResponse);
    XCTAssertNotNil(self.closeResponse);
    XCTAssertEqual(self.closeResponse.statusCode, 400);
}

@end


@implementation ZMWebSocketTests (NetworkSocket)

- (void)testThatItCallsDidCloseWhenTheNetworkSocketCloses;
{
    WaitForAllGroupsToBeEmpty(0.5);
    // when
    [self.sut networkSocketDidClose:self.networkSocketMock];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.closeCounter, 1);
    XCTAssertEqual(self.closeError.code, ZMWebSocketErrorCodeLostConnection);
}

- (void)testThatItClosesTheNetworkSocketWhenItItselfCloses
{
    // expect
    [[(id)self.networkSocketMock expect] close];
    
    // when
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.5);
}


- (void)testThatItDoesNotGoIntoAnInfiniteLoopWhenClosingNetworkSocket
{
    // expect
    [[[(id)self.networkSocketMock stub] andDo:^(NSInvocation *inv ZM_UNUSED) {
        [self.sut networkSocketDidClose:self.networkSocketMock];
    }] close];
    
    // when
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.5);
}

@end
