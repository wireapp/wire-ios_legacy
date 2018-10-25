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

protocol GroupDetailsUserDetailPresenter: class {
    func presentDetails(for user: ZMUser)
}

protocol GroupDetailsSectionControllerDelegate: GroupDetailsUserDetailPresenter {
    func presentFullParticipantsList(for users: [UserType], in conversation: ZMConversation)
}

class GroupDetailsSectionController: NSObject, CollectionViewSectionController {

    var isHidden: Bool {
        return false
    }

    var sectionTitle: String {
        return ""
    }

    var sectionAccessibilityIdentifier: String {
        return "section_header"
    }

    func prepareForUse(in collectionView : UICollectionView?) {
        collectionView?.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader")
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader", for: indexPath)

        if let sectionHeaderView = supplementaryView as? SectionHeader {
            sectionHeaderView.titleLabel.text = sectionTitle
            sectionHeaderView.accessibilityIdentifier = sectionAccessibilityIdentifier
        }

        return supplementaryView
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 48)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fatal("Must be overridden")
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatal("Must be overridden")
    }

}
