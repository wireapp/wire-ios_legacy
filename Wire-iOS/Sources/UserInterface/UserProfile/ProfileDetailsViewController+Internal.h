//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

@class ConversationActionController;
@protocol ActionController;

@class UserImageView;
@class GuestLabelIndicator;
@class AvailabilityTitleView;
@class CustomSpacingStackView;

@interface ProfileDetailsViewController ()

@property (nonatomic) UILabel *remainingTimeLabel;
@property (nonatomic) id<ActionController> actionsController;
@property (nonatomic) ZMConversation *conversation;
@property (nonatomic) UIView *footerView;
@property (nonatomic) UILabel *readReceiptsEnabledLabel;
@property (nonatomic) ProfileViewControllerContext context;
@property (nonatomic) UserImageView *userImageView;
@property (nonatomic) UIView *stackViewContainer;
@property (nonatomic) GuestLabelIndicator *teamsGuestIndicator;
@property (nonatomic) BOOL showGuestLabel;
@property (nonatomic) AvailabilityTitleView *availabilityView;
@property (nonatomic) CustomSpacingStackView *stackView;

- (ZMUser *)fullUser;
- (void)performRightButtonAction:(id)sender;

- (void)createUserImageView;
- (void)createFooter;
- (void)createGuestIndicator;

- (void)presentAddParticipantsViewController;
- (void)unblockUser;
- (void)openOneToOneConversation;
- (void)bringUpConnectionRequestSheet;
- (void)sendConnectionRequest;
- (void)bringUpCancelConnectionRequestSheet;

@end

typedef NS_ENUM(NSUInteger, ProfileUserAction) {
    ProfileUserActionNone,
    ProfileUserActionOpenConversation,
    ProfileUserActionAddPeople,
    ProfileUserActionRemovePeople,
    ProfileUserActionBlock,
    ProfileUserActionPresentMenu,
    ProfileUserActionUnblock,
    ProfileUserActionAcceptConnectionRequest,
    ProfileUserActionSendConnectionRequest,
    ProfileUserActionCancelConnectionRequest
};
