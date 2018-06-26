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


class ParticipantsSectionController: GroupDetailsSectionController {
    
    fileprivate weak var collectionView: UICollectionView?
    private weak var delegate: GroupDetailsSectionControllerDelegate?
    private let participants: [ZMBareUser]
    private let conversation: ZMConversation
    private var token: AnyObject?
    
    init(participants: [ZMBareUser], conversation: ZMConversation, delegate: GroupDetailsSectionControllerDelegate) {
        self.participants = participants
        self.conversation = conversation
        self.delegate = delegate
        
        super.init()
        
        token = UserChangeInfo.add(observer: self, for: nil, userSession: ZMUserSession.shared()!)
    }
    
    override func prepareForUse(in collectionView : UICollectionView?) {
        super.prepareForUse(in: collectionView)
        
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.zm_reuseIdentifier)
        
        self.collectionView = collectionView
    }
    
    override var sectionTitle: String {
        return "participants.section.participants".localized(args: participants.count).uppercased()
    }
    
    override var sectionAccessibilityIdentifier: String {
        return "label.groupdetails.participants"
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return participants.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = participants[indexPath.row]
        let cell = collectionView.dequeueReusableCell(ofType: UserCell.self, for: indexPath)
        
        cell.accessoryIconView.isHidden = false
        cell.configure(with: user, conversation: conversation)
        cell.showSeparator = (participants.count - 1) != indexPath.row

        cell.accessibilityIdentifier = "participants.section.participants.cell"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let user = participants[indexPath.row] as? ZMUser else { return true }
        return !user.isSelfUser
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let user = participants[indexPath.row] as? ZMUser else { return true }
        return !user.isSelfUser
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = participants[indexPath.row] as? ZMUser else { return }
        delegate?.presentDetails(for: user)
    }
    
}

extension ParticipantsSectionController: ZMUserObserver {
    
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.connectionStateChanged || changeInfo.nameChanged else { return }
        
        collectionView?.reloadData()
    }
    
}
