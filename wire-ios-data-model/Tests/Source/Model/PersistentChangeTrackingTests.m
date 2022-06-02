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


#import "ZMBaseManagedObjectTest.h"

#import "NSManagedObjectContext+zmessaging.h"

#import "ZMManagedObject+Internal.h"
#import "ZMUser+Internal.h"



//
// These test check that changes to model objects create a persisted change tracking.
// If the UI changes the 'name' of a conversation, we persistently track that this
// value needs to be pushed to the backend.
//



@interface PersistentChangeTrackingTests : ZMBaseManagedObjectTest


@end



@implementation PersistentChangeTrackingTests

- (void)testThatChangesAreMitigatedBetweenContexts;
{
    // Given
    __block NSString *error;
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"Foo Bar";
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    
    // When
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMUser entityName]];
    
    __block NSManagedObjectID *user2ID;
    __block NSString *user2Name;
    
    // That
    
    [self.syncMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        
        NSArray *users = [self.syncMOC executeFetchRequestOrAssert:request];
        if(users.count != 2u) { // The self user will be in there, too
            error = @"Users.count != 2";
            return;
        }
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        
        NSArray *others = [users filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ZMUser *u, NSDictionary *bindings) {
            NOT_USED(bindings);
            return (u != selfUser);
        }]];
        XCTAssertEqual(others.count, 1u);
        ZMUser *user2 = others[0];
        user2ID = user2.objectID;
        user2Name = user2.name;
    }];
    
    XCTAssertNil(error, @"%@", error);
    XCTAssertEqualObjects(user1.objectID, user2ID);
    XCTAssertEqualObjects(user1.name, user2Name);
}

@end
