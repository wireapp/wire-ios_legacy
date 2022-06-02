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
@import WireSystem;
@import WireTransport;
#import "WireTransport_ios_tests-Swift.h"


@interface ZMNetworkSocketTest : ZMTBaseTest <NetworkSocketDelegate>

@property (nonatomic) NetworkSocket *sut;
@property (nonatomic) NSMutableData *dataRead;
@property (nonatomic) NSInteger openCounter;
@property (nonatomic) NSInteger closeCounter;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) MockCertificateTrust *trustProvider;

@end


@implementation ZMNetworkSocketTest

- (void)setUp
{
    [super setUp];
    self.openCounter = 0;
    self.closeCounter = 0;
    self.dataRead = [NSMutableData dataWithCapacity:16 * 1024];
    self.queue = dispatch_get_main_queue();
    self.trustProvider = [[MockCertificateTrust alloc] init];
}

- (void)tearDown
{
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.5);
    self.queue = nil;
    self.trustProvider = nil;
    if(self.sut != nil) {
        XCTAssertEqual(self.closeCounter, 1);
    }
    self.sut = nil;
    [super tearDown];
}

- (BOOL)checkThatWeCanRetrieveHTTPSURL:(NSURL *)url ZM_MUST_USE_RETURN
{
    self.sut = [[NetworkSocket alloc] initWithUrl:url
                                    trustProvider:self.trustProvider
                                         delegate:self
                                            queue:self.queue
                                    callbackQueue:self.queue
                                            group:self.dispatchGroup];
    XCTAssertNotNil(self.sut);
    BOOL success = [self checkThatWeCanRetrieveHTTPSURL:url withNetworkSocket:self.sut];
    [self.sut close];
    WaitForAllGroupsToBeEmpty(0.5);
    return success;
}

- (BOOL)checkThatWeCanRetrieveHTTPSURL:(NSURL *)url withNetworkSocket:(NetworkSocket *)socket ZM_MUST_USE_RETURN
{
    
    NSString *requestHeader = [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
                               "Accept: */*\r\n"
                               "Accept-Encoding: gzip, deflate, compress\r\n"
                               "Host: %@\r\n"
                               "\r\n"
                               "\r\n", url.path, url.host ];
    NSData *requestData = [requestHeader dataUsingEncoding:NSUTF8StringEncoding];
    
    // when
    [socket open];
    [socket writeData:requestData];
    [self expectationForNotification:@"ZMNetworkSocketTest" object:nil handler:^BOOL(NSNotification *notification) {
        NOT_USED(notification);
        return YES;
    }];
    
    // then
    if(![self waitForCustomExpectationsWithTimeout:10 handler:nil]) {
        NSLog(@"Failed to contact server at URL: %@",url);
        return NO;
    }
    CFHTTPMessageRef message = CFHTTPMessageCreateEmpty(NULL, NO);
    if(!CFHTTPMessageAppendBytes(message, self.dataRead.bytes, (CFIndex) self.dataRead.length)) {
        CFRelease(message);
        return NO;
    }
    CFIndex status = CFHTTPMessageGetResponseStatusCode(message);
    if(!(status >= 100 && status < 400)) {
        CFRelease(message);
        NSLog(@"Unexpected return status %ld for URL: %@", status, url);
        return NO;
    }
    NSString *statusLine = CFBridgingRelease(CFHTTPMessageCopyResponseStatusLine(message));
    CFRelease(message);
    if(![statusLine hasPrefix:@"HTTP/1.1"]) {
        NSLog(@"Unexpected response status line from %@: %@", url, statusLine);
        return NO;
    }
    if(self.openCounter != 1) {
        return NO;
    }
    
    return YES;
}

- (void)testThatItRetrievesAWellKnownHomepage
{
    XCTAssertTrue([self checkThatWeCanRetrieveHTTPSURL:[NSURL URLWithString:@"https://www.apple.com/"]]);
}

- (void)testThatItFailsWhenRetrieveingFromANonexistingServer;
{
    NSURL *url = [NSURL URLWithString:@"https://127.0.0.1:38973/this-does-not-exist"];
    [self performIgnoringZMLogError:^{
        self.sut = [[NetworkSocket alloc] initWithUrl:url
                                        trustProvider:self.trustProvider
                                             delegate:self
                                                queue:self.queue
                                        callbackQueue:self.queue
                                                group:self.dispatchGroup];

        XCTAssertNotNil(self.sut);

        NSString *requestHeader = [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
                                   "Accept: */*\r\n"
                                   "Accept-Encoding: gzip, deflate, compress\r\n"
                                   "Host: %@\r\n"
                                   "User-Agent: ZMNetworkSocket\r\n"
                                   "\r\n"
                                   "\r\n", url.path, url.host ];
        NSData *requestData = [requestHeader dataUsingEncoding:NSUTF8StringEncoding];

        // when

        [self.sut open];
        [self.sut writeData:requestData];
        [self expectationForNotification:@"ZMNetworkSocketClosed" object:nil handler:^BOOL(NSNotification *notification) {
            NOT_USED(notification);
            return YES;
        }];


        // then
        XCTAssertTrue([self waitForCustomExpectationsWithTimeout:5 handler:nil]);
        XCTAssertEqual(self.dataRead.length, 0u);
        XCTAssertEqual(self.openCounter, 0);
        XCTAssertEqual(self.closeCounter, 1);
    }];
}

- (void)testThatItAutomaticallyClosesWhenDeallocated
{
    // GIVEN
    self.sut = [[NetworkSocket alloc] initWithUrl:[NSURL URLWithString:@"https://www.apple.com/"]
                                    trustProvider:self.trustProvider
                                         delegate:self
                                            queue:self.queue
                                    callbackQueue:self.queue
                                            group:self.dispatchGroup];
    XCTAssertNotNil(self.sut);
    
    // WHEN
    [self expectationForNotification:@"ZMNetworkSocketClosed" object:nil handler:^BOOL(NSNotification *notification) {
        NOT_USED(notification);
        return YES;
    }];
    
    self.sut = nil;
    
    // THEN
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:5 handler:nil]);
}

- (void)didReceiveData:(NSData *)data networkSocket:(NetworkSocket *)socket
{
    XCTAssertEqual(socket, self.sut);
    [self.dataRead appendData:(NSData *) data];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZMNetworkSocketTest" object:self.dataRead];
}

- (void)networkSocketDidClose:(NetworkSocket *)socket
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZMNetworkSocketClosed" object:socket];
    if (self.sut != nil) {
        XCTAssertEqual(socket, self.sut);
    }
    self.closeCounter++;
}

- (void)networkSocketDidOpen:(NetworkSocket *)socket
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZMNetworkSocketOpened" object:socket];
    XCTAssertEqual(socket, self.sut);
    self.openCounter++;
}

@end
