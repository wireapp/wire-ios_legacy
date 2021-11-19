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

    fileprivate struct Configuration {
        typealias FeatureFlag = L10n.Localizable.FeatureConfig.Update
        typealias FileSharingAlert = FeatureFlag.FileSharing.Alert

        var title: String?
        var message: String?

        init(featureName: Feature.Name, status: Feature.Status) {
            switch (featureName, status) {
            case (.fileSharing, .enabled):
                title = FileSharingAlert.title
                message = FileSharingAlert.Message.enabled
            case (.fileSharing, .disabled):
                title = FileSharingAlert.title
                message = FileSharingAlert.Message.disabled
            case (.appLock, _), (.conferenceCalling, _):
                break
            }
        }
    }

    public static func showFeatureConfigDidChangeAlert(_ featureName: Feature.Name, status: Feature.Status) {
        let alertConfiguration = Configuration(featureName: featureName, status: status)
        guard let title = alertConfiguration.title,
              let message = alertConfiguration.message else {
            return
        }
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                alertAction: .ok(style: .cancel))

        UIApplication.shared.topmostViewController(onlyFullScreen: false)?.present(alertController, animated: true)
    }

}
