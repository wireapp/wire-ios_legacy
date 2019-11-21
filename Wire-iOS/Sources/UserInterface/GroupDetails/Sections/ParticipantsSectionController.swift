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
    let teamRole: TeamRole
    
    var sectionAccesibilityIdentifier = "label.groupdetails.participants"
    var sectionTitle: String? {
        switch teamRole {
        case .member:
            return "group_details.conversation_members_header.title".localized(args: participants.count).localizedUppercase
        case .admin:
            return "group_details.conversation_admins_header.title".localized(args: participants.count).localizedUppercase
        default:
            return nil
        }
    }
   
    var footerTitle: String {
        if teamRole.isAdminGroup {
            return "participants.section.admins.footer".localized
        } else {
            return "participants.section.members.footer".localized
        }
    }

    var footerVisible: Bool {
        return participants.isEmpty
    }
    
    var accessibilityTitle: String {
        switch teamRole {
        case .member:
            return "Members"
        case .admin:
            return "Admins"
        default:
            return ""
        }
    }
        
    /// init method
    ///
    /// - Parameters:
    ///   - participants: list of conversation participants
    ///   - teamRole: participant's role
    ///   - showAllRows: enable/disable the display of the “ShowAll” button
    init(participants: [UserType], teamRole: TeamRole, clipSection: Bool = true) {
        self.participants = participants
        self.teamRole = teamRole
        rows = clipSection ? ParticipantsSectionViewModel.computeRows(participants) : participants.map(ParticipantsRowType.init)
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
        accessoryIconView.isHidden = user.isSelfUser
        accessibilityIdentifier = identifier
        self.showSeparator = showSeparator
    }
}

final class ParticipantsSectionController: GroupDetailsSectionController {
    
    fileprivate weak var collectionView: UICollectionView? {
        didSet {
            guard let collectionView =  collectionView else { return }
            SectionFooter.register(collectionView: collectionView)
        }
    }
    private weak var delegate: GroupDetailsSectionControllerDelegate?
    private var viewModel: ParticipantsSectionViewModel
    private let conversation: ZMConversation
    private var token: AnyObject?
    
    init(participants: [UserType],
         teamRole: TeamRole,
         conversation: ZMConversation,
         delegate: GroupDetailsSectionControllerDelegate,
         clipSection: Bool = true) {
        viewModel = .init(participants: participants, teamRole: teamRole, clipSection: clipSection)
        self.conversation = conversation
        self.delegate = delegate
        super.init()
        
        if let userSession = ZMUserSession.shared() {
            token = UserChangeInfo.add(userObserver: self, for: nil, userSession: userSession)
        }
    }
    
    override func prepareForUse(in collectionView : UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        collectionView?.register(ShowAllParticipantsCell.self, forCellWithReuseIdentifier: ShowAllParticipantsCell.reuseIdentifier)
        self.collectionView = collectionView
    }

    override var sectionTitle: String? {
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
        (cell as? SectionListCellType)?.sectionName = viewModel.accessibilityTitle
        cell.configure(with: configuration, conversation: conversation, showSeparator: showSeparator)
        return cell
    }
    
    ///MARK: - footer
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        guard viewModel.footerVisible,
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter", for: IndexPath(item: 0, section: section)) as? SectionFooter else { return .zero }
        
        footer.titleLabel.text = viewModel.footerTitle
        
        footer.size(fittingWidth: collectionView.bounds.width)
        return footer.bounds.size
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter else { return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)}
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter", for: indexPath)
        (view as? SectionFooter)?.titleLabel.text = viewModel.footerTitle
        return view
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewModel.rows[indexPath.row] {
        case .user(let bareUser):
            guard let user = bareUser as? ZMUser else { return }
            delegate?.presentDetails(for: user)
        case .showAll:
            delegate?.presentFullParticipantsList(for: viewModel.participants, in: conversation)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        switch viewModel.rows[indexPath.row] {
        case .user(let bareUser):
            return !bareUser.isSelfUser
        default:
            return true
        }
    }

}

extension ParticipantsSectionController: ZMUserObserver {
    
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.connectionStateChanged || changeInfo.nameChanged else { return }
        collectionView?.reloadData()
    }
    
}
