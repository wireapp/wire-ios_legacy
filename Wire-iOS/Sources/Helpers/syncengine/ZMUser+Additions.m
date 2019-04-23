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


#import "ZMUser+Additions.h"
#import "WireSyncEngine+iOS.h"
#import "UIColor+WAZExtensions.h"
#import "Analytics.h"
#import "ColorScheme.h"
#import "Wire-Swift.h"

@implementation ZMUser (Additions)

- (void)toggleBlocked
{
    if (self.isBlocked) {
        [self accept];
    } else {
        [self block];
    }
}

- (UIColor *)nameAccentColor
{
    return [UIColor nameColorForZMAccentColor:self.accentColorValue variant:[[ColorScheme defaultColorScheme] variant]];
}

+ (BOOL)isSelfUserActiveParticipantOfConversation:(ZMConversation *)conversation
{
    ZMUser *selfUser = [self selfUser];
    return [conversation.activeParticipants containsObject:selfUser];
}

- (BOOL)isPendingApproval
{
    return (self.isPendingApprovalBySelfUser || self.isPendingApprovalByOtherUser);
}

@end
