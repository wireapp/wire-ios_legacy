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

protocol ParticipantsCellConfigurable: Reusable {
    func configure(with rowType: ParticipantsRowType, conversation: ZMConversation, showSeparator: Bool)
}

enum ParticipantsRowType {
    case user(UserType)
    case showAll(Int)
    
    init(_ user: UserType) {
        self = .user(user)
    }
    
    var cellType: ParticipantsCellConfigurable.Type {
        switch self {
        case .user: return UserCell.self
        case .showAll: return ShowAllParticipantsCell.self
        }
    }
}

private struct ParticipantsSectionViewModel {
    static private let maxParticipants = 7
    let rows: [ParticipantsRowType]
    let participants: [UserType]
    
    var sectionAccesibilityIdentifier = "label.groupdetails.participants"
    
    var sectionTitle: String {
        return "participants.section.participants".localized(args: participants.count).uppercased()
    }

    init(participants: [UserType]) {
        self.participants = participants
        rows = ParticipantsSectionViewModel.computeRows(participants)
    }
    
    static func computeRows(_ participants: [UserType]) -> [ParticipantsRowType] {
        guard participants.count > maxParticipants else { return participants.map(ParticipantsRowType.init) }
        return participants[0..<5].map(ParticipantsRowType.init) + [.showAll(participants.count)]
    }
}

extension UserCell: ParticipantsCellConfigurable {
    func configure(with rowType: ParticipantsRowType, conversation: ZMConversation, showSeparator: Bool) {
        guard case let .user(user) = rowType else { preconditionFailure() }
        configure(with: user, conversation: conversation)
        accessoryIconView.isHidden = false
        accessibilityIdentifier = "participants.section.participants.cell"
        self.showSeparator = showSeparator
    }
}

class ParticipantsSectionController: GroupDetailsSectionController {
    
    fileprivate weak var collectionView: UICollectionView?
    private weak var delegate: GroupDetailsSectionControllerDelegate?
    private let viewModel: ParticipantsSectionViewModel
    private let conversation: ZMConversation
    private var token: AnyObject?
    
    init(participants: [UserType], conversation: ZMConversation, delegate: GroupDetailsSectionControllerDelegate) {
        viewModel = .init(participants: participants)
        self.conversation = conversation
        self.delegate = delegate
        super.init()
        token = UserChangeInfo.add(userObserver: self, for: nil, userSession: ZMUserSession.shared()!)
    }
    
    override func prepareForUse(in collectionView : UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        collectionView?.register(ShowAllParticipantsCell.self, forCellWithReuseIdentifier: ShowAllParticipantsCell.reuseIdentifier)
        self.collectionView = collectionView
    }
    
    override var sectionTitle: String {
        return viewModel.sectionTitle
    }
    
    override var sectionAccessibilityIdentifier: String {
        return viewModel.sectionAccesibilityIdentifier
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.rows.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let configuration = viewModel.rows[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: configuration.cellType.reuseIdentifier, for: indexPath) as! ParticipantsCellConfigurable & UICollectionViewCell
        let showSeparator = (viewModel.rows.count - 1) != indexPath.row
        cell.configure(with: configuration, conversation: conversation, showSeparator: showSeparator)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewModel.rows[indexPath.row] {
        case .user(let bareUser):
            guard let user = bareUser as? ZMUser else { return }
            delegate?.presentDetails(for: user)
        case .showAll:
            delegate?.presentFullParticipantsList(for: viewModel.participants, in: conversation)
        }
    }
    
}

extension ParticipantsSectionController: ZMUserObserver {
    
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.connectionStateChanged || changeInfo.nameChanged else { return }
        collectionView?.reloadData()
    }
    
}
