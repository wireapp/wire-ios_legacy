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

#import "ZMPushChannelConnection+WebSocket.h"
#import "WireTransport_ios_tests-Swift.h"


@interface ZMPushChannelConnectionTests : ZMTBaseTest <ZMPushChannelConnectionConsumer>

@property (nonatomic) NSMutableArray *receivedData;
@property (nonatomic) NSInteger closeCounter;
@property (nonatomic) NSInteger openCounter;
@property (nonatomic) ZMPushChannelConnection *sut;
@property (nonatomic) id webSocketMock;
@property (nonatomic) ZMAccessToken *accessToken;
@property (nonatomic) NSString *clientID;
@property (nonatomic) MockEnvironment *environment;

@end

@interface ZMPushChannelConnectionTests (WebSocket)
@end

@implementation ZMPushChannelConnectionTests

- (void)pushChannel:(ZMPushChannelConnection *)channel didReceiveTransportData:(id<ZMTransportData>)data;
{
    XCTAssertEqual(channel, self.sut);
    XCTAssertNotNil(data);
    XCTAssertTrue(channel.isOpen);
    [self.receivedData addObject:data ?: @{}];
}

- (void)pushChannel:(ZMPushChannelConnection *)channel didCloseWithResponse:(NSHTTPURLResponse *)response error:(nullable NSError *)error;
{
    NOT_USED(response);
    NOT_USED(error);
    XCTAssertTrue((self.sut == nil) || (channel == self.sut));
    XCTAssertFalse(channel.isOpen);
    self.closeCounter++;
}

- (void)pushChannel:(ZMPushChannelConnection *)channel didOpenWithResponse:(NSHTTPURLResponse *)response;
{
    NOT_USED(response);
    XCTAssertEqual(channel, self.sut);
    XCTAssertTrue(channel.isOpen);
    self.openCounter++;
}

- (void)setUp
{
    [super setUp];

    self.webSocketMock = [OCMockObject niceMockForClass:[ZMWebSocket class]];
    self.accessToken = [[ZMAccessToken alloc] initWithToken:@"ffsdfsdf" type:@"TATA" expiresInSeconds:1000000];
    self.clientID = @"12do34l90as23a";
    self.environment = [[MockEnvironment alloc] init];
    self.environment.backendWSURL = [NSURL URLWithString:@"127.0.0.1"];
    
    [self verifyMockLater:self.webSocketMock];
    self.sut = [[ZMPushChannelConnection alloc] initWithEnvironment:self.environment
                                                   consumer:self
                                                      queue:self.fakeSyncContext
                                                  webSocket:self.webSocketMock
                                                accessToken:self.accessToken
                                                   clientID:self.clientID
                                            userAgentString:@"User-Agent: Mozilla/5.0"];
    
    self.receivedData = [NSMutableArray array];
    self.closeCounter = 0;
    self.openCounter = 0;
}

- (void)tearDown
{
    WaitForAllGroupsToBeEmpty(0.5);
    self.receivedData = nil;
    [self.sut close];
    self.sut = nil;
    self.accessToken = nil;
    self.webSocketMock = nil;
    [super tearDown];
}

- (void)testThatItNotifiesConsumerOfNewWebsocketData
{
    // given
    uint8_t const jsonBytes[] = "{\"foo\": \"bar\"}";
    NSData *jsonData = [NSData dataWithBytes:jsonBytes length:sizeof(jsonBytes) - 1];
    
    // when
    [self.sut webSocket:nil didReceiveFrameWithData:jsonData];
    WaitForAllGroupsToBeEmpty(0.01);
    
    // then
    XCTAssertEqual(self.receivedData.count, 1u);
    XCTAssertEqualObjects(self.receivedData[0], @{@"foo": @"bar"});
}

- (void)testThatItNotifiesConsumerOfNewWebsocketText
{
    // given
    NSString* text = @"{\"foo\": \"bar\"}";
   
    // when
    [self.sut webSocket:nil didReceiveFrameWithText:text];
    WaitForAllGroupsToBeEmpty(0.01);
    
    // then
    XCTAssertEqual(self.receivedData.count, 1u);
    XCTAssertEqualObjects(self.receivedData[0], @{@"foo": @"bar"});
}

- (void)testThatItDoesNotCallTheConsumerWhenReceivingMalformedJSON
{
    // given
    uint8_t const jsonBytes[] = "{\"foo\": \"ba}";
    NSData *jsonData = [NSData dataWithBytes:jsonBytes length:sizeof(jsonBytes) - 1];
    
    // when
    [self performIgnoringZMLogError:^{
        [self.sut webSocket:nil didReceiveFrameWithData:jsonData];
        WaitForAllGroupsToBeEmpty(0.01);
    }];
    
    // then
    XCTAssertEqual(self.receivedData.count, 0u);
}

