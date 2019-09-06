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


#import "ZMConversation+Additions.h"

#import "WireSyncEngine+iOS.h"
#import "ZMUserSession+iOS.h"
#import <AVFoundation/AVFoundation.h>
#import "Analytics.h"
#import "Analytics.h"
#import "UIAlertController+Wire.h"
#import "AppDelegate.h"
#import "ZClientViewController.h"
#import "UIApplication+Permissions.h"
#import "Wire-Swift.h"
#import "Settings.h"

#import "Wire-Swift.h"

@implementation ZMConversation (Additions)

- (ZMConversation *)addParticipantsOrCreateConversation:(NSSet *)participants
{
    if (! participants || participants.count == 0) {
        return self;
    }

    if (self.conversationType == ZMConversationTypeGroup) {
        [self addParticipantsOrShowError:participants];
        return self;
    }
    else if (self.conversationType == ZMConversationTypeOneOnOne &&
               (participants.count > 1 || (participants.count == 1 && ! [self.connectedUser isEqual:participants.anyObject]))) {

        Team *team = ZMUser.selfUser.team;

        NSMutableArray *listOfPeople = [participants.allObjects mutableCopy];
        [listOfPeople addObject:self.connectedUser];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoUserSession:[ZMUserSession sharedSession]
                                                                             withParticipants:listOfPeople
                                                                                       inTeam:team];

        return conversation;
    }

    return self;
}

- (ZMUser *)firstActiveParticipantOtherThanSelf
{
    ZMUser *selfUser = [ZMUser selfUser];
    for (ZMUser *user in self.activeParticipants) {
        if ( ! [user isEqual:selfUser]) {
            return user;
        }
    }
    return nil;
}

@end
