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


#import <WireSyncEngine/WireSyncEngine.h>
#import "AccentColorProvider.h"

@class ZMConversation;
@class ZMUser;
@class ZMSearchUser;



FOUNDATION_EXPORT ZMUser *BareUserToUser(id bareUser);

@interface ZMUser (Additions)

@property (nonatomic, readonly) UIColor *nameAccentColor;

/// Returns the current self user
+ (instancetype)selfUser;

+ (ZMUser<ZMEditableUser> *)editableSelfUser;

+ (BOOL)isSelfUserActiveParticipantOfConversation:(ZMConversation *)conversation;

/// Just checks if any approval is pending from any side (SelfUser or OtherUser)
- (BOOL)isPendingApproval;

/// Blocks user if not already blocked and vice versa.
- (void)toggleBlocked;

/// Randomly select the accent color that can be used for a new user
+ (ZMAccentColor)pickRandomAcceptableAccentColor;
+ (ZMAccentColor)pickRandomAccentColor;
@end
