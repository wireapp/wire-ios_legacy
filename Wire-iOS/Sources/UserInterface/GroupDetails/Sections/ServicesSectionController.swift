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

final class ServicesSectionController: NSObject, GroupDetailsSectionControllerType {

    var isHidden: Bool {
        return false
    }

    private weak var delegate: GroupDetailsSectionControllerDelegate?
    private let serviceUsers: [UserType]
    private let conversation: ZMConversation
    
    init(serviceUsers: [UserType], conversation: ZMConversation, delegate: GroupDetailsSectionControllerDelegate) {
        self.serviceUsers = serviceUsers
        self.conversation = conversation
        self.delegate = delegate

    }
    
    func prepareForUse(in collectionView : UICollectionView?) {
        registerSectionHeader(in: collectionView)

        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.zm_reuseIdentifier)
    }
    
    var sectionTitle: String {
        return "participants.section.services".localized(uppercased: true, args: serviceUsers.count)
    }
    
    var sectionAccessibilityIdentifier: String {
        return "label.groupdetails.services"
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return serviceUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = serviceUsers[indexPath.row]
        let cell = collectionView.dequeueReusableCell(ofType: UserCell.self, for: indexPath)
        
        cell.configure(with: user, conversation: conversation)
        cell.showSeparator = (serviceUsers.count - 1) != indexPath.row
        cell.accessoryIconView.isHidden = false
        cell.accessibilityIdentifier = "participants.section.services.cell"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = serviceUsers[indexPath.row] as? ZMUser else { return }
        delegate?.presentDetails(for: user)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 48)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return defaultSizeForItem(collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        return sectionHeader(collectionView, at: indexPath)
    }

}
