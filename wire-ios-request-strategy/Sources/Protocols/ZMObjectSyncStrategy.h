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
@import WireDataModel;
@import WireSystem;

#import "ZMRequestGenerator.h"
#import "ZMContextChangeTracker.h"

@class ZMTransportRequest;
@class ZMSyncStrategy;
@class ZMUpdateEvent;
@class NSManagedObjectContext;
@protocol ZMTransportData;
@class ZMConversation;

NS_ASSUME_NONNULL_BEGIN



@protocol ZMEventConsumer <NSObject>

/// Process events received either through a live update (websocket / notification / notification stream)
/// or through history download
/// @param liveEvents true if the events were received through websocket / notifications / notification stream,
///    false if received from history download
/// @param prefetchResult prefetched conversations and messages that the events belong to, indexed by remote identifier and nonce
- (void)processEvents:(NSArray<ZMUpdateEvent *> *)events
           liveEvents:(BOOL)liveEvents
       prefetchResult:(ZMFetchRequestBatchResult * _Nullable)prefetchResult;

@optional

- (void)processEventsWhileInBackground:(NSArray<ZMUpdateEvent *> *)events NS_SWIFT_NAME(processEventsWhileInBackground(_:));

/// If conforming to these mothods the object strategy will be asked to extract relevant messages (by nonce)
/// and conversations from the events array. All messages and conversations will be prefetched and
/// passed to @c processEvents:liveEvents:prefetchResult as last parameter

/// The method to register message nonces for prefetching
- (NSSet <NSUUID *>*)messageNoncesToPrefetchToProcessEvents:(NSArray<ZMUpdateEvent *> *)events;

/// The method to register conversation remoteIdentifiers for prefetching
- (NSSet <NSUUID *>*)conversationRemoteIdentifiersToPrefetchToProcessEvents:(NSArray<ZMUpdateEvent *> *)events;

@end


@protocol ZMObjectStrategy <NSObject, ZMEventConsumer, ZMRequestGeneratorSource, ZMContextChangeTrackerSource>
@end


@interface ZMObjectSyncStrategy : NSObject <TearDownCapable>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, weak) NSManagedObjectContext *managedObjectContext;

- (void)tearDown ZM_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
