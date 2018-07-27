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


#import "NSString+Mentions.h"
#import "MockUser.h"

@interface NSString_MentionsTests : XCTestCase

@property (nonatomic) NSArray *users;

@end

@implementation NSString_MentionsTests

- (void)setUp {
    [super setUp];

    self.users = [MockLoader mockObjectsOfClass:[MockUser class] fromFile:@"a_lot_of_people.json"];
}

- (void)testThatMatchesAreReturned {
    
    NSArray *matchingUsers = [@"some text @K" usersMatchingLastMention:self.users];
    
    XCTAssertTrue(matchingUsers.count > 0 , @"No matches returned. Expecting some matches");
}

- (void)testThatAFullMentionDoesNotReturnMatches
{
    NSArray *matchingUsers = [@"@KeraPedraza" usersMatchingLastMention:self.users];
    
    XCTAssertTrue(matchingUsers.count == 0 , @"Matches returned. Expecting no matches");
}

@end
