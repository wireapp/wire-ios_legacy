//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UIKit
import WireCommonComponents

enum CallActionIconType: IconLabelButtonInput {
    case microphone
    case camera
    case speaker
    case flipCamera
    case endCall
    case pickUp

    func icon(forState state: UIControl.State) -> StyleKitIcon {
        switch state {
        case .selected: return selectedIcon
        default: return normalIcon
        }
    }

    var label: String {
        typealias Voice = L10n.Localizable.Voice

        switch self {
        case .microphone: return Voice.MuteButton.title
        case .camera: return Voice.VideoButton.title
        case .speaker: return Voice.SpeakerButton.title
        case .flipCamera: return DeveloperFlag.isUpdatedCallingUI ? Voice.FlipCameraButton.title : Voice.FlipVideoButton.title
        case .endCall:  return DeveloperFlag.isUpdatedCallingUI ? Voice.HangUpButton.title : Voice.EndCallButton.title
        case .pickUp: return Voice.PickUpButton.title
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .microphone: return "CallMuteButton"
        case .camera: return "CallVideoButton"
        case .speaker: return "CallSpeakerButton"
        case .flipCamera: return "CallFlipCameraButton"
        case .endCall: return "EndCallButton"
        case .pickUp: return "PickUpButton"
        }
    }

    private var normalIcon: StyleKitIcon {
        switch self {
        case .microphone: return .microphoneOff
        case .camera: return .cameraOff
        case .speaker: return .speakerOff
        case .flipCamera: return .flipCamera
        case .endCall: return .endCall
        case .pickUp: return .endCall
        }
    }

    private var selectedIcon: StyleKitIcon {
        switch self {
        case .microphone: return .microphone
        case .camera: return .camera
        case .speaker: return .speaker
        case .flipCamera: return .flipCamera
        case .endCall: return .endCall
        case .pickUp: return .endCall
        }
    }
}
