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


#import <ZMTesting/ZMTesting.h>
#import <WireSyncEngine/WireSyncEngine.h>



@interface DatabaseMovingTests : ZMTBaseTest

@property (nonatomic) NSFileManager *fm;
@property (nonatomic) NSURL *cachesDirectoryStoreURL;
@property (nonatomic) NSURL *applicationSupportStoreURL;

@end



@implementation DatabaseMovingTests

- (void)setUp {
    [super setUp];
    [NSManagedObjectContext setUseInMemoryStore:NO];
    [self cleanUp];
    self.fm = [NSFileManager defaultManager];
    self.cachesDirectoryStoreURL = [NSManagedObjectContext storeURLInDirectory:NSCachesDirectory];
    self.applicationSupportStoreURL = [NSManagedObjectContext storeURLInDirectory:NSApplicationSupportDirectory];
}

- (void)tearDown
{
    [self cleanUp];
    [super tearDown];
}

- (void)cleanUp
{
    NSString *supportCachesPath = self.cachesDirectoryStoreURL.URLByDeletingLastPathComponent.path;
    if([self.fm fileExistsAtPath:supportCachesPath]) {
        [self.fm removeItemAtPath:supportCachesPath error:nil];
    }
    
    NSString *supportApplicationSupportPath = self.applicationSupportStoreURL.URLByDeletingLastPathComponent.path;
    if([self.fm fileExistsAtPath:supportApplicationSupportPath]) {
        [self.fm removeItemAtPath:supportApplicationSupportPath error:nil];
    }
    
    for(NSString *backupFolder in [self currentBackupFoldersInApplicationSupport]) {
        [self.fm removeItemAtPath:backupFolder error:nil];
    }
    
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
}

- (void)testThatItMovesTheDatabaseFromCachesToApplicationSupportDirectory
{
    // given
    [self performIgnoringZMLogError:^{
        XCTAssertTrue([self moveDatabaseToCachesDirectory]);
        XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStore]);
    }];
    
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.cachesDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.applicationSupportStoreURL.path stringByAppendingString:extension];
        XCTAssertFalse([self.fm fileExistsAtPath:toPath]);
        XCTAssertTrue([self.fm fileExistsAtPath:fromPath]);
    }
    
    // when
    XCTestExpectation *moveExpectation = [self expectationWithDescription:@"It should move the database files"];
    
    [self performIgnoringZMLogError:^{
        [NSManagedObjectContext prepareLocalStoreSync:NO backingUpCorruptedDatabase:NO completionHandler:^{
            [moveExpectation fulfill];
        }];
    
        XCTAssertTrue([self waitForCustomExpectationsWithTimeout:1]);
    }];
    
    // then
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.cachesDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.applicationSupportStoreURL.path stringByAppendingString:extension];
        XCTAssertTrue([self.fm fileExistsAtPath:toPath]);
        XCTAssertFalse([self.fm fileExistsAtPath:fromPath]);
    }
    
    NSString *supportURL = [self.applicationSupportStoreURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@".store_SUPPORT"].path;
    XCTAssertTrue([self.fm fileExistsAtPath:supportURL]);
}

- (void)testThatItWipesTheLocalStoreWhenItIsUnreadable
{
    // given
    [self performIgnoringZMLogError:^{
        XCTAssertTrue([self createdUnredableLocalStore]);
        XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStore]);
    }];
    
    NSString *storeFile = [self.applicationSupportStoreURL.path stringByAppendingString:@""];
    NSData *oldStoreFileData = [NSData dataWithContentsOfFile:storeFile];
    XCTAssertNotNil(storeFile);
    XCTAssertEqualObjects(oldStoreFileData, self.invalidData);
    
    // when
    XCTestExpectation *donePreparing = [self expectationWithDescription:@"It is done preparing"];
    
    [self performIgnoringZMLogError:^{
        [NSManagedObjectContext prepareLocalStoreSync:NO backingUpCorruptedDatabase:NO completionHandler:^{
            [donePreparing fulfill];
        }];
        
        XCTAssertTrue([self waitForCustomExpectationsWithTimeout:1]);
    }];
    
    // then
    NSData *newData = [NSData dataWithContentsOfFile:storeFile];
    XCTAssertNotEqualObjects(newData, oldStoreFileData);
    XCTAssertNotNil(newData);

}

