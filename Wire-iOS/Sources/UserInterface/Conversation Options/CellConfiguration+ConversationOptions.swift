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
import UIKit

extension CellConfiguration {

    static func groupAdminToogle(get: @escaping () -> Bool,
                                 set: @escaping (Bool, UIView?) -> Void) -> CellConfiguration {
        return .iconToggle(
            title: L10n.Localizable.Profile.Profile.GroupAdminOptions.title,
            subtitle: "",
            identifier: "cell.profile.group_admin_options",
            titleIdentifier: "label.groupAdminOptions.description",
            icon: .groupAdmin,
            color: nil,
            isEnabled: true,
            get: get,
            set: set
        )
    }

    static func allowGuestsToogle(get: @escaping () -> Bool, set: @escaping (Bool, UIView?) -> Void, isDisabled: Bool) -> CellConfiguration {
        return .iconToggle(
            title: L10n.Localizable.GuestRoom.AllowGuests.title,
            subtitle: L10n.Localizable.GuestRoom.AllowGuests.subtitle,
            identifier: "toggle.guestoptions.allowguests",
            titleIdentifier: "label.guestoptions.description",
            icon: nil,
            color: nil,
            isEnabled: !isDisabled,
            get: get,
            set: set
        )
    }

    static func allowServicesToggle(get: @escaping () -> Bool, set: @escaping (Bool, UIView?) -> Void) -> CellConfiguration {
        return .iconToggle(
            title: L10n.Localizable.ServicesOptions.AllowServices.title,
            subtitle: L10n.Localizable.ServicesOptions.AllowServices.subtitle,
            identifier: "toggle.guestoptions.allowservices",
            titleIdentifier: "label.guestoptions.services.description",
            icon: nil,
            color: nil,
            isEnabled: true,
            get: get,
            set: set
        )
    }

    static func createLinkButton(action: @escaping Action) -> CellConfiguration {
        return .leadingButton(
            title: L10n.Localizable.GuestRoom.Link.Button.title,
            identifier: "",
            action: action
        )
    }

    static func copyLink(action: @escaping Action) -> CellConfiguration {
        return .iconAction(
            title: L10n.Localizable.GuestRoom.Actions.copyLink,
            icon: .copy,
            color: nil,
            action: action
        )
    }

    static let copiedLink: CellConfiguration = .iconAction(
            title: L10n.Localizable.GuestRoom.Actions.copiedLink,
            icon: .checkmark,
            color: nil,
            action: {_ in }
        )

    static func shareLink(action: @escaping Action) -> CellConfiguration {
        return .iconAction(
            title: L10n.Localizable.GuestRoom.Actions.shareLink,
            icon: .export,
            color: nil,
            action: action
        )
    }

    static func revokeLink(action: @escaping Action) -> CellConfiguration {
        return .iconAction(
            title: L10n.Localizable.GuestRoom.Actions.revokeLink,
            icon: .cross,
            color: nil,
            action: action
        )
    }

}
