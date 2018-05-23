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

import UIKit

extension IconLabelButton {

    static func speaker() -> IconLabelButton {
        return .init(
            icon: .speaker,
            label: "voice.speaker_button.title".localized,
            accessibilityIdentifier: "CallSpeakerButton"
        )
    }
    
    static func muteCall() -> IconLabelButton {
        return .init(
            icon: .microphoneWithStrikethrough,
            label: "voice.mute_button.title".localized,
            accessibilityIdentifier: "CallMuteButton"
        )
    }
    
    static func video() -> IconLabelButton {
        return .init(
            icon: .videoCall,
            label: "voice.video_button.title".localized,
            accessibilityIdentifier: "CallVideoButton"
        )
    }
    
    static func flipCamera() -> IconLabelButton {
        return .init(
            icon: .cameraSwitch,
            label: "voice.flip_video_button.title".localized,
            accessibilityIdentifier: "CallFlipCameraButton"
        )
    }
    
}
