//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension UIViewController {

    /// Present an alert with a OK button
    ///
    /// - Parameters:
    ///   - title: optional title of the alert
    ///   - message: message of the alert
    ///   - animated: present the alert animated or not
    ///   - okActionHandler: optional closure for the OK button
    /// - Returns: the alert presented
    @discardableResult
    func presentAlertWithOKButton(title: String? = nil,
                                  message: String,
                                  animated: Bool = true,
                                  okActionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {

        let alert = UIAlertController.alertWithOKButton(title: title,
                                                        message: message,
                                                        okActionHandler: okActionHandler)

        present(alert, animated: animated)

        return alert
    }

    // MARK: - user profile deep link

    @discardableResult
    func presentInvalidUserProfileLinkAlert(okActionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        return presentAlertWithOKButton(title: "url_action.invalid_user.title".localized,
                                        message: "url_action.invalid_user.message".localized,
                                        okActionHandler: okActionHandler)
    }

}
