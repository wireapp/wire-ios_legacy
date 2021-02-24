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
import WireSyncEngine

extension UIAlertController {

    static func degradedCall(degradedUser: UserType?, callEnded: Bool = false, confirmationBlock: ((_ continueDegradedCall: Bool) -> Void)? = nil) -> UIAlertController {

        // Choose localization prefix
        let prefix = callEnded
            ? "call.degraded.ended.alert"
            : "call.degraded.alert"

        // Set message
        var message = "\(prefix).message"

        switch degradedUser {
        case .some(let user) where user.isSelfUser:
            message = "\(message).self".localized
        case .some(let user):
            message = "\(message).user".localized(args: user.name ?? "")
        default:
            message = "\(message).unknown".localized
        }

        // Create controller
        let controller = UIAlertController(title: "\(prefix).title".localized, message: message, preferredStyle: .alert)

        // Add actions
        if let confirmationBlock = confirmationBlock {
            controller.addAction(UIAlertAction(title: "general.cancel".localized, style: .cancel) { (action) in
                confirmationBlock(false)
            })

            controller.addAction(UIAlertAction(title: "call.degraded.alert.action.continue".localized, style: .default) { (action) in
                confirmationBlock(true)
            })
        } else {
            controller.addAction(UIAlertAction(title: "general.ok".localized, style: .default))
        }

        return controller
    }

}
