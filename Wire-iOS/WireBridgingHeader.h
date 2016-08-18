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
@import zmessaging;
#import "ZMUserSession+iOS.h"
#import <AVSMediaManager+Client.h>
#import <AVSMediaManager.h>
#import <AVSFlowManager.h>
#import <AVSAudioEffect.h>
#import <CommonCrypto/CommonCrypto.h>
#import "Settings.h"
#import "AppDelegate.h"
#import "Message.h"

// UI
@import WireExtensionComponents;
#import "UIColor+WAZExtensions.h"
#import "ConversationCell.h"
#import "WireStyleKit.h"
#import <Classy/UIViewController+CASAdditions.h>
#import "UIViewController+Errors.h"
#import "ConversationViewController.h"
#import "ConversationListCollectionViewLayout.h"
#import "ConversationListCell.h"
#import "GapLoadingBar.h"
#import "WAZUIMagicIOS.h"
#import "ResizingTextView.h"
#import "InvisibleInputAccessoryView.h"
#import <SCSiriWaveformView/SCSiriWaveformView.h>
#import "ConversationInputBarSendController.h"
#import "ConversationContentViewController+Private.h"
#import "MessageTimestampView.h"

// View Controllers
#import "ZClientViewController.h"
#import "FormFlowViewController.h"
#import "RegistrationStepViewController.h"
#import "NavigationController.h"
#import "SettingsTechnicalReportViewController.h"
#import "DevOptionsController.h"
#import "ConversationInputBarViewController.h"
#import "ConversationInputBarViewController+Files.h"
#import "ConversationInputBarViewController+Private.h"
#import "ConversationListContentController.h"
#import "ConversationListViewModel.h"
#import "ParticipantsChangedView.h"
#import "NotificationWindowRootViewController.h"
#import "VoiceChannelController.h"
#import "SplitViewController.h"
#import "ConfirmAssetViewController.h"
#import "SketchViewController.h"

// Helper objects
#import "PushTransition.h"
#import "PopTransition.h"
#import "ZoomTransition.h"
#import "CrossfadeTransition.h"
#import "VerticalTransition.h"
#import "MediaAsset.h"

// Utils
#import "UIFont+MagicAccess.h"
#import "UIColor+MagicAccess.h"
#import "Analytics.h"
#import "Analytics+iOS.h"
#import "AddressBookHelper.h"
#import "NSURL+WireURLs.h"
#import "NSURL+WireLocale.h"
#import "Analytics+ProfileEvents.h"
#import "DeveloperMenuState.h"
#import "NSString+Fingerprint.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIColor+WAZExtensions.h"
#import "AccentColorChangeHandler.h"
#import "ZMUserSession+Additions.h"
#import "AnalyticsTracker+FileTransfer.h"
#import "TimeIntervalClusterizer.h"
#import "UIColor+WR_ColorScheme.h"
#import "UIApplication+Permissions.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "UIViewController+Orientation.h"
#import "UIView+Zeta.h"
#import "NSString+Emoji.h"
#import "Message+Formatting.h"
#import "ImageCache.h"
#import "AVAsset+VideoConvert.h"
#import "DeviceOrientationObserver.h"
#import "Analytics+ConversationEvents.h"

// Camera
#import "CameraController.h"

// Audio player
#import "AudioTrack.h"
#import "AudioTrackPlayer.h"
#import "MediaPlaybackManager.h"


