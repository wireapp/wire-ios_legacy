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


#import "ZMSnapshotTestCase.h"
#import "ZMSnapshotTestCase+Internal.h"
#import <WireSyncEngine/WireSyncEngine.h>
#import "UIColor+WAZExtensions.h"
#import "ColorScheme.h"
#import "Wire-Swift.h"



@interface ZMSnapshotTestCase ()
@property (nonatomic) NSURL *documentsDirectory;
@end


@implementation ZMSnapshotTestCase

- (BOOL)needsCaches
{
    return NO;
}

- (void)setUp
{
    [super setUp];
    XCTAssertEqual(UIScreen.mainScreen.scale, 2, @"Snapshot tests need to be run on a device with a 2x scale");

    if ([UIDevice.currentDevice.systemVersion compare:@"10" options:NSNumericSearch] == NSOrderedAscending) {
        XCTFail(@"Snapshot tests need to be run on a device running at least iOS 10");
    }

    [AppRootViewController configureAppearance];
    [UIView setAnimationsEnabled:NO];
    self.accentColor = ZMAccentColorVividRed;
    self.snapshotBackgroundColor = UIColor.clearColor;
    
    // Enable when the design of the view has changed in order to update the reference snapshots
#ifdef RECORDING_SNAPSHOTS
    self.recordMode = YES;
#endif
    
    self.usesDrawViewHierarchyInRect = YES;

    XCTestExpectation *contextExpectation = [self expectationWithDescription:@"It should create a context"];

    [StorageStack reset];
    StorageStack.shared.createStorageAsInMemory = YES;
    NSError *error = nil;
    self.documentsDirectory = [NSFileManager.defaultManager URLForDirectory:NSDocumentDirectory
                                                                   inDomain:NSUserDomainMask
                                                          appropriateForURL:nil
                                                                     create:YES
                                                                      error:&error];

    XCTAssertNil(error, @"Unexpected error %@", error);

    [StorageStack.shared createManagedObjectContextDirectoryForAccountIdentifier:NSUUID.UUID
                                                            applicationContainer:self.documentsDirectory
                                                                   dispatchGroup:nil
                                                        startedMigrationCallback:nil
                                                               completionHandler:^(ManagedObjectContextDirectory * _Nonnull contextDirectory) {
                                                                   self.uiMOC = contextDirectory.uiContext;
                                                                   [contextExpectation fulfill];
                                                               }];

    [self waitForExpectations:@[contextExpectation] timeout:0.1];
    
    if (self.needsCaches) {
        [self setUpCaches];
    }
}

- (void)tearDown
{
    if (self.needsCaches) {
        [self wipeCaches];
    }
    
    // Needs to be called before setting self.documentsDirectory to nil.
    [self removeContentsOfDocumentsDirectory];

    self.uiMOC = (id _Nonnull)nil;
    self.documentsDirectory = nil;
    self.snapshotBackgroundColor = nil;

    [UIColor setAccentOverrideColor:ZMAccentColorUndefined];
    [UIView setAnimationsEnabled:YES];

    [super tearDown];
}

- (void)setUpCaches
{
    self.uiMOC.zm_userImageCache = [[UserImageLocalCache alloc] initWithLocation:nil];
    self.uiMOC.zm_fileAssetCache = [[FileAssetCache alloc] initWithLocation:nil];
}

- (void)wipeCaches
{
    [self.uiMOC.zm_fileAssetCache wipeCaches];
    [self.uiMOC.zm_userImageCache wipeCache];
    
    [PersonName.stringsToPersonNames removeAllObjects];
}

- (void)removeContentsOfDocumentsDirectory
{
    NSError *error = nil;
    NSArray<NSURL *> *contents = [NSFileManager.defaultManager contentsOfDirectoryAtURL:self.documentsDirectory
                                                             includingPropertiesForKeys:nil
                                                                                options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                  error:&error];

    XCTAssertNil(error, @"Unexpected error %@", error);

    for (NSURL *content in contents) {
        error = nil;
        [NSFileManager.defaultManager removeItemAtURL:content error:&error];
        XCTAssertNil(error, @"Unexpected error %@", error);
    }
}

- (void)setAccentColor:(ZMAccentColor)accentColor
{
     [UIColor setAccentOverrideColor:accentColor];
}

- (void)assertAmbigousLayout:(UIView *)view file:(const char[])file line:(NSUInteger)line
{
    if (view.hasAmbiguousLayout) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        NSString *description = [NSString stringWithFormat:@"Ambigous layout in view: %@ trace: \n%@", view, [view performSelector:@selector(_autolayoutTrace)]];
#pragma clang diagnostic pop
        NSString *filePath = [NSString stringWithFormat:@"%s", file];
        [self recordFailureWithDescription:description inFile:filePath atLine:line expected:YES];
    }
}

- (BOOL)assertEmptyFrame:(UIView *)view file:(const char[])file line:(NSUInteger)line
{
    if (CGRectIsEmpty(view.frame)) {
        NSString *description = @"View frame can not be empty";
        NSString *filePath = [NSString stringWithFormat:@"%s", file];
        [self recordFailureWithDescription:description inFile:filePath atLine:line expected:YES];
        return YES;
    }
    
    return NO;
}

@end
