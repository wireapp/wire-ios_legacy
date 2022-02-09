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

extension UIAlertController {

    static func checkYourConnection() -> UIAlertController {
        let controller = UIAlertController(
            title: "guest_room.error.generic.title".localized,
            message: "guest_room.error.generic.message".localized,
            preferredStyle: .alert
        )
        controller.addAction(.ok())
        controller.view.tintColor = UIColor.from(scheme: .textForeground, variant: .light)
        return controller
    }

    static func confirmRemovingGuests(_ completion: @escaping (Bool) -> Void) -> UIAlertController {
        return confirmController(
            title: "guest_room.remove_guests.message".localized,
            confirmTitle: "guest_room.remove_guests.action".localized,
            completion: completion
        )
    }

    static func confirmRevokingLink(_ completion: @escaping (Bool) -> Void) -> UIAlertController {
        return confirmController(
            title: "guest_room.revoke_link.message".localized,
            confirmTitle: "guest_room.revoke_link.action".localized,
            completion: completion
        )
    }

    static func confirmController(title: String,
                                  message: String? = nil,
                                  confirmAction: UIAlertAction,
                                  completion: @escaping (Bool) -> Void) -> UIAlertController {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        controller.addAction(confirmAction)
        controller.addAction(.cancel { completion(false) })
        controller.view.tintColor = UIColor.from(scheme: .textForeground, variant: .light)
        return controller
    }

    static func confirmController(title: String,
                                  message: String? = nil,
                                  confirmTitle: String,
                                  completion: @escaping (Bool) -> Void) -> UIAlertController {
        let confirmAction = UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            completion(true)
        }

        return UIAlertController.confirmController(title: title,
                                                   message: message,
                                                   confirmAction: confirmAction,
                                                   completion: completion)
    }
}
