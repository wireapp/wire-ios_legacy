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
        case .flipCamera: return DeveloperFlag.updatedCallingUI.isOn ? Voice.FlipCameraButton.title : Voice.FlipVideoButton.title
        case .endCall:  return DeveloperFlag.updatedCallingUI.isOn ? Voice.HangUpButton.title : Voice.EndCallButton.title
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .microphone: return "CallMuteButton"
        case .camera: return "CallVideoButton"
        case .speaker: return "CallSpeakerButton"
        case .flipCamera: return "CallFlipCameraButton"
        case .endCall: return "EndCallButton"
        }
    }

    private var normalIcon: StyleKitIcon {
        switch self {
        case .microphone: return .microphoneOff
        case .camera: return .cameraOff
        case .speaker: return .speakerOff
        case .flipCamera: return .flipCamera
        case .endCall: return .endCall
        }
    }

    private var selectedIcon: StyleKitIcon {
        switch self {
        case .microphone: return .microphone
        case .camera: return .camera
        case .speaker: return .speaker
        case .flipCamera: return .flipCamera
        case .endCall: return .endCall
        }
    }

    func accessibilityLabel(forState state: UIControl.State) -> String {
        switch state {
        case .selected: return selectedAccessibilityLabel
        default: return normalAccessibilityLabel
        }
    }

    private var normalAccessibilityLabel: String {
        typealias Calling = L10n.Accessibility.Calling

        switch self {
        case .microphone: return Calling.MicrophoneOnButton.description
        case .camera: return Calling.VideoOnButton.description
        case .speaker: return Calling.SpeakerOnButton.description
        case .flipCamera: return Calling.FlipCameraFrontButton.description
        case .endCall: return Calling.HangUpButton.description
        }
    }

    private var selectedAccessibilityLabel: String {
        typealias Calling = L10n.Accessibility.Calling

        switch self {
        case .microphone: return Calling.MicrophoneOffButton.description
        case .camera: return Calling.VideoOffButton.description
        case .speaker: return Calling.SpeakerOffButton.description
        case .flipCamera: return Calling.FlipCameraBackButton.description
        case .endCall: return Calling.HangUpButton.description
        }
    }
}
