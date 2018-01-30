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
        guard let userType = UserType(rawValue: section), userType == .serviceUser else {
            return .zero
        }

        var height: CGFloat = 24
        if let headerView = collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader).first as? ParticipantsCollectionHeaderView {
            headerView.layoutIfNeeded()
            height = headerView.systemLayoutSizeFitting(UILayoutFittingExpandedSize).height
        }

        return CGSize(width: collectionView.bounds.size.width, height: height)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard let userType = UserType(rawValue:indexPath.section), userType == .serviceUser else { return UICollectionReusableView() }

        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                                               withReuseIdentifier: ParticipantCollectionViewSectionHeaderReuseIdentifier,
                                                                               for: indexPath) as? ParticipantsCollectionHeaderView
            else { fatal("cannot dequeue header") }

        headerView.title = "peoplepicker.header.services".localized
        return headerView
    }
}

extension ParticipantsViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard headerView?.titleView.isFirstResponder == false else {
            headerView?.titleView.resignFirstResponder()
            return
        }
        guard let user: ZMUser = user(at: indexPath) else { return }


        if let layoutAttributes: UICollectionViewLayoutAttributes = collectionView.layoutAttributesForItem(at: indexPath) {
            navigationControllerDelegate.tapLocation = collectionView.convert(layoutAttributes.center, to: view)
        }

        let viewContollerToPush = UIViewController.createUserDetailViewController(user: user, conversation: conversation, profileViewControllerDelegate: self, navigationControllerDelegate: navigationControllerDelegate)

        navigationController?.pushViewController(viewContollerToPush, animated: true)
    }
}

extension ParticipantsViewController {

    // MARK: - collectionview layout configuration

    func configCollectionViewLayout() {

        if self.view.frame.width * UIScreen.main.scale < DeviceNativeBoundsSize.iPhone4_7Inch.rawValue.width {
            self.collectionViewLayout.itemSize = CGSize(width: 80, height: 98)
            self.collectionViewLayout.minimumLineSpacing = 18
        } else {
            self.collectionViewLayout.itemSize = CGSize(width: 96, height: 106)
            self.collectionViewLayout.minimumLineSpacing = 26
        }

        self.collectionViewLayout.sectionInset = UIEdgeInsets(top: self.insetMargin, left: self.insetMargin, bottom: self.insetMargin, right: self.insetMargin)
    }

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

    func updateParticipants() {
        self.groupedParticipants = self.conversation.sortedOtherActiveParticipantsGroupByUserType

        self.collectionView?.reloadData()
    }
}