- (void)testThatTheConsumerIsNotifiedWhenClosingThePushChannel
{
    
    // when
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.01);
    
    // then
    XCTAssertEqual(self.closeCounter, 1);
}

- (void)testThatTheConsumerIsNotifiedOnlyOnceWhenClosingThePushChannelMultipleTimes
{
    
    // when
    [self.sut close];
    [self.sut close];
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.01);
    
    // then
    XCTAssertEqual(self.closeCounter, 1);
}

- (void)testThatItDoesNotNotifyTheConsumerOfNewWebsocketDataAfterClosing
{
    // given
    uint8_t const jsonBytes[] = "{\"foo\": \"bar\"}";
    NSData *jsonData = [NSData dataWithBytes:jsonBytes length:sizeof(jsonBytes) - 1];
    
    // when
    [self.sut close];
    [self.sut webSocket:nil didReceiveFrameWithData:jsonData];
    WaitForAllGroupsToBeEmpty(0.01);
    
    // then
    XCTAssertEqual(self.receivedData.count, 0u);
}

- (void)testThatItInitializesTheWebSocketWithAuthenticationHeadersFromTheAccessToken
{
    [self.sut close];
    self.sut = nil;
    WaitForAllGroupsToBeEmpty(0.5);
    NSURL *baseURL = self.environment.backendWSURL;
    
    NSURL *expectedURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/await?client=%@", baseURL.absoluteString, self.clientID]];
    NSDictionary *expectedHeaders = self.accessToken.httpHeaders;
    id webSocketMock = [OCMockObject niceMockForClass:ZMWebSocket.class];
    [[[[webSocketMock stub] classMethod] andReturn:webSocketMock] alloc];
    (void) [[[webSocketMock expect] andReturn:nil] initWithConsumer:OCMOCK_ANY queue:OCMOCK_ANY group:self.fakeSyncContext.dispatchGroup url:expectedURL trustProvider:OCMOCK_ANY additionalHeaderFields:expectedHeaders];

    // when
    id userAgent = nil;
    
    self.sut = [[ZMPushChannelConnection alloc] initWithEnvironment:self.environment
                                                   consumer:self
                                                      queue:self.fakeSyncContext
                                                accessToken:self.accessToken
                                                   clientID:self.clientID
                                            userAgentString:userAgent];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // after
    [webSocketMock verify];
    [webSocketMock stopMocking];
}

- (void)testThatItSetsThePingInterval;
{
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqualWithAccuracy(self.sut.pingInterval, 40., 0.1);
}

- (void)testThatItSendsPingsAfterCreation;
{
    // given
    self.sut.pingInterval = 0.05;
    
    // expect
    __block int count = 0;
    [[[self.webSocketMock stub] andDo:^(NSInvocation * ZM_UNUSED i) {
        ++count;
    }] sendPingFrame];
    
    // when
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:0.5];
    while (0. < [end timeIntervalSinceNow]) {
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]]) {
            [NSThread sleepForTimeInterval:0.002];
        }
    }
    
    // then
    XCTAssertGreaterThan(count, 8);
    XCTAssertLessThan(count, 14);
}

- (void)testThatItSendsPingsWhenAskedToCheckTheConnection;
{
    // expect
    __block int count = 0;
    [[[self.webSocketMock stub] andDo:^(NSInvocation * ZM_UNUSED i) {
        ++count;
    }] sendPingFrame];
    
    // Wait for ping on startup:
    XCTAssert([self waitWithTimeout:0.5 verificationBlock:^BOOL{
        return (0 < count);
    }]);
    
    // when
    [self.sut checkConnection];

    XCTAssert([self waitWithTimeout:0.5 verificationBlock:^BOOL{
        return (1 < count);
    }]);
}

@end



@implementation ZMPushChannelConnectionTests (WebSocket)

- (void)testThatItCallsDidCloseWhenTheWebSocketCloses;
{
    // when
    [self.sut webSocketDidClose:self.webSocketMock HTTPResponse:nil error:nil];
    WaitForAllGroupsToBeEmpty(0.01);
    
    // then
    XCTAssertEqual(self.closeCounter, 1);
}

- (void)testThatItClosesTheWebSocketWhenItItselfCloses
{
    // expect
    [[self.webSocketMock expect] close];
    
    // when
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.01);
}


- (void)testThatItDoesNotGoIntoAnInfiniteLoopWhenClosingWebSocket
{
    // expect
    [[[self.webSocketMock stub] andDo:^(NSInvocation *inv ZM_UNUSED) {
        [self.sut webSocketDidClose:self.webSocketMock HTTPResponse:nil error:nil];
    }] close];
    
    // when
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.01);
}

- (void)testThatItCallsDidOpenWhenTheWebsocketOpens
{
    [self.sut webSocketDidCompleteHandshake:self.webSocketMock HTTPResponse:nil];
    WaitForAllGroupsToBeEmpty(0.01);
    
    // then
    XCTAssertEqual(self.openCounter, 1);
}

@end
