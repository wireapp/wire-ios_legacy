//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension UIAlertController {
    static var unsupportedVersionAlert: UIAlertController {
        let alertController = UIAlertController(
            title: "voice.call_error.unsupported_version.title".localized,
            message: "voice.call_error.unsupported_version.message".localized,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(
            title: "force.update.ok_button".localized,
            style: .default,
            handler: { _ in UIApplication.shared.open(URL.wr_wireAppOnItunes) }
        ))

        alertController.addAction(UIAlertAction(
            title: "voice.call_error.unsupported_version.dismiss".localized,
            style: .default,
            handler: nil
        ))

        return alertController
    }
}
