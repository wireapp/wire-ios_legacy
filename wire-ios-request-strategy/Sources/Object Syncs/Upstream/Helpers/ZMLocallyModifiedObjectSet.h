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


@import Foundation;

#import <WireRequestStrategy/ZMOutstandingItems.h>

@class ZMManagedObject;
@class ZMLocallyModifiedObjectSyncStatus;

NS_ASSUME_NONNULL_BEGIN

@interface ZMObjectWithKeys : NSObject

@property (nonatomic, readonly,) ZMManagedObject *object;
@property (nonatomic, readonly,) NSSet *keysToSync;

@end


@class ZMModifiedObjectSyncToken;


@interface ZMLocallyModifiedObjectSet : NSObject <ZMOutstandingItems>

@property (nonatomic, readonly, nullable) NSSet *trackedKeys;

// Init with all keys tracked
- (instancetype)init;
// Init with only some keys tracked
- (instancetype)initWithTrackedKeys:(NSSet *)keys;

// This will check internally if the object really needs to be synced i.e. the locally modified keys are the one we are interested in
- (void)addPossibleObjectToSynchronize:(ZMManagedObject *)object;

// return any of the object that is not currently being synced
- (ZMObjectWithKeys * __nullable)anyObjectToSynchronize;

// Mark the object as started to sync and return a token that should be passed in all the completion callbacks (didFailToSynchronize, ...)
- (ZMModifiedObjectSyncToken *)didStartSynchronizingKeys:(NSSet *)keys forObject:(ZMObjectWithKeys *)object;

// Called when sync failed
- (void)didFailToSynchronizeToken:(ZMModifiedObjectSyncToken *)token;

// Returns list of keys that should be parsed by the transcoder
- (NSSet *)keysToParseAfterSyncingToken:(ZMModifiedObjectSyncToken *)token;

// Called when it is done syncing the keys in the token
- (void)didSynchronizeToken:(ZMModifiedObjectSyncToken *)token;

// Called when it still needs to generate more requests to sync this object
- (void)didNotFinishToSynchronizeToken:(ZMModifiedObjectSyncToken *)token;

@end

NS_ASSUME_NONNULL_END
