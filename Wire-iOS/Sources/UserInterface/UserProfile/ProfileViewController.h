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
@import WireExtensionComponents;
#import "ViewControllerDismissable.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZMSearchableUser;
@class ZMConversation;
@class ZMUser;
@class ProfileViewController;
@class ProfileNavigationControllerDelegate;



typedef NS_ENUM(NSInteger, ProfileViewControllerContext) {
    ProfileViewControllerContextSearch,
    ProfileViewControllerContextGroupConversation,
    ProfileViewControllerContextOneToOneConversation,
    ProfileViewControllerContextCommonConnection,
    ProfileViewControllerContextDeviceList
};

@protocol ProfileViewControllerDelegate <NSObject>

@optional

- (NSString *)suggestedBackButtonTitleForProfileViewController:(nullable ProfileViewController *)controller;

- (void)profileViewController:(nullable ProfileViewController *)controller wantsToNavigateToConversation:(ZMConversation *)conversation;
- (void)profileViewController:(nullable ProfileViewController *)controller wantsToAddUsers:(NSSet *)users toConversation:(ZMConversation *)conversation;
- (void)profileViewController:(nullable ProfileViewController *)controller wantsToCreateConversationWithName:(nullable NSString *)name users:(nonnull NSSet <ZMUser *>*)users;

@end



@interface ProfileViewController : UIViewController

- (instancetype)initWithUser:(id<ZMSearchableUser, AccentColorProvider>)user context:(ProfileViewControllerContext)context;
- (instancetype)initWithUser:(id<ZMSearchableUser, AccentColorProvider>)user conversation:(nullable ZMConversation *)conversation;
- (instancetype)initWithUser:(id<ZMSearchableUser, AccentColorProvider>)user conversation:(nullable ZMConversation *)conversation context:(ProfileViewControllerContext)context;

@property (nonatomic, readonly) id<ZMSearchableUser, AccentColorProvider> bareUser;
@property (nonatomic, weak, nullable) id<ProfileViewControllerDelegate> delegate;
@property (nonatomic, weak, nullable) id<ViewControllerDismissable> viewControllerDismissable;
@property (nonatomic, nullable) ProfileNavigationControllerDelegate *navigationControllerDelegate;

@end

NS_ASSUME_NONNULL_END
