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

class ServicesSectionController: GroupDetailsSectionController {
    
    private weak var delegate: GroupDetailsSectionControllerDelegate?
    private let serviceUsers: [UserType]
    private let conversation: ZMConversation
    
    init(serviceUsers: [UserType], conversation: ZMConversation, delegate: GroupDetailsSectionControllerDelegate) {
        self.serviceUsers = serviceUsers
        self.conversation = conversation
        self.delegate = delegate
    }
    
    override func prepareForUse(in collectionView : UICollectionView?) {
        super.prepareForUse(in: collectionView)
        
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.zm_reuseIdentifier)
    }
    
    override var sectionTitle: String {
        return "participants.section.services".localized(args: serviceUsers.count).uppercased()
    }
    
    override var sectionAccessibilityIdentifier: String {
        return "label.groupdetails.services"
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return serviceUsers.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
    
}
