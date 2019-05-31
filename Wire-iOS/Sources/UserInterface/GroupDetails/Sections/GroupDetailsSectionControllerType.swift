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


protocol GroupDetailsSectionControllerType: CollectionViewSectionController {
    var sectionTitle: String { get }
    var sectionAccessibilityIdentifier: String { get }
}

// The class extends GroupDetailsSectionControllerType has to be a NSObject since CollectionViewSectionController's parents extend NSObjectProtocol
typealias GroupDetailsSectionController = GroupDetailsSectionControllerType & NSObject

// MARK: - default implementation
extension GroupDetailsSectionControllerType {
    func registerSectionHeader(in collectionView : UICollectionView?) {
        collectionView?.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader")
    }

    func sectionHeader(_ collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionReusableView {
        let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader", for: indexPath)

        if let sectionHeaderView = supplementaryView as? SectionHeader {
            sectionHeaderView.titleLabel.text = sectionTitle
            sectionHeaderView.accessibilityIdentifier = sectionAccessibilityIdentifier
        }

        return supplementaryView
    }

    func defaultReferenceSizeForHeaderInSection(_ collectionView: UICollectionView) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 48)
    }

    func defaultSizeForItem(_ collectionView: UICollectionView) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
}
