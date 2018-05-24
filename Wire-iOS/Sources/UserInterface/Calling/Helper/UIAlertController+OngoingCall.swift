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

    static func ongoingCallJoinCallConfirmation(completion: @escaping (Bool) -> Void) -> UIAlertController {
        return ongoingCallConfirmation(
            titleKey: "call.alert.ongoing.join.title",
            buttonTitleKey: "call.alert.ongoing.join.button",
            completion: completion
        )
    }
    
    static func ongoingCallStartCallConfirmation(completion: @escaping (Bool) -> Void) -> UIAlertController {
        return ongoingCallConfirmation(
            titleKey: "call.alert.ongoing.start.title",
            buttonTitleKey: "call.alert.ongoing.start.button",
            completion: completion
        )
    }
    
    private static func ongoingCallConfirmation(
        titleKey: String,
        buttonTitleKey: String,
        completion: @escaping (Bool) -> Void
        ) -> UIAlertController {
        let controller = UIAlertController(title: nil, message: titleKey.localized, preferredStyle: .actionSheet)
        controller.addAction(.init(title: buttonTitleKey.localized, style: .default) { _ in completion(true) })
        controller.addAction(.cancel { completion(false) })
        return controller
    }

}
