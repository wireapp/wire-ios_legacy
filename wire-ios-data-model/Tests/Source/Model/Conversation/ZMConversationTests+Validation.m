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


@import WireUtilities;

#import "ZMConversationTests.h"

@interface ZMConversationValidationTests : ZMConversationTestsBase
@end

@implementation ZMConversationValidationTests

- (void)testThatItTrimmsTheUserDefinedNameForLeadingAndTrailingWhitespace;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.userDefinedName = @" \tasdfad \t";
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertEqualObjects(conversation.userDefinedName, @"asdfad");
}

- (void)testThatItRollsBackIfTheUserDefinedNameIsTooLong;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.userDefinedName = @"Short Name";
    [self.uiMOC saveOrRollback];
    
    // when
    conversation.userDefinedName = [@"" stringByPaddingToLength:200 withString:@"Long " startingAtIndex:0];
    [self performIgnoringZMLogError:^{
        [self.uiMOC saveOrRollback];
    }];
    
    // then
    XCTAssertEqualObjects(conversation.userDefinedName, @"Short Name");
}

- (void)testThatItReplacesNewlinesAndTabWithSpaces;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.userDefinedName = @"Name";
    [self.uiMOC saveOrRollback];
    
    // when
    conversation.userDefinedName = @"\tA\tB \tC\t\rD\r \nE";
    [self.uiMOC saveOrRollback];

    // then
    XCTAssertEqualObjects(conversation.userDefinedName, @"A B  C  D   E");
}

- (void)testThatItDoesNotValidateOnSyncContext_1;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.userDefinedName = @"Name";
        [self.syncMOC saveOrRollback];
        
        // when
        conversation.userDefinedName = @"\tA\tB \tC\t\rD\r \nE";
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertEqualObjects(conversation.userDefinedName, @"\tA\tB \tC\t\rD\r \nE");
    }];
}

- (void)testThatItDoesNotValidateOnSyncContext_2;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.userDefinedName = @"Name";
        [self.syncMOC saveOrRollback];
        NSString *veryLongName = [@"" stringByPaddingToLength:300 withString:@"Long " startingAtIndex:0];
        
        // when
        conversation.userDefinedName = veryLongName;
        [self.syncMOC saveOrRollback];
        
        // then

        XCTAssertEqualObjects(conversation.userDefinedName, veryLongName);
    }];
}

- (void)testThatItOnlyValidatesChangesOnUIContext;
{
    // given
    NSString *veryLongName = [@"" stringByPaddingToLength:200 withString:@"zeta" startingAtIndex:0];
    __block NSManagedObjectID *conversationID;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation1.userDefinedName = veryLongName;
        
        XCTAssertEqualObjects(conversation1.userDefinedName, veryLongName);
        [self.syncMOC saveOrRollback];
        conversationID = conversation1.objectID;
    }];
    
    // when
    ZMConversation *conversation2 = (id) [self.uiMOC objectWithID:conversationID];
    [conversation2 appendMessageWithText:@"Test Message"];
    
    // then
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    XCTAssertEqualObjects(conversation2.userDefinedName, veryLongName);
}

- (void)testThatItValidatesNilValuesAsValid
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.draftMessage = [[DraftMessage alloc] initWithText:@"My draft message text" mentions:@[] quote:nil];
    conversation1.userDefinedName = @"My Name";
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    
    // when
    conversation1.draftMessage = nil;
    conversation1.userDefinedName = nil;
    
    // then
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    XCTAssertNil(conversation1.draftMessage);
    XCTAssertNil(conversation1.userDefinedName);
}


@end
