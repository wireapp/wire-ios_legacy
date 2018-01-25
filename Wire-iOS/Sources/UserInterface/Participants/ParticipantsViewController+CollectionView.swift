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
        guard let userType = UserType(rawValue:section),
            let array = groupedParticipants[userType] as? [ZMUser]
            else { return 0 }

        return array.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ParticipantCellReuseIdentifier, for: indexPath) as? ParticipantsListCell else { fatal("unable to dequeue cell with ParticipantCellReuseIdentifier") }

        configureCell(cell, at: indexPath)
        return cell
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return hasServiceUserInParticipants() ? 2 : 1
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let userType = UserType(rawValue: section), userType == .serviceUser else { return .zero }

        return CGSize(width: collectionView.bounds.size.width, height: 48) /// FIXME: height
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard let userType = UserType(rawValue:indexPath.section), userType == .serviceUser else { return UICollectionReusableView() }

        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                                               withReuseIdentifier: ParticipantCollectionViewHeaderReuseIdentifier,
                                                                               for: indexPath) as? ParticipantsCollectionHeaderView
            else { fatal("cannot dequeue header") }

        headerView.title = "peoplepicker.header.services".localized

//        headerView.colorSchemeVariant = colorSchemeVariant /// TODO
        return headerView
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

/// Service user identification

extension ParticipantsViewController {
    func hasServiceUserInParticipants() -> Bool {
        guard let array = groupedParticipants[UserType.serviceUser] as? [ZMUser]
            else { return false }

        return array.count >= 1
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
