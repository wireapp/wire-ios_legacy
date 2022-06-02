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

import UIKit

public typealias AlertActionHandler = (UIAlertAction) -> Void

public extension UIAlertController {

    /// Create an alert with a OK button
    ///
    /// - Parameters:
    ///   - title: optional title of the alert
    ///   - message: message of the alert
    ///   - okActionHandler: a nullable closure for the OK button
    /// - Returns: the alert presented
    static func alertWithOKButton(title: String? = nil,
                                  message: String,
                                  okActionHandler: AlertActionHandler? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)

        let okAction =  UIAlertAction.ok(style: .cancel, handler: okActionHandler)
        alert.addAction(okAction)

        return alert
    }

    convenience init(title: String? = nil,
                     message: String,
                     alertAction: UIAlertAction) {
        self.init(title: title,
                  message: message,
                  preferredStyle: .alert)
        addAction(alertAction)
    }

}

public extension UIAlertAction {
    static func ok(_ completion: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction.ok(style: .default, handler: completion)
    }

    static func ok(style: Style = .default, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(
            title: "general.ok".localized,
            style: style,
            handler: handler
        )
    }
}
