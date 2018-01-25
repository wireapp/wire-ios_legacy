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

extension ParticipantsViewController: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        switch section {
        case UserType.user.rawValue:
            if let array = groupedParticipants[UserType.user] as? [AnyObject] {
                return array.count
            }
        case UserType.serviceUser.rawValue:
            if let array = groupedParticipants[UserType.serviceUser] as? [AnyObject] {
                return array.count
            }
        default:
            return 0
        }

        return 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ParticipantCellReuseIdentifier, for: indexPath) as? ParticipantsListCell else { fatal("unable to dequeue cell with ParticipantCellReuseIdentifier") }

        configureCell(cell, at: indexPath)
        return cell
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return hasServiceUserInParticipants() ? 2 : 1
    }

}

/// Cell configuration

extension ParticipantsViewController {
    func configureCell(_ cell: ParticipantsListCell, at indexPath: IndexPath) {
        guard let userType = UserType(rawValue:indexPath.section),
              let array = groupedParticipants[userType] as? [ZMUser],
              indexPath.row < array.count else { return }

        let user = array[indexPath.row]
        cell.update(for: user, in: conversation)
    }
}

///TODO: section title - service section with "peoplepicker.header.services"

/// Service user identification

extension ParticipantsViewController {
    func hasServiceUserInParticipants() -> Bool {
        var hasServiceUser = false

        for participant in participants {
            if let user = participant as? ZMUser, user.isServiceUser {
                hasServiceUser = true
                break
            }
        }

        return hasServiceUser
    }
}

/// refresh collection view data source

extension ParticipantsViewController {
    func updateParticipants()
    {
        self.participants = self.conversation.sortedOtherActiveParticipants
        self.groupedParticipants = self.conversation.sortedOtherActiveParticipantsGroupByUserType

        self.collectionView?.reloadData()
    }
}
