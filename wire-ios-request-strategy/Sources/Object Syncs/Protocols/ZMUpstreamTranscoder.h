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


@class ZMUpstreamRequest;
@class ZMManagedObject;

@protocol ZMUpstreamTranscoder <NSObject>

- (BOOL)shouldProcessUpdatesBeforeInserts;

- (ZMUpstreamRequest  * _Nullable )requestForUpdatingObject:(ZMManagedObject  * _Nonnull )managedObject forKeys:(NSSet<NSString *>  * _Nonnull )keys apiVersion:(APIVersion)apiVersion;
- (ZMUpstreamRequest  * _Nullable )requestForInsertingObject:(ZMManagedObject  * _Nonnull )managedObject forKeys:(NSSet<NSString *>  * _Nullable )keys apiVersion:(APIVersion)apiVersion;

- (void)updateInsertedObject:(ZMManagedObject * _Nonnull)managedObject request:(ZMUpstreamRequest * _Nonnull)upstreamRequest response:(ZMTransportResponse * _Nonnull)response;

/// Returns whether synchronization of this object needs additional requests
- (BOOL)updateUpdatedObject:(ZMManagedObject * _Nonnull)managedObject
            requestUserInfo:(NSDictionary * _Nullable)requestUserInfo
                   response:(ZMTransportResponse * _Nonnull)response
                keysToParse:(NSSet<NSString *> * _Nonnull)keysToParse;

// Should return the objects that need to be refetched from the BE in case of upload error
- (ZMManagedObject * _Nullable)objectToRefetchForFailedUpdateOfObject:(ZMManagedObject * _Nonnull)managedObject;

@optional

/// If implemented, the upstream object sync will call this before inserting any objects into either
/// its inserted or updated objects collection. If the transcoder returns no dependency (e.g. @c nil),
/// the object (@c dependant) will get inserted.
///
/// If a dependency gets returned, the dependant is put on hold until the returned dependency is updated
/// at which time the upstream object sync will ask the transcoder again.
///
/// Dependant -> depends on -> dependency
- (id _Nullable)dependentObjectNeedingUpdateBeforeProcessingObject:(ZMManagedObject * _Nonnull)dependant;

/// If implemented, the upstream object sync will call this when an upstream request timed out. Having a request
/// that might time out but not implementing this will trigger an assertion.
- (void)requestExpiredForObject:(ZMManagedObject * _Nonnull)managedObject forKeys:(NSSet<NSString *> * _Nonnull)keys;

/// If implemented, the transcoder can refuse requests until a conditions is fullfilled
/// Object will be not removed from objects to be synced
- (BOOL)shouldCreateRequestToSyncObject:(ZMManagedObject * _Nonnull)managedObject forKeys:(NSSet<NSString *>  * _Nonnull )keys withSync:(id _Nonnull)sync;

/// If this method is not implemented, inserted sync will delete object.
/// If this method reutrns TRUE the object will be added back to sync queue.
/// If it returns FALSE, it will be deleted (if it's an insertion) or the keys will be reset (if it's an update)
- (BOOL)shouldRetryToSyncAfterFailedToUpdateObject:(ZMManagedObject * _Nonnull)managedObject
                                           request:(ZMUpstreamRequest * _Nonnull)upstreamRequest
                                          response:(ZMTransportResponse * _Nonnull)response
                                       keysToParse:(NSSet<NSString *> * _Nonnull)keys;

@end

/// Asserts with a description of how it failed to generate a request from a transcoder
void ZMTrapUnableToGenerateRequest(NSSet<NSString *> * _Nonnull keys, id _Nonnull transcoder);
