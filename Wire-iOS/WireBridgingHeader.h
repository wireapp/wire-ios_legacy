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



// Data model
@import WireSyncEngine;
@import avs;
#import "ZMUserSession+iOS.h"
#import <CommonCrypto/CommonCrypto.h>
#import "Settings.h"
#import "AppDelegate.h"
#import "Message+Private.h"

// UI
@import WireExtensionComponents;
#import "UIColor+WAZExtensions.h"
#import "ConversationCell.h"
#import "TextMessageCell.h"
#import "TextMessageCell+Internal.h"
#import "ImageMessageCell.h"
#import "ImageMessageCell+Internal.h"
#import "WireStyleKit.h"
#import <Classy/UIViewController+CASAdditions.h>
#import "UIViewController+Errors.h"
#import "ConversationViewController.h"
#import "ConversationViewController+Private.h"
#import "ConversationListCell.h"
#import "ConversationListItemView.h"
#import "GapLoadingBar.h"
#import "WAZUIMagicIOS.h"
#import "ResizingTextView.h"
#import "NextResponderTextView.h"
#import "RegistrationTextField.h"
#import "InvisibleInputAccessoryView.h"
#import <SCSiriWaveformView/SCSiriWaveformView.h>
#import "ConversationInputBarSendController.h"
#import "ConversationContentViewController+Private.h"
#import "StackView.h"
#import "SearchResultCell.h"
#import "UIAlertController+NewSelfClients.h"
#import "SwizzleTransition.h"
#import "ARCollectionViewMasonryLayout.h"
#import "ZiphyClient+Convenience.h"
#import "ConversationDetailsTransitioningDelegate.h"
#import "ActionSheetController.h"
#import "ActionSheetController+Conversation.h"
#import "Country.h"
#import "UserImageView+Magic.h"
#import "CameraPreviewView.h"
#import "VoiceChannelCollectionViewLayout.h"
#import "ContrastUserImageView.h"
#import "PassthroughTouchesView.h"

// View Controllers
#import "ZClientViewController.h"
#import "ZClientViewController+Internal.h"
#import "RegistrationViewController.h"
#import "FormFlowViewController.h"
#import "RegistrationStepViewController.h"
#import "SignInViewController.h"
#import "NavigationController.h"
#import "ConversationInputBarViewController.h"
#import "ConversationInputBarViewController+Files.h"
#import "ConversationInputBarViewController+Private.h"
#import "ConversationListContentController.h"
#import "ConversationListViewModel.h"
#import "ConversationListViewModel+Private.h"
#import "NotificationWindowRootViewController.h"
#import "SplitViewController.h"
#import "ConfirmAssetViewController.h"
#import "ProfileSelfPictureViewController.h"
#import "AddEmailPasswordViewController.h"
#import "AddPhoneNumberViewController.h"
#import "VersionInfoViewController.h"
#import "SketchColorPickerController.h"
#import "BrowserViewController.h"
#import "ConversationListViewController.h"
#import "ConversationListViewController+Private.h"
#import "FullscreenImageViewController.h"
#import "KeyboardAvoidingViewController.h"
#import "PhoneNumberViewController.h"
#import "CountryCodeTableViewController.h"
#import "UIViewController+WR_Invite.h"
#import "UIActivityViewController+Invite.h"
#import "UsersInContactsSection.h"
#import "UsersInDirectorySection.h"
#import "GroupConversationsSection.h"
#import "TopPeopleLineSection.h"
#import "CollectionViewSectionAggregator.h"
#import "ProfileDetailsViewController.h"
#import "ContactsDataSource.h"
#import "LaunchImageViewController.h"
#import "VoiceUserImageView.h"
#import "VoiceChannelParticipantCell.h"
#import "ProfilePictureStepViewController.h"

// Helper objects
#import "PushTransition.h"
#import "PopTransition.h"
#import "ZoomTransition.h"
#import "CrossfadeTransition.h"
#import "VerticalTransition.h"
#import "MediaAsset.h"
#import "MagicConfig.h"
#import "PassthroughWindow.h"
#import "PassthroughTouchesView.h"
#import "StopWatch.h"

// Utils
#import "UIFont+MagicAccess.h"
#import "UIColor+MagicAccess.h"
#import "Analytics.h"
#import "AnalyticsEvent.h"
#import "Analytics+Events.h"
#import "Application+runDuration.h"
#import "NSURL+WireURLs.h"
#import "NSURL+WireLocale.h"
#import "Analytics+ProfileEvents.h"
#import "DeveloperMenuState.h"
#import "NSString+Fingerprint.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIColor+WAZExtensions.h"
#import "AccentColorChangeHandler.h"
#import "AnalyticsTracker+FileTransfer.h"
#import "TimeIntervalClusterizer.h"
#import "UIColor+WR_ColorScheme.h"
#import "UIApplication+Permissions.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "UIView+Zeta.h"
#import "NSString+Emoji.h"
#import "Message+Formatting.h"
#import "ImageCache.h"
#import "AVAsset+VideoConvert.h"
#import "DeviceOrientationObserver.h"
#import "Analytics+ConversationEvents.h"
#import "AppDelegate+Logging.h"
#import "LinkAttachment.h"
#import "Message+Formatting.h"
#import "UIImagePickerController+GetImage.h"
#import <Classy/UIColor+CASAdditions.h>
#import "MessagePresenter.h"
#import "WireStyleKit+Additions.h"
#import "UIResponder+FirstResponder.h"
#import "UIApplication+StatusBar.h"
#import "CASStyler+Variables.h"
#import "AVSLogObserver.h"
#import "NSIndexSet+IndexPaths.h"
#import "UIAlertController+Wire.h"
#import "NetworkConditionHelper.h"
#import "SoundEventRulesWatchDog.h"
#import "Analytics+CallEvents.h"
#import "UIScreen+Compact.h"
#import "NSString+EmoticonSubstitution.h"
#import "UILabel+TextTransform.h"
#import "NSString+TextTransform.h"
#import "KeyboardFrameObserver+iOS.h"

// Camera
#import "CameraController.h"

// Audio player
#import "AudioTrack.h"
#import "AudioTrackPlayer.h"
#import "MediaPlaybackManager.h"

#import <Localytics/Localytics.h>

