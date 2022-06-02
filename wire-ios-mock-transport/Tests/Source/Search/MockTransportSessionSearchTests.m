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

@interface MockTransportSessionSearchTests : MockTransportSessionTests

@end

@implementation MockTransportSessionSearchTests



- (void)testThatItRespondsWithSearchResults
{
    // GIVEN
    __block MockUser *user1;
    __block MockUser *user2;
    NSString *user2email = @"foo@example.com";
    NSString *user2phone = @"454545456456";
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"SelfUser"];
        user1 = [session insertUserWithName:@"User1 AAAA"];
        user2 = [session insertUserWithName:@"User2 AABB"];
        
        user1.accentID = 3;
        user2.email = user2email;
        user2.phone = user2phone;
        user2.accentID = 2;
        MockUser *user3 = [session insertUserWithName:@"User3 XXXX"];
        [session insertUserWithName:@"User4 YYYY"];
        
        
        MockConnection *connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user2];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        
        MockConnection *connection2 = [session insertConnectionWithSelfUser:selfUser toUser:user3];
        connection2.status = @"accepted";
        connection2.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [NSString pathWithComponents:@[@"/", @"search", @"contacts?q=AA&l=200&d=1"]];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    
    // THEN
    NSDictionary *expectedPayload = @{
                                      @"documents": @[
                                              @{
                                                  @"blocked": @NO,
                                                  @"accent_id": @3,
                                                  @"connected": @NO,
                                                  @"id": user1.identifier,
                                                  @"level": @1,
                                                  @"name": user1.name,
                                                  @"handle": user1.handle
                                                  },
                                              
                                              @{
                                                  @"blocked": @NO,
                                                  @"accent_id": @2,
                                                  @"connected": @YES,
                                                  @"id": user2.identifier,
                                                  @"level": @1,
                                                  @"name": user2.name,
                                                  @"handle": user2.handle
                                                  }
                                              ]
                                      };
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, expectedPayload);
}



- (void)testThatItLimitsTheNumberOfSearchResults
{
    // GIVEN
    __block MockUser *user1;
    __block MockUser *user2;
    __block MockUser *user3;
    NSString *user2email = @"foo2@example.com";
    NSString *user3email = @"foo3@example.com";
    NSString *user3phone = @"66767567657";
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"SelfUser"];
        user1 = [session insertUserWithName:@"User1 AA"];
        user2 = [session insertUserWithName:@"User2 AA"];
        user3 = [session insertUserWithName:@"User3 AA"];
        [session insertUserWithName:@"User4 BB"];
        
        user2.accentID = 2;
        user3.accentID = 2;
        user1.accentID = 2;
        user3.email = user3email;
        user3.phone = user3phone;
        user2.email = user2email;
        
        MockConnection *connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user2];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        
        MockConnection *connection2 = [session insertConnectionWithSelfUser:selfUser toUser:user3];
        connection2.status = @"accepted";
        connection2.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [NSString pathWithComponents:@[@"/", @"search", @"contacts?q=aa&l=3&d=1"]];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    
    // THEN
    NSDictionary *expectedPayload = @{
                                      @"documents": @[
                                              @{
                                                  @"blocked": @NO,
                                                  @"accent_id": @2,
                                                  @"connected": @NO,
                                                  @"id": user1.identifier,
                                                  @"level": @1,
                                                  @"name": user1.name,
                                                  @"handle": user1.handle
                                                  },
                                              
                                              @{
                                                  @"blocked": @NO,
                                                  @"accent_id": @2,
                                                  @"connected": @YES,
                                                  @"id": user2.identifier,
                                                  @"level": @1,
                                                  @"name": user2.name,
                                                  @"handle": user2.handle
                                                  },
                                              
                                              
                                              @{
                                                  @"blocked": @NO,
                                                  @"accent_id": @2,
                                                  @"connected": @YES,
                                                  @"id": user3.identifier,
                                                  @"level": @1,
                                                  @"name": user3.name,
                                                  @"handle": user3.handle
                                                  }
                                              ]
                                      };
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, expectedPayload);
}




- (void)testThatItDoesNotReturnSelfUser
{
    // GIVEN
    __block MockUser *user1;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"SelfUser"];
        user1 = [session insertUserWithName:@"OtherUser"];
        user1.accentID = 2;
        MockConnection *connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user1];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [NSString pathWithComponents:@[@"/", @"search", @"contacts?q=User&l=200&d=1"]];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    
    // THEN
    NSDictionary *expectedPayload = @{
                                      @"documents": @[
                                              @{
                                                  @"blocked": @NO,
                                                  @"accent_id": @2,
                                                  @"connected": @YES,
                                                  @"id": user1.identifier,
                                                  @"level": @1,
                                                  @"name": user1.name,
                                                  @"handle": user1.handle
                                                  }
                                              ]
                                      };
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, expectedPayload);
}

@end
