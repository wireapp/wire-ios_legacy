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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


@import Foundation;
@import CoreData;

@class ZMTransportRequest;
@class ZMTransportResponse;
@class ZMSingleRequestSync;

@protocol ZMSingleRequestTranscoder <NSObject>

- (ZMTransportRequest *)requestForSingleRequestSync:(ZMSingleRequestSync *)sync;
- (void)didReceiveResponse:(ZMTransportResponse *)response forSingleRequest:(ZMSingleRequestSync *)sync;

@end

typedef NS_ENUM(int, ZMSingleRequestProgress) {
    ZMSingleRequestIdle = 0,
    ZMSingleRequestInProgress,
    ZMSingleRequestCompleted
};


@interface ZMSingleRequestSync : NSObject

@property (nonatomic, readonly, weak) id<ZMSingleRequestTranscoder> transcoder;
@property (nonatomic, readonly) ZMSingleRequestProgress status;
@property (nonatomic, readonly) NSManagedObjectContext *moc;

- (instancetype)initWithSingleRequestTranscoder:(id<ZMSingleRequestTranscoder>)transcoder managedObjectContext:(NSManagedObjectContext *)moc;

+ (instancetype)syncWithSingleRequestTranscoder:(id<ZMSingleRequestTranscoder>)transcoder managedObjectContext:(NSManagedObjectContext *)moc;

/// Marks as need to request, even if it's already performing a request (will abort that request)
- (void)readyForNextRequest;
/// Marks as need request, only if it's not requesting already
- (void)readyForNextRequestIfNotBusy;

/// mark the completion as "noted" by the client, and goes back to the idle state
- (void)resetCompletionState;

- (ZMTransportRequest *)nextRequest;

@end
