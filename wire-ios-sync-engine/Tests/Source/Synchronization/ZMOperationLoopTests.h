//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
@import WireCryptobox;
@import WireDataModel;
@import avs;

#import <WireSyncEngine/WireSyncEngine-Swift.h>

@class MockRequestStrategy;
@class MockUpdateEventProcessor;
@class MockRequestCancellation;

@interface ZMOperationLoopTests : MessagingTest

@property (nonatomic) ZMOperationLoop *sut;
@property (nonatomic) ZMPersistentCookieStorage *cookieStorage;
@property (nonatomic) MockPushChannel* mockPushChannel;
@property (nonatomic) RecordingMockTransportSession *mockTransportSesssion;
@property (nonatomic) ApplicationStatusDirectory *applicationStatusDirectory;
@property (nonatomic) PushNotificationStatus *pushNotificationStatus;
@property (nonatomic) CallEventStatus *callEventStatus;
@property (nonatomic) SyncStatus *syncStatus;
@property (nonatomic) MockSyncStateDelegate *mockSyncDelegate;
@property (nonatomic) MockRequestStrategy *mockRequestStrategy;
@property (nonatomic) MockUpdateEventProcessor *mockUpdateEventProcessor;
@property (nonatomic) MockRequestCancellation *mockRequestCancellation;
@property (nonatomic) NSMutableArray *pushChannelNotifications;
@property (nonatomic) id pushChannelObserverToken;

@end