- (void)testThatItCreatesACopyOfTheLocalStoreWhenItIsUnreadable
{
    // given
    [self performIgnoringZMLogError:^{
        XCTAssertTrue([self createdUnredableLocalStore]);
        XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStore]);
    }];
    
    NSString *storeFile = [self.applicationSupportStoreURL.path stringByAppendingString:@""];
    NSData *oldStoreFileData = [NSData dataWithContentsOfFile:storeFile];
    XCTAssertNotNil(storeFile);
    
    // when
    XCTestExpectation *donePreparing = [self expectationWithDescription:@"It is done preparing"];
    
    [self performIgnoringZMLogError:^{
        [NSManagedObjectContext prepareLocalStoreSync:NO backingUpCorruptedDatabase:YES completionHandler:^{
            [donePreparing fulfill];
        }];
        XCTAssertTrue([self waitForCustomExpectationsWithTimeout:1]);
    }];
    
    // then
    NSURL *storeFolder;
    [[NSURL fileURLWithPath:storeFile] getResourceValue:&storeFolder forKey:NSURLParentDirectoryURLKey error:NULL];
    NSURL *parentFolder;
    [storeFolder getResourceValue:&parentFolder forKey:NSURLParentDirectoryURLKey error:NULL];
    
    NSArray *backupFolders = [self currentBackupFoldersInApplicationSupport];
    XCTAssertEqual(backupFolders.count, 1u);
    
    NSURL *firstBackupFolder = [NSURL fileURLWithPath:backupFolders.firstObject];
    NSURL *backedUpStoreFile = [firstBackupFolder URLByAppendingPathComponent:storeFile.lastPathComponent];
    
    NSData *newData = [NSData dataWithContentsOfFile:backedUpStoreFile.path];
    XCTAssertNotNil(newData);
    XCTAssertEqualObjects(newData, oldStoreFileData);
}

- (NSArray<NSString *>*)currentBackupFoldersInApplicationSupport
{
    NSURL *containerFolder = [NSManagedObjectContext storeURLInDirectory:NSApplicationSupportDirectory].URLByDeletingLastPathComponent.URLByDeletingLastPathComponent;
    NSArray *dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:containerFolder.path
                                                                              error:NULL];
    NSMutableArray *backupFolders = [NSMutableArray array];
    for(NSString *file in dirContent) {
        if([file hasPrefix:@"DB-"] && [file hasSuffix:@".bak"]) {
            [backupFolders addObject:[containerFolder URLByAppendingPathComponent:file].path];
        }
    }
    return backupFolders;
}

- (void)testThatItReportsDatabaseExistsInCachesDirectoryAfterMovingIt
{
    // given
    XCTAssertTrue([self moveDatabaseToCachesDirectory]);
    
    // then
    XCTAssertTrue([NSManagedObjectContext databaseExistsInCachesDirectory]);
}

- (void)testThatItReportsDatabaseDoesNotExistsInCachesDirectoryWhenItIsNotThere
{
    XCTAssertFalse([NSManagedObjectContext databaseExistsInCachesDirectory]);
}

- (void)testThatItConstructsTheStoreURLUsingThePassedSearchPathDirectory
{
    XCTAssertTrue([self.cachesDirectoryStoreURL.path containsString:@"Caches"]);
    XCTAssertTrue([self.applicationSupportStoreURL.path containsString:@"Application Support"]);
}

#pragma mark - Helper

- (BOOL)moveDatabaseToCachesDirectory
{
    NSError *error;
    NSURL *cachesStoreURL = [NSManagedObjectContext storeURLInDirectory:NSCachesDirectory];
    NSURL *applicationDirectoryStoreURL = [NSManagedObjectContext storeURLInDirectory:NSApplicationSupportDirectory];
    
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [cachesStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [applicationDirectoryStoreURL.path stringByAppendingString:extension];

        if (! [self.fm createFileAtPath:fromPath contents:nil attributes:nil]) {
            XCTFail();
            return NO;
        }
        if ([self.fm fileExistsAtPath:toPath isDirectory:nil]) {
            [self.fm removeItemAtPath:toPath error:&error];
            XCTAssertNil(error);
            
            if (nil != error) {
                return NO;
            }
        }
    }
    
    NSString *supportPath = [cachesStoreURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@".store_SUPPORT"].path;
    XCTAssertTrue([self.fm createDirectoryAtPath:supportPath withIntermediateDirectories:NO attributes:nil error:&error]);
    XCTAssertNil(error);
    
    return YES;
}

- (NSData *)invalidData
{
    return [@"Trollolol" dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)createdUnredableLocalStore
{
    NSData *data = self.invalidData;
    NSURL *applicationDirectoryStoreURL = [NSManagedObjectContext storeURLInDirectory:NSApplicationSupportDirectory];
    
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *filePath = [applicationDirectoryStoreURL.path stringByAppendingString:extension];
        
        if (! [self.fm createFileAtPath:filePath contents:data attributes:nil]) {
            XCTFail();
            return NO;
        }
    }
    return YES;
}

- (NSArray <NSString *>*)databaseFileExtensions
{
    return @[@"", @"-wal", @"-shm"];
}

@end
