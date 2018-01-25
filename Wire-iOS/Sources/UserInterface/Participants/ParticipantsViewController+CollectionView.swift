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

    // MARK: - section header

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

extension ParticipantsViewController {

    // MARK: - Cell configuration

    func user(at indexPath: IndexPath) -> ZMUser? {
        guard let userType = UserType(rawValue:indexPath.section),
            let array = groupedParticipants[userType] as? [ZMUser],
            indexPath.row < array.count else { return nil }

        let user = array[indexPath.row]

        return user
    }

    func configureCell(_ cell: ParticipantsListCell, at indexPath: IndexPath) {
        cell.update(for: user(at: indexPath), in: conversation)
    }

    // MARK: - Service user identification

    func hasServiceUserInParticipants() -> Bool {
        guard let array = groupedParticipants[UserType.serviceUser] as? [ZMUser]
            else { return false }

        return array.count >= 1
    }

    // MARK: - refresh collection view data source

    func updateParticipants()
    {
        self.participants = self.conversation.sortedOtherActiveParticipants
        self.groupedParticipants = self.conversation.sortedOtherActiveParticipantsGroupByUserType

        self.collectionView?.reloadData()
    }
}
