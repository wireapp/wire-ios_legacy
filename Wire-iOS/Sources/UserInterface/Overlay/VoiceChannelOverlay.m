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


@import QuartzCore;
#import <PureLayout/PureLayout.h>
@import Classy;
@import WireExtensionComponents;
#import <avs/AVSVideoView.h>
#import <avs/AVSVideoPreview.h>

#import "VoiceChannelOverlay.h"
#import "VoiceChannelOverlayController.h"
#import "VoiceChannelCollectionViewLayout.h"
#import "UserImageView.h"
#import "UIImage+ZetaIconsNeue.h"
#import "WAZUIMagicIOS.h"
#import "zmessaging+iOS.h"
#import "UIColor+WAZExtensions.h"
#import "NSAttributedString+Wire.h"
#import "Constants.h"
#import "Analytics+iOS.h"
#import "UIColor+Mixing.h"
#import "WireStyleKit.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "RBBAnimation.h"
#import "CameraPreviewView.h"
#import "Wire-Swift.h"
#import "Settings.h"

NSString *const VoiceChannelOverlayVideoFeedPositionKey = @"VideoFeedPosition";

NSString *StringFromVoiceChannelOverlayState(VoiceChannelOverlayState state)
{
    if (VoiceChannelOverlayStateInvalid == state) {
        return @"OverlayInvalid";
    }
    if (VoiceChannelOverlayStateIncomingCall == state) {
        return @"OverlayIncomingCall";
    }
    else if (VoiceChannelOverlayStateIncomingCallInactive == state) {
        return @"OverlayIncomingCallInactive";
    }
    else if (VoiceChannelOverlayStateJoiningCall == state) {
        return @"OverlayJoiningCall";
    }
    else if (VoiceChannelOverlayStateOutgoingCall == state) {
        return @"OverlayOutgoingCall";
    }
    else if (VoiceChannelOverlayStateConnected == state) {
        return @"OverlayConnected";
    }
    return @"unknown";
}

@interface VoiceChannelOverlay_Old ()

@end



@implementation VoiceChannelOverlay_Old

#pragma mark - Message formating

@end
