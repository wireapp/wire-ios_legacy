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
@import WireTransport;
@import WireDataModel;
@import WireRequestStrategy;

#import "ZMHotFix.h"
#import "ZMHotFixDirectory.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

static NSString* ZMLogTag ZM_UNUSED = @"HotFix";
static NSString * const LastSavedVersionKey = @"lastSavedVersion";
NSString * const ZMSkipHotfix = @"ZMSkipHotfix";

@interface ZMHotFix ()
@property (nonatomic) ZMHotFixDirectory *hotFixDirectory;
@property (nonatomic) NSManagedObjectContext *syncMOC;
@end


@implementation ZMHotFix


- (instancetype)initWithSyncMOC:(NSManagedObjectContext *)syncMOC
{
    return [self initWithHotFixDirectory:nil syncMOC:syncMOC];
}

- (instancetype)initWithHotFixDirectory:(ZMHotFixDirectory *)hotFixDirectory syncMOC:(NSManagedObjectContext *)syncMOC
{
    self = [super init];
    if (self != nil) {
        self.syncMOC = syncMOC;
        self.hotFixDirectory = hotFixDirectory ?: [[ZMHotFixDirectory alloc] init];
    }
    return self;
}

- (void)applyPatches
{
    if ([[self.syncMOC persistentStoreMetadataForKey:ZMSkipHotfix] boolValue]) {
        ZMLogDebug(@"Skipping applying HotFix");
        return;
    }
    
    NSString * currentVersionString = [[[NSBundle bundleForClass:ZMUserSession.class] infoDictionary] objectForKey:@"FrameworkVersion"];
    [self applyPatchesForCurrentVersion:currentVersionString];
}

- (void)applyPatchesForCurrentVersion:(NSString *)currentVersionString;
{
    if (currentVersionString.length == 0) {
        ZMLogDebug(@"Invalid version string, skipping HotFix");
        return;
    }

    ZMVersion *lastSavedVersion = [self lastSavedVersion];
    ZMVersion *currentVersion = [[ZMVersion alloc] initWithVersionString:currentVersionString];
    
    if (lastSavedVersion == nil) {
        ZMLogDebug(@"No saved last version. We assume it's a new database and don't apply any HotFix.");
        [self.syncMOC performGroupedBlock:^{
            [self saveNewVersion:currentVersionString];
            [self.syncMOC saveOrRollback];
        }];
        return;
    }
    
    if ([currentVersion compareWithVersion:lastSavedVersion] == NSOrderedSame) {
        ZMLogDebug(@"Current version equal to last saved version (%@). Not applying any HotFix.", lastSavedVersion.versionString);
        return;
    }
    
    ZMLogDebug(@"Applying HotFix with last saved version %@, current version %@.", lastSavedVersion.versionString, currentVersion.versionString);
    [self.syncMOC performGroupedBlock:^{
        [self applyFixesSinceVersion:lastSavedVersion];///TODO: exception here
        [self saveNewVersion:currentVersionString];
        [self.syncMOC saveOrRollback];
        [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    }];
}

- (ZMVersion *)lastSavedVersion
{
    NSString *versionString = [self.syncMOC persistentStoreMetadataForKey:LastSavedVersionKey];
    if (nil == versionString) {
        return nil;
    }
    return [[ZMVersion alloc] initWithVersionString:versionString];
}

- (void)saveNewVersion:(NSString *)version
{
    [self.syncMOC setPersistentStoreMetadata:version forKey:LastSavedVersionKey];
    ZMLogDebug(@"Saved new HotFix version %@", version);
}

- (void)applyFixesSinceVersion:(ZMVersion *)lastSavedVersion
{
    for(ZMHotFixPatch *patch in self.hotFixDirectory.patches) {
        ZMVersion *version = [[ZMVersion alloc] initWithVersionString:patch.version];
        if ((lastSavedVersion == nil || [version compareWithVersion:lastSavedVersion] == NSOrderedDescending)
            && patch.code)
        {
            patch.code(self.syncMOC);
        }
    }
}

@end
