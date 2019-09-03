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


#import "ConversationListViewController.h"
#import "ConversationListViewController+Internal.h"

#import "ZClientViewController.h"
#import "ZClientViewController+Internal.h"

#import "Constants.h"
#import "PermissionDeniedViewController.h"

#import "WireSyncEngine+iOS.h"

#import "ConversationListContentController.h"
#import "StartUIViewController.h"
#import "KeyboardAvoidingViewController.h"

// helpers

#import "Analytics.h"
#import "NSAttributedString+Wire.h"

// Transitions
#import "AppDelegate.h"
#import "Wire-Swift.h"

@implementation ConversationListViewController

- (void)dealloc
{
    [self removeUserProfileObserver];
}

- (void)setSelectedConversation:(ZMConversation *)conversation
{
    _selectedConversation = conversation;
}


- (void)setStateValue: (ConversationListState)newState
{
    _state = newState;
}
@end
