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


#import <UIKit/UIKit.h>
#import "ProfileViewController.h"

@class ZMConversation;
@class ZClientViewController;
@class ParticipantsViewController;

@protocol ParticipantsViewControllerDelegate <NSObject>
@optional
- (void)participantsViewControllerWantsToBeDismissed:(ParticipantsViewController *)viewController;
- (void)participantsViewController:(ParticipantsViewController *)controller wantsToAddUsers:(NSSet *)users toConversation:(ZMConversation *)conversation;

@end

/// The view controller which shows details about the given @c ZMConversation and their participants
/// @see ProfileViewController
@interface ParticipantsViewController : UIViewController <ProfileViewControllerDelegate, ViewControllerDismissable>

@property (nonatomic, weak) id<ParticipantsViewControllerDelegate> delegate;
@property (nonatomic, strong) ZMConversation *conversation;
@property (nonatomic, weak) ZClientViewController *zClientViewController;

- (instancetype)initWithConversation:(ZMConversation *)conversation;

@end
