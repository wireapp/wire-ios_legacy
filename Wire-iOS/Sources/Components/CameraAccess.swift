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

@objc enum CameraAccessFeature: Int {
    case recordVideo
    case recordAudioMessage
    case takePhoto
}

@objcMembers public class CameraAccess: NSObject {

    static func displayCameraAlertForOngoingCall(at feature: CameraAccessFeature, from viewController: UIViewController) {
        let alert = UIAlertController(title: "conversation.input_bar.ongoing_call_alert.title".localized,
                                      message: feature.message.localized,
                                      cancelButtonTitle: "general.ok".localized)
        viewController.present(alert, animated: true, completion: nil)
    }
}

fileprivate extension CameraAccessFeature {
    var message: String {
        switch self {
        case .recordVideo: return "conversation.input_bar.ongoing_call_alert.video.message"
        case .recordAudioMessage: return "conversation.input_bar.ongoing_call_alert.audio.message"
        case .takePhoto: return "conversation.input_bar.ongoing_call_alert.photo.message"
        }
    }
}
