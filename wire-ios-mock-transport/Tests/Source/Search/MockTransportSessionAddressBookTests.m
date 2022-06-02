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


#import "MockTransportSessionTests.h"
@import WireMockTransport;

@interface MockTransportSessionAddressBookTests : MockTransportSessionTests

@end

@implementation MockTransportSessionAddressBookTests

- (void)testThatWhenPostingAddressBookItReturnsAllUserIDsThatAreNotSelf
{
    // GIVEN
    __block MockUser *user1;
    __block MockUser *user2;
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"SelfUser"];
        user1 = [session insertUserWithName:@"User1 AAAA"];
        user2 = [session insertUserWithName:@"User2 AABB"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    
    // WHEN
    NSDictionary *upstreamPayload = @{
                                      @"self":@[@"2312rfw32434234"],
                                      @"cards": @[@{@"contact":@[]}]
                                      };
    NSString *path = [NSString pathWithComponents:@[@"/", @"onboarding", @"v3"]];
    ZMTransportResponse *response = [self responseForPayload:upstreamPayload path:path method:ZMMethodPOST apiVersion:0];
    
    // THEN
    NSDictionary *expectedPayload = @{
                                      @"results": @[
                                              @{@"id": user1.identifier, @"cards": @[]},
                                              @{@"id": user2.identifier, @"cards": @[]},
                                              ]
                                      };
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, expectedPayload);
}

- (void)testThatWhenPostingAddressBookItFailsIfMissingAnySelfElement
{
    // GIVEN
    NSDictionary *upstreamPayload = @{
                                      @"self":@[],
                                      @"contacts":@[]
                                      };
    NSString *path = [NSString pathWithComponents:@[@"/", @"onboarding", @"v3"]];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:upstreamPayload path:path method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 400);
}

- (void)testThatWhenPostingAddressBookItFailsIfMissingSelf
{
    // GIVEN
    NSDictionary *upstreamPayload = @{
                                      @"contacts":@[]
                                      };
    NSString *path = [NSString pathWithComponents:@[@"/", @"onboarding", @"v3"]];
    
    // WHEN
    [self performIgnoringZMLogError:^{
        ZMTransportResponse *response = [self responseForPayload:upstreamPayload path:path method:ZMMethodPOST apiVersion:0];
        
        // THEN
        XCTAssertEqual(response.HTTPStatus, 400);
    }];
}


- (void)testThatWhenPostingAddressBookItFailsIfMissingContacts
{
    // GIVEN
    NSDictionary *upstreamPayload = @{
                                      @"self":@[@"fooooooooo"]
                                      };
    NSString *path = [NSString pathWithComponents:@[@"/", @"onboarding", @"v3"]];
    
    // WHEN
    [self performIgnoringZMLogError:^{
        ZMTransportResponse *response = [self responseForPayload:upstreamPayload path:path method:ZMMethodPOST apiVersion:0];
        
        // THEN
        XCTAssertEqual(response.HTTPStatus, 400);
    }];
}


@end
