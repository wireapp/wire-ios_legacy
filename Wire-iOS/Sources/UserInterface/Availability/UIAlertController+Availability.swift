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
import WireDataModel

extension UIAlertController {

    static func availabilityExplanation(_ availability: AvailabilityKind) -> UIAlertController {

        let title = availability.canonicalNameReminderTitle
        let message = availability.canonicalNameReminderMessage
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: L10n.Localizable.Availability.Reminder.Action.dontRemindMe,
            style: .default,
            handler: { (_) in
                Settings.shared.dontRemindUserWhenChanging(availability)
        }))
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.Availability.Reminder.Action.ok,
            style: .default,
            handler: { (_) in }))
        return alert
    }

    static func availabilityPicker(_ handler: @escaping (_ availability: AvailabilityKind) -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: L10n.Localizable.Availability.Message.setStatus,
            message: nil,
            preferredStyle: .actionSheet)

        for availability in AvailabilityKind.allCases {
            alert.addAction(UIAlertAction(title: availability.localizedName, style: .default, handler: { _ in
                handler(availability)
            }))
        }

        alert.popoverPresentationController?.permittedArrowDirections = [ .up, .down ]
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.Availability.Message.cancel,
            style: .cancel,
            handler: nil))

        return alert
    }
}
