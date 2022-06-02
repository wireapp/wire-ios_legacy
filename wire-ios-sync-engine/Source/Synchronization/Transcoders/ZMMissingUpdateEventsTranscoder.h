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
@import WireRequestStrategy;

@class SyncStatus;
@class OperationStatus;
@class PushNotificationStatus;
@class NotificationsTracker;
@class NSManagedObjectContext;
@protocol ZMApplicationStatus;
@protocol PreviouslyReceivedEventIDsCollection;
@protocol UpdateEventProcessor;

extern NSUInteger const ZMMissingUpdateEventsTranscoderListPageSize;

@interface ZMMissingUpdateEventsTranscoder : ZMAbstractRequestStrategy <ZMObjectStrategy>

@property (nonatomic, readonly) BOOL hasLastUpdateEventID;
@property (nonatomic, readonly) BOOL isDownloadingMissingNotifications;
@property (nonatomic, readonly) NSUUID *lastUpdateEventID;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                        notificationsTracker:(NotificationsTracker *)notificationsTracker
                              eventProcessor:(id<UpdateEventProcessor>)eventProcessor
        previouslyReceivedEventIDsCollection:(id<PreviouslyReceivedEventIDsCollection>)eventIDsCollection
                           applicationStatus:(id<ZMApplicationStatus>)applicationStatus
                      pushNotificationStatus:(PushNotificationStatus *)pushNotificationStatus
                                  syncStatus:(SyncStatus *)syncStatus
                             operationStatus:(OperationStatus *)operationStatus
                  useLegacyPushNotifications:(BOOL)useLegacyPushNotifications;

- (void)startDownloadingMissingNotifications;

@end
