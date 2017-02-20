//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import Foundation
import Cartography

let CameraPreviewContainerSize: CGFloat = 72.0;
let OverlayButtonWidth: CGFloat = 56.0;
let GroupCallAvatarSize: CGFloat = 120.0;
let GroupCallAvatarGainRadius: CGFloat = 14.0;
let GroupCallAvatarLabelHeight: CGFloat = 30.0;

extension VoiceChannelOverlay {
    
    public func createConstraints(){
        
        constrain([videoView, shadow, videoNotAvailableBackground]) { views in
            let superview = (views.first?.superview)!
            views.forEach { $0.edges == superview.edges }
        }
        
        constrain(self, contentContainer, callingTopUserImage, topStatusLabel, centerStatusLabel) { view, contentContainer, callingTopUserImage, topStatusLabel, centerStatusLabel in
            contentContainer.width == 320 ~ LayoutPriority(750)
            contentContainer.width <= 320
            contentContainer.top == view.top
            contentContainer.bottom == view.bottom
            contentContainer.leading >= view.leading
            contentContainer.trailing <= view.trailing
            contentContainer.centerX == view.centerX
            
            callingTopUserImage.top == contentContainer.topMargin
            callingTopUserImage.leading == contentContainer.leadingMargin
            callingTopUserImage.height == callingTopUserImage.width
            callingTopUserImage.width == 56

            topStatusLabel.leading == contentContainer.leadingMargin ~ 750
            topStatusLabel.trailing == contentContainer.trailingMargin
            topStatusLabel.top == contentContainer.top + 50
            self.statusLabelToTopUserImageInset = topStatusLabel.leading == callingTopUserImage.trailing + 12
            self.statusLabelToTopUserImageInset.isActive = false
            
            centerStatusLabel.leading == contentContainer.leadingMargin
            centerStatusLabel.trailing == contentContainer.trailingMargin
            centerStatusLabel.centerY == contentContainer.centerY
        }
        
        constrain(contentContainer, avatarContainer, topStatusLabel, callingUserImage) { contentContainer, avatarContainer, topStatusLabel, callingUserImage in
            avatarContainer.top == topStatusLabel.bottom + 24
            avatarContainer.leading == contentContainer.leadingMargin
            avatarContainer.trailing == contentContainer.trailingMargin
            
            callingUserImage.width == 320 ~ LayoutPriority(750)
            callingUserImage.height == 320 ~ LayoutPriority(750)
            callingUserImage.width == callingUserImage.height
            callingUserImage.center == avatarContainer.center
            callingUserImage.leading >= avatarContainer.leading
            callingUserImage.trailing <= avatarContainer.trailing
            callingUserImage.top >= avatarContainer.top
            callingUserImage.bottom <= avatarContainer.bottom
        }
        
        constrain(self, participantsCollectionView, cameraPreviewView) { view, participantsCollectionView, cameraPreviewView in
            participantsCollectionView.height == (GroupCallAvatarSize + GroupCallAvatarGainRadius + GroupCallAvatarLabelHeight)
            participantsCollectionView.leading == view.leading
            participantsCollectionView.trailing == view.trailing
            participantsCollectionView.centerY == view.centerY
            
            cameraPreviewView.width == CameraPreviewContainerSize
            cameraPreviewView.top == view.top + 24
            cameraPreviewView.leading >= view.leading + 24
            cameraPreviewView.trailing <= view.trailing - 24
            self.cameraPreviewCenterHorisontally = (cameraPreviewView.centerX == view.centerX ~ 750)
        }
        
        constrain(contentContainer, avatarContainer, leaveButton) { view, avatarContainer, leave in
            leave.width == OverlayButtonWidth
            leave.centerX == view.centerX ~ 750
            leave.top == avatarContainer.bottom + 32
            leave.bottom == view.bottomMargin
            self.leaveButtonPinRightConstraint = leave.trailing == view.trailingMargin
            self.leaveButtonPinRightConstraint.isActive = false
        }
        
        constrain([ignoreButton, muteButton]) { buttons in
            let superview = (buttons.first?.superview)!
            buttons.forEach {
                $0.width == OverlayButtonWidth
                $0.bottom == superview.bottomMargin
                $0.leading == superview.leadingMargin
            }
        }
        
        constrain([acceptButton, acceptVideoButton, videoButton, speakerButton]) { buttons in
            let superview = (buttons.first?.superview)!
            buttons.forEach {
                $0.width == OverlayButtonWidth
                $0.bottom == superview.bottomMargin
                $0.trailing == superview.trailingMargin
            }
        }
    }
    
}
