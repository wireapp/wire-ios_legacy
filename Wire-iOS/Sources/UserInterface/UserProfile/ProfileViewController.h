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


NS_ASSUME_NONNULL_BEGIN

@protocol UserType;
@protocol ViewControllerDismisser;

@class ZMConversation;
@class ZMUser;
@class ProfileViewController;

typedef NS_ENUM(NSInteger, ProfileViewControllerTabBarIndex) {
    ProfileViewControllerTabBarIndexDetails = 0,
    ProfileViewControllerTabBarIndexDevices
};

typedef NS_ENUM(NSInteger, ProfileViewControllerContext) {
    ProfileViewControllerContextSearch,
    ProfileViewControllerContextGroupConversation,
    ProfileViewControllerContextOneToOneConversation,
    ProfileViewControllerContextDeviceList,
    /// when opening from a URL scheme, not linked to a specific conversation
    ProfileViewControllerContextProfileViewer
};

@protocol ProfileViewControllerDelegate <NSObject>

@optional

- (NSString *)suggestedBackButtonTitleForProfileViewController:(nullable ProfileViewController *)controller;

- (void)profileViewController:(nullable ProfileViewController *)controller wantsToNavigateToConversation:(ZMConversation *)conversation;
- (void)profileViewController:(nullable ProfileViewController *)controller wantsToCreateConversationWithName:(nullable NSString *)name users:(nonnull NSSet <ZMUser *>*)users;

@end

@interface ProfileViewController : UIViewController

- (instancetype)initWithUser:(id<UserType>)user viewer:(id<UserType>)viewer context:(ProfileViewControllerContext)context;
- (instancetype)initWithUser:(id<UserType>)user viewer:(id<UserType>)viewer conversation:(nullable ZMConversation *)conversation;
- (instancetype)initWithUser:(id<UserType>)user viewer:(id<UserType>)viewer conversation:(nullable ZMConversation *)conversation context:(ProfileViewControllerContext)context;

@property (nonatomic, readonly) id<UserType> bareUser;
@property (nonatomic, readonly) id<UserType> viewer;
@property (nonatomic, weak, nullable) id<ProfileViewControllerDelegate> delegate;
@property (nonatomic, weak, nullable) id<ViewControllerDismisser> viewControllerDismisser;
@property (nonatomic, nullable) id<UINavigationControllerDelegate> navigationControllerDelegate;

- (void)openOneToOneConversation;
- (void)bringUpCancelConnectionRequestSheetFromView:(UIView *)targetView;
- (void)bringUpConversationCreationFlow;

@end

NS_ASSUME_NONNULL_END
