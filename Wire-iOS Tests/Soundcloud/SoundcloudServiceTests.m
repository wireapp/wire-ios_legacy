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


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "SoundcloudService.h"
#import "SoundcloudService+Testing.h"
#import "ZMUserSession+RequestProxy.h"
#import "OCMock/OCMock.h"



@interface SoundcloudServiceTests : XCTestCase

@property (nonatomic, readonly) SoundcloudService  *service;
@property (nonatomic, readonly) id sessionMock;

@end

@implementation SoundcloudServiceTests

- (void)setUp
{
    [super setUp];
    
    _sessionMock = [OCMockObject niceMockForClass:[ZMUserSession class]];
    _service = [[SoundcloudService alloc] initWithUserSession:_sessionMock];
}

- (void)tearDown
{
    [_sessionMock stopMocking];
    _sessionMock = nil;
    _service = nil;
    [super tearDown];
}

- (void)testThatloadAudioResourceFromURLConstructsValidRequest
{
    // given
    NSURL *URL = [NSURL URLWithString:@"https://soundcloud.com/goldenbest/ho-ga-toppar-djupa-basar"];
    NSString *expectedPath = [NSString stringWithFormat:@"/resolve?url=%@", URL.absoluteString];
    
    // expect
    [[_sessionMock expect] doRequestWithPath:expectedPath method:ZMMethodGET type:ProxiedRequestTypeSoundcloud completionHandler:OCMOCK_ANY];
    
    // when
    [self.service loadAudioResourceFromURL:URL completion:nil];
    
    OCMVerifyAll(self.sessionMock);
}

- (void)testThatItIgnoresInconsistentResponse
{
    // given
    NSArray *responseStructure = @[@"some", @"test", @{@"some": @1}];
    NSData *jsonResponseData = [NSJSONSerialization dataWithJSONObject:responseStructure options:NSJSONWritingPrettyPrinted error:NULL];
    NSURLResponse *response = nil;

    // when
    id result = [self.service audioObjectFromData:jsonResponseData response:response];
    
    // then
    // No crash happened and
    XCTAssertNil(result);
}

- (void)testThatItIgnoresNilResponse
{
    // given
    NSData *responseData = nil;
    NSURLResponse *response = nil;
    
    // when
    id result = [self.service audioObjectFromData:responseData response:response];
    
    // then
    // No crash happened and
    XCTAssertNil(result);
}

@end
