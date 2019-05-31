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

protocol GroupOptionsSectionControllerDelegate: class {
    func presentTimeoutOptions(animated: Bool)
    func presentGuestOptions(animated: Bool)
    func presentNotificationsOptions(animated: Bool)
}

final class GroupOptionsSectionController: NSObject, GroupDetailsSectionControllerType {

    private enum Option: Int, CaseIterable, Restricted {

        fileprivate static let count = Option.allCases.count

        case notifications = 0, guests, timeout
        
        var requiredPermissions: Permissions {
            switch self {
            case .notifications: return .partner
            case .guests:        return .member
            case .timeout:       return .member
            }
        }

        var cellReuseIdentifier: String {
            switch self {
            case .guests: return GroupDetailsGuestOptionsCell.zm_reuseIdentifier
            case .timeout: return GroupDetailsTimeoutOptionsCell.zm_reuseIdentifier
            case .notifications: return GroupDetailsNotificationOptionsCell.zm_reuseIdentifier
            }
        }

    }

    // MARK: - Properties

    private weak var delegate: GroupOptionsSectionControllerDelegate?
    private let conversation: ZMConversation
    private let syncCompleted: Bool
    private let options: [Option]

    var isHidden: Bool {
        return false
    }

    var sectionAccessibilityIdentifier: String {
        return "section_header"
    }

    var hasOptions: Bool {
        return !options.isEmpty
    }
    
    init(conversation: ZMConversation, delegate: GroupOptionsSectionControllerDelegate, syncCompleted: Bool) {
        self.delegate = delegate
        self.conversation = conversation
        self.syncCompleted = syncCompleted
        var options = [Option]()
        
        let selfIsGuest = ZMUser.selfUser().isGuest(in: conversation)
        
        if ZMUser.selfUserIsTeamMember {
            Option.notifications.authorizeSelfUser {
                options.append(.notifications)
            }
        }
        
        if conversation.canManageAccess {
            Option.guests.authorizeSelfUser {
                options.append(.guests)
            }
        }
        
        if !selfIsGuest {
            Option.timeout.authorizeSelfUser {
                options.append(.timeout)
            }
        }
        
        self.options = options
    }

    // MARK: - Collection View
    
    var sectionTitle: String {
        return "participants.section.settings".localized(uppercased: true)
    }

    func prepareForUse(in collectionView: UICollectionView?) {
        registerSectionHeader(in: collectionView)
        collectionView.flatMap(GroupDetailsGuestOptionsCell.register)
        collectionView.flatMap(GroupDetailsTimeoutOptionsCell.register)
        collectionView.flatMap(GroupDetailsNotificationOptionsCell.register)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return defaultSizeForItem(collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 48)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let option = options[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: option.cellReuseIdentifier, for: indexPath) as! GroupDetailsDisclosureOptionsCell

        cell.configure(with: conversation)
        cell.showSeparator = indexPath.row < options.count - 1
        cell.isUserInteractionEnabled = syncCompleted
        cell.alpha = syncCompleted ? 1 : 0.48
        return cell

    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        switch options[indexPath.row] {
        case .guests:
            delegate?.presentGuestOptions(animated: true)
        case .timeout:
            delegate?.presentTimeoutOptions(animated: true)
        case .notifications:
            delegate?.presentNotificationsOptions(animated: true)
        }

    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return sectionHeader(collectionView, at: indexPath)
    }

}
