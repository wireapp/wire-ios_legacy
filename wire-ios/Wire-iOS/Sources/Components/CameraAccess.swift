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
import WireSyncEngine

enum CameraAccessFeature: Int {
    case recordVideo
    case recordAudioMessage
    case takePhoto
}

final class CameraAccess: NSObject {

    /// if there is an on going call, show a alert and return true
    ///
    /// - Parameters:
    ///   - feature: a CameraAccessFeature for alert's message
    ///   - viewController: the viewController to present the alert
    /// - Returns: true is there is an on going call and a alert is shown
    static func displayAlertIfOngoingCall(at feature: CameraAccessFeature, from viewController: UIViewController) -> Bool {
        if ZMUserSession.shared()?.isCallOngoing == true {
            CameraAccess.displayCameraAlertForOngoingCall(at: feature, from: viewController)
            return true
        }

        return false
    }

    static private func displayCameraAlertForOngoingCall(at feature: CameraAccessFeature, from viewController: UIViewController) {
        let alert = UIAlertController.alertWithOKButton(title: "conversation.input_bar.ongoing_call_alert.title".localized,
                                            message: feature.message.localized)

        viewController.present(alert, animated: true)
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
