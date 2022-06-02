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
@import WireSystem;
@import WireTransport;


@class ZMManagedObject;
@class ZMSyncToken;


@interface ZMSyncOperationSet : NSObject

@property (nonatomic, copy) NSArray *sortDescriptors;
@property (nonatomic, readonly) NSUInteger count;

- (void)addObjectToBeSynchronized:(ZMManagedObject *)mo;

- (ZMManagedObject *)nextObjectToSynchronize;

/// This will internally capture the current state of the values for those given keys in order to check if they're still the same once -keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:forObject:success: gets called.
- (ZMSyncToken *)didStartSynchronizingKeys:(NSSet *)keys forObject:(ZMManagedObject *)mo;

/// Returns the keys for which resulting changes should be applied to the model.
/// If the model has had additional changes to any of the keys for which the sync was being performed, there will not be included in the set.
- (NSSet *)keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:(ZMSyncToken *)token forObject:(ZMManagedObject *)mo result:(ZMTransportResponseStatus)status;

- (void)removeUpdatedObject:(ZMManagedObject *)mo syncToken:(ZMSyncToken *)token synchronizedKeys:(NSSet *)synchronizedKeys;

/// Removes an object from the set
- (void)removeObject:(ZMManagedObject *)mo;


@end



@interface ZMSyncOperationSet (PartialUpdates)

/// This corresponds to @c -nextObjectToSynchronize but will additionally return by reference the remaining keys for the object that still need to be synchronized.
/// If @c -setRemainingKeys:forObject: was never called for the returned object, the @c remainingKeys will be @c nil.
- (ZMManagedObject *)nextObjectToSynchronizeWithRemainingKeys:(NSSet **)remainingKeys notInOperationSet:(ZMSyncOperationSet *)operationSet ZM_NON_NULL(1) ;

/// After calling -didStartSynchronizingKeys:forObject: this method can be called to add the managed object to the list of partial objects.
/// The object will then be returned by -nextObjectToSynchronizeWithRemainingKeys: until this method is called with the same object with an empty set of keys (or @c nil) or @c -deleteObject: has been called.
- (void)setRemainingKeys:(NSSet *)keys forObject:(ZMManagedObject *)mo;

@end
