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
import WireDataModel

struct AddParticipantsViewModel {
    let context: AddParticipantsViewController.Context
    let variant: ColorSchemeVariant

    init(with context: AddParticipantsViewController.Context, variant: ColorSchemeVariant) {
        self.context = context
        self.variant = variant
    }

    var botCanBeAdded: Bool {
        switch context {
        case .create: return false
        case .add(let conversation): return conversation.botCanBeAdded
        }
    }

    var selectedUsers: UserSet {
        switch context {
        case .add(let conversation) where conversation.conversationType == .oneOnOne:
            return conversation.connectedUserType.map { [$0] } ?? []
        case .create(let values): return values.participants
        default: return []
        }
    }

    func title(with users: UserSet) -> String {
        return users.isEmpty
            ? "peoplepicker.group.title.singular".localized(uppercased: true)
            : "peoplepicker.group.title.plural".localized(uppercased: true, args: users.count)
    }

    var filterConversation: ZMConversation? {
        switch context {
        case .add(let conversation) where conversation.conversationType == .group: return conversation as? ZMConversation
        default: return nil
        }
    }

    var showsConfirmButton: Bool {
        switch context {
        case .add: return true
        case .create: return false
        }
    }

    var confirmButtonTitle: String? {
        switch context {
        case .create: return nil
        case .add(let conversation):
            if conversation.conversationType == .oneOnOne {
                return "peoplepicker.button.create_conversation".localized(uppercased: true)
            } else {
                return "peoplepicker.button.add_to_conversation".localized(uppercased: true)
            }
        }
    }

    func rightNavigationItem(target: AnyObject, action: Selector) -> UIBarButtonItem {
        switch context {
        case .add:
            let item = UIBarButtonItem(icon: .cross, target: target, action: action)
            item.tintColor = SemanticColors.Icon.foregroundCellIconActive
            item.accessibilityIdentifier = "close"
            return item
        case .create(let values):
            let key = values.participants.isEmpty ? "peoplepicker.group.skip" : "peoplepicker.group.done"
            let item = UIBarButtonItem(title: key.localized(uppercased: true), style: .plain, target: target, action: action)
            item.tintColor = UIColor.accent()
            item.accessibilityIdentifier = values.participants.isEmpty ? "button.addpeople.skip" : "button.addpeople.create"
            return item
        }
    }

}
