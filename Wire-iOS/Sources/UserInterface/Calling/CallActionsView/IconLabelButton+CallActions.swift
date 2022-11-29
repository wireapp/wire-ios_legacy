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

    convenience init(callActionIcon: CallActionIconType) {
        self.init(input: callActionIcon)
    }

    static func speaker() -> IconLabelButton {
        .init(callActionIcon: .speaker)
    }

    static func microphone() -> IconLabelButton {
        .init(callActionIcon: .microphone)
    }

    static func camera() -> IconLabelButton {
        .init(callActionIcon: .camera)
    }

    static func flipCamera() -> IconLabelButton {
        .init(callActionIcon: .flipCamera)
    }

}

extension CallingActionButton {

    convenience init(callingActionIcon: CallActionIconType) {
        self.init(input: callingActionIcon)
    }

    static func speakerButton() -> CallingActionButton {
        .init(callActionIcon: .speaker)
    }

    static func microphoneButton() -> CallingActionButton {
        .init(callActionIcon: .microphone)
    }

    static func cameraButton() -> CallingActionButton {
        .init(callActionIcon: .camera)
    }

    static func flipCameraButton() -> CallingActionButton {
        .init(callActionIcon: .flipCamera)
    }

}

extension EndCallButton {

    static func endCallButton() -> EndCallButton {
        .init(callActionIcon: .endCall)
    }
}
