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

    init(with context: AddParticipantsViewController.Context) {
        self.context = context
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
            ? L10n.Localizable.Peoplepicker.Group.Title.singular.capitalized
            : L10n.Localizable.Peoplepicker.Group.Title.plural(users.count).capitalized
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
                return L10n.Localizable.Peoplepicker.Button.createConversation.capitalized
            } else {
                return L10n.Localizable.Peoplepicker.Button.addToConversation.capitalized
            }
        }
    }

    func rightNavigationItem(target: AnyObject, action: Selector) -> UIBarButtonItem {
        switch context {
        case .add:
            let item = UIBarButtonItem(icon: .cross, target: target, action: action)
            item.tintColor = SemanticColors.Icon.foregroundDefault
            item.accessibilityIdentifier = "close"
            return item
        case .create(let values):
            let key = values.participants.isEmpty ? "peoplepicker.group.skip" : "peoplepicker.group.done"
            let newItem: UIBarButtonItem = .createNavigationRightBarButtonItem(title: key.localized.capitalized,
                                                                               systemImage: false,
                                                                               target: target,
                                                                               action: action)
            newItem.tintColor = UIColor.accent()
            newItem.accessibilityIdentifier = values.participants.isEmpty ? "button.addpeople.skip" : "button.addpeople.create"
            return newItem
        }
    }

}
