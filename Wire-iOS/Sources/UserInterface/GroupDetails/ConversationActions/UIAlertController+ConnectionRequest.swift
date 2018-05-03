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

import Foundation


extension UIAlertController {
    @objc(controllerForAcceptingConnectionRequestForUser:completion:)
    static func acceptingConnectionRequest(for user: ZMUser, completion: @escaping (Bool) -> Void) -> UIAlertController {
        let controller = UIAlertController(
            title: "profile.connection_request_dialog.message".localized(args: user.displayName),
            message: nil,
            preferredStyle: .actionSheet
        )
        let acceptAction = UIAlertAction(
            title: "profile.connection_request_dialog.button_connect".localized,
            style: .default,
            handler: { _ in completion(true) }
        )
        let ignoreAction = UIAlertAction(
            title: "profile.connection_request_dialog.button_cancel".localized,
            style: .cancel,
            handler: { _ in completion(false) }
        )
        controller.addAction(acceptAction)
        controller.addAction(ignoreAction)
        return controller
    }
}
