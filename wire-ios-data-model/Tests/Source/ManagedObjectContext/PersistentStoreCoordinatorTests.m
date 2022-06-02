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
#import "ZMConversation+Internal.h"
#import "NSManagedObjectContext+zmessaging-Internal.h"
#import "ZMManagedObject+Internal.h"




@interface PersistentStoreCoordinatorTests : ZMBaseManagedObjectTest
@end



@implementation PersistentStoreCoordinatorTests

- (BOOL)shouldUseInMemoryStore;
{
    // This makes the test to use an on disk SQLite store
    return NO;
}

- (void)setUp
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *storeURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject] URLAppendingPersistentStoreLocation];
    
    if ([fm fileExistsAtPath:storeURL.path]) {
        NSError *error = nil;
        NSURL *parentURL;
        XCTAssert([storeURL getResourceValue:&parentURL forKey:NSURLParentDirectoryURLKey error:&error], @"%@", error);
        XCTAssert([[NSFileManager defaultManager] removeItemAtURL:parentURL error:&error],
                  @"Failed to remove directory %@", parentURL.path);
    }
    
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testThatChangesInOneContextAreVisibleInAnother
{
    // when
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);
    
    __block ZMConversation *syncConversation;
    [self.syncMOC performGroupedBlockAndWait:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ZMConversation.entityName];
        NSArray *result = [self.syncMOC executeFetchRequestOrAssert:request];
        
        // then
        XCTAssertEqual(result.count, 1u);
        syncConversation = result[0];
    }];

    XCTAssertEqualObjects(syncConversation.objectID, conversation.objectID);
}

- (void)testThatPermissionsAreCorrectlySet;
{
    NSError *error;
    NSURL *parentURL;
    XCTAssert([self.testSession.storeURL getResourceValue:&parentURL forKey:NSURLParentDirectoryURLKey error:&error], @"%@", error);
    
    NSNumber *excluded;
    XCTAssert([parentURL getResourceValue:&excluded forKey:NSURLIsExcludedFromBackupKey error:&error], @"%@", error);
    XCTAssertTrue(excluded.boolValue);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:parentURL.path error:&error];
    XCTAssertNotNil(attributes, @"%@", error);
    int permissions = ((NSNumber *) attributes[NSFilePosixPermissions]).intValue;
    XCTAssertEqual(permissions & 0077, 0);
}

@end
