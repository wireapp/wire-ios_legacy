//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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


private struct LegalHoldParticipantsSectionViewModel {

    let participants: [UserType]
    
    var sectionAccesibilityIdentifier = "label.groupdetails.participants"
    
    var sectionTitle: String {
        return "legalhold.participants.section.title".localized(uppercased: true, args: participants.count)
    }
    
    init(participants: [UserType]) {
        self.participants = participants
    }
    
}

protocol LegalHoldParticipantsSectionControllerDelegate: class {
    
    func legalHoldParticipantsSectionWantsToPresentUserProfile(for user: UserType)
    
}

final class LegalHoldParticipantsSectionController: GroupDetailsSectionController {
    
    fileprivate weak var collectionView: UICollectionView?
    private let viewModel: LegalHoldParticipantsSectionViewModel
    private let conversation: ZMConversation
    private var token: AnyObject?
    
    public weak var delegate: LegalHoldParticipantsSectionControllerDelegate?
    
    init(participants: [UserType], conversation: ZMConversation) {
        viewModel = .init(participants: participants)
        self.conversation = conversation
        super.init()
        
        if let userSession = ZMUserSession.shared() {
            token = UserChangeInfo.add(userObserver: self, for: nil, userSession: userSession)
        }
    }
    
    func prepareForUse(in collectionView : UICollectionView?) {
        registerSectionHeader(in: collectionView)
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        self.collectionView = collectionView
    }

    var isHidden: Bool {
        return false
    }

    var sectionTitle: String {
        return viewModel.sectionTitle
    }
    
    var sectionAccessibilityIdentifier: String {
        return viewModel.sectionAccesibilityIdentifier
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.participants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let participant = viewModel.participants[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCell.reuseIdentifier, for: indexPath) as! UserCell
        let showSeparator = (viewModel.participants.count - 1) != indexPath.row
        
        cell.configure(with: participant, conversation: conversation)
        cell.accessoryIconView.isHidden = false
        cell.accessibilityIdentifier = "participants.section.participants.cell"
        cell.showSeparator = showSeparator
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = viewModel.participants[indexPath.row]
        
        delegate?.legalHoldParticipantsSectionWantsToPresentUserProfile(for: user)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return defaultReferenceSizeForHeaderInSection(collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return defaultSizeForItem(collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        return sectionHeader(collectionView, at: indexPath)
    }

}

extension LegalHoldParticipantsSectionController: ZMUserObserver {
    
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.connectionStateChanged || changeInfo.nameChanged else { return }
        collectionView?.reloadData()
    }
    
}
