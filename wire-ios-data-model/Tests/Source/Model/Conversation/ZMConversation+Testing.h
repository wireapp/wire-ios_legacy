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

@import WireDataModel;

@class MockConversation;
@class ZMTFailureRecorder;

@interface ZMConversation (Testing)

/// Creates enough unread messages to make the unread count match the required count
- (void)setUnreadCount:(NSUInteger)count;

/// Adds a system message for a missed call and make it unread by setting the timestamp past the last read
- (void)addUnreadMissedCall;

/// Adds an unread unsent message in the conversation
- (void)setHasExpiredMessage:(BOOL)hasUnreadUnsentMessage;


@end

