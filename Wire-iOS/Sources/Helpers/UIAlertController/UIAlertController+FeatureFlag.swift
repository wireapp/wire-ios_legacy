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
import WireSyncEngine

extension UIAlertController {

    static func showFeatureConfigDidChangeAlert(_ featureName: Feature.Name, status: Feature.Status) {
        guard let viewController = UIApplication.shared.topmostViewController(onlyFullScreen: false) else { return }

        switch (featureName, status) {
        case (.fileSharing, .enabled):
            viewController.presentAlert(.fileSharingEnabled)

        case (.fileSharing, .disabled):
            viewController.presentAlert(.fileSharingDisabled)

        default:
            break
        }
    }

}

private extension UIViewController {

    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true, completion: nil)
    }

}


private extension UIAlertController {

    // MARK: - File sharing

    static var fileSharingEnabled: UIAlertController {
        return alertForFeatureChange(message: Strings.Update.FileSharing.Alert.Message.enabled)
    }

    static var fileSharingDisabled: UIAlertController {
        return alertForFeatureChange(message: Strings.Update.FileSharing.Alert.Message.disabled)
    }

    // MARK: - Self-deleting messages

    static var selfDeletingMessagesDisabled: UIAlertController {
        return alertForFeatureChange(message: Strings.Alert.SelfDeletingMessages.Message.disabled)
    }

    static var selfDeletingMessagesForcedOn: UIAlertController {
        return alertForFeatureChange(message: Strings.Alert.SelfDeletingMessages.Message.forcedOn)
    }

    // MARK: - Helpers

    typealias Strings = L10n.Localizable.FeatureConfig

    static func alertForFeatureChange(message: String) -> UIAlertController {
        return confirmationAlert(title: Strings.Alert.genericTitle, message: message)
    }

    static func confirmationAlert(title: String?, message: String) -> UIAlertController {
        return UIAlertController(title: title, message: message, alertAction: .ok())
    }

}
