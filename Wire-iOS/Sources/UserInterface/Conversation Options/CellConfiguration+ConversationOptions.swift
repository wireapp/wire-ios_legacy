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

extension CellConfiguration {

    static func groupAdminToogle(get: @escaping () -> Bool,
                                 set: @escaping (Bool) -> Void) -> CellConfiguration {
        return .iconToggle(
            title: "profile.profile.group_admin_options.title".localized,
            subtitle: "",
            identifier: "cell.profile.group_admin_options",
            titleIdentifier: "label.groupAdminOptions.description",
            icon: .groupAdmin,
            color: nil,
            get: get,
            set: set
        )
    }

    static func allowGuestsToogle(get: @escaping () -> Bool, set: @escaping (Bool) -> Void) -> CellConfiguration {
        return .iconToggle(
            title: "guest_room.allow_guests.title".localized,
            subtitle: "guest_room.allow_guests.subtitle".localized,
            identifier: "toggle.guestoptions.allowguests",
            titleIdentifier: "label.guestoptions.description",
            icon: nil,
            color: nil,
            get: get,
            set: set
        )
    }

    static func createLinkButton(action: @escaping Action) -> CellConfiguration {
        return .leadingButton(
            title: "guest_room.link.button.title".localized,
            identifier: "",
            action: action
        )
    }

    static func copyLink(action: @escaping Action) -> CellConfiguration {
        return .iconAction(
            title: "guest_room.actions.copy_link".localized,
            icon: .copy,
            color: nil,
            action: action
        )
    }

    static let copiedLink: CellConfiguration = .iconAction(
            title: "guest_room.actions.copied_link".localized,
            icon: .checkmark,
            color: nil,
            action: {_ in }
        )

    static func shareLink(action: @escaping Action) -> CellConfiguration {
        return .iconAction(
            title: "guest_room.actions.share_link".localized,
            icon: .export,
            color: nil,
            action: action
        )
    }

    static func revokeLink(action: @escaping Action) -> CellConfiguration {
        return .iconAction(
            title: "guest_room.actions.revoke_link".localized,
            icon: .cross,
            color: nil,
            action: action
        )
    }

}
