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



#import "ZMOperationLoop.h"

@class APSSignalingKeysStore;
@class ZMSyncStrategy;
@class PushNotificationStatus;
@class ZMSyncStrategy;
@class CallEventStatus;
@class SyncStatus;

@protocol RequestStrategy;
@protocol UpdateEventProcessor;

// Required by OperationLoop+Background.h
@interface ZMOperationLoop ()

@property (nonatomic) APSSignalingKeysStore *apsSignalKeyStore;
@property (nonatomic) id<RequestStrategy> requestStrategy;
@property (nonatomic) id<UpdateEventProcessor> updateEventProcessor;
@property (nonatomic, weak) NSManagedObjectContext *syncMOC;
@property (nonatomic, readonly) PushNotificationStatus *pushNotificationStatus;
@property (nonatomic, readonly) CallEventStatus *callEventStatus;
@property (nonatomic, readonly) SyncStatus *syncStatus;
@end
