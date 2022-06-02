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


@import WireTransport;

#import <WireRequestStrategy/ZMContextChangeTracker.h>
#import <WireRequestStrategy/ZMOutstandingItems.h>
#import <WireRequestStrategy/ZMRequestGenerator.h>

@class ZMTransportRequest;
@class ZMTransportResponse;
@protocol ZMUpstreamTranscoder;


@interface ZMUpstreamModifiedObjectSync : NSObject <ZMContextChangeTracker, ZMOutstandingItems, ZMRequestGenerator>

- (instancetype)initWithTranscoder:(id<ZMUpstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
              managedObjectContext:(NSManagedObjectContext *)context;


- (instancetype)initWithTranscoder:(id<ZMUpstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
                        keysToSync:(NSArray<NSString *> *)keysToSync
              managedObjectContext:(NSManagedObjectContext *)context;


/// The @c ZMUpstreamTranscoder can use @c keysToSync to limit the keys that are supposed to be synchronized.
/// If not implemented or nil, all keys will be synchronized, otherwise only those in the set.
- (instancetype)initWithTranscoder:(id<ZMUpstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
                   updatePredicate:(NSPredicate *)updatePredicate
                            filter:(NSPredicate *)filter
                        keysToSync:(NSArray<NSString *> *)keysToSync
              managedObjectContext:(NSManagedObjectContext *)context;

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion;

@end

