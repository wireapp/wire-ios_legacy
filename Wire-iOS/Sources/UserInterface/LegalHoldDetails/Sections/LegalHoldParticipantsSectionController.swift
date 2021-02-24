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
import WireSyncEngine

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

typealias LegalHoldDetailsConversation = Conversation & GroupDetailsConversation

private extension ConversationLike {
    func createViewModel() -> LegalHoldParticipantsSectionViewModel {
        return LegalHoldParticipantsSectionViewModel(participants: sortedActiveParticipantsUserTypes.filter(\.isUnderLegalHold))
    }
}

final class LegalHoldParticipantsSectionController: GroupDetailsSectionController {
    
    fileprivate weak var collectionView: UICollectionView?
    private var viewModel: LegalHoldParticipantsSectionViewModel
    private let conversation: LegalHoldDetailsConversation
    private var token: AnyObject?
    
    weak var delegate: LegalHoldParticipantsSectionControllerDelegate?
    
    init(conversation: LegalHoldDetailsConversation) {
        viewModel = conversation.createViewModel()
        self.conversation = conversation
        super.init()
        
        if let userSession = ZMUserSession.shared() {
            token = UserChangeInfo.add(userObserver: self, in: userSession)
        }
    }
    
    private func setupViewModel() {
        viewModel = LegalHoldParticipantsSectionViewModel(participants: conversation.sortedActiveParticipantsUserTypes.filter(\.isUnderLegalHold))
    }
    
    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        self.collectionView = collectionView
    }
    
    override var sectionTitle: String {
        return viewModel.sectionTitle
    }
    
    override var sectionAccessibilityIdentifier: String {
        return viewModel.sectionAccesibilityIdentifier
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.participants.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let participant = viewModel.participants[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCell.reuseIdentifier, for: indexPath) as! UserCell
        let showSeparator = (viewModel.participants.count - 1) != indexPath.row
        
        cell.configure(with: participant, selfUser: SelfUser.current, conversation: conversation)
        cell.accessoryIconView.isHidden = false
        cell.accessibilityIdentifier = "participants.section.participants.cell"
        cell.showSeparator = showSeparator
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = viewModel.participants[indexPath.row]
        
        delegate?.legalHoldParticipantsSectionWantsToPresentUserProfile(for: user)
    }
    
}

extension LegalHoldParticipantsSectionController: ZMUserObserver {
    
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.connectionStateChanged || changeInfo.nameChanged || changeInfo.isUnderLegalHoldChanged else { return }
        
        viewModel = conversation.createViewModel()
        collectionView?.reloadData()
    }
    
}
