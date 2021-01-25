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
import UIKit
import WireDataModel
import WireSyncEngine

protocol ParticipantsCellConfigurable: Reusable {
    func configure(with rowType: ParticipantsRowType, conversation: GroupDetailsConversationType, showSeparator: Bool)
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

enum ConversationRole {
    case admin, member
    
    var name: String {
        switch self {
        case .admin:
            return "Admins"
        case .member:
            return "Members"
        }
    }
}

private struct ParticipantsSectionViewModel {
    let rows: [ParticipantsRowType]
    let participants: [UserType]    
    let conversationRole: ConversationRole
    
    let showSectionCount: Bool
    var sectionAccesibilityIdentifier = "label.groupdetails.participants"
    var sectionTitle: String? {
        switch conversationRole {
        case .member:
            return showSectionCount ? ("group_details.conversation_members_header.title".localized.localizedUppercase + " (%d)".localized(args: participants.count)) : "group_details.conversation_members_header.title".localized.localizedUppercase
        case .admin:
            return showSectionCount ? ("group_details.conversation_admins_header.title".localized.localizedUppercase + " (%d)".localized(args: participants.count)) : "group_details.conversation_admins_header.title".localized.localizedUppercase
        }
    }
   
    var footerTitle: String {
        switch conversationRole {
            case .admin:
                return "participants.section.admins.footer".localized
            case .member:
                return "participants.section.members.footer".localized
        }
    }

    var footerVisible: Bool {
        return participants.isEmpty
    }
    
    var accessibilityTitle: String {
        return conversationRole.name
    }
        
    /// init method
    ///
    /// - Parameters:
    ///   - users: list of conversation participants
    ///   - conversationRole: participants' ConversationRole
    ///   - totalParticipantsCount: the number of all participants in the conversation
    ///   - clipSection: enable/disable the display of the “ShowAll” button
    ///   - maxParticipants: max number of participants we can display
    ///   - maxDisplayedParticipants: max number of participants we can display, if there are more than maxParticipants participants
    ///   - showSectionCount: current view model - a search result or not
    init(users: [UserType],
         conversationRole: ConversationRole,
         totalParticipantsCount: Int,
         clipSection: Bool = true,
         maxParticipants: Int,
         maxDisplayedParticipants: Int,
         showSectionCount: Bool = true) {
        participants = users.sorted(by: {
            $0.name < $1.name
        })
        self.conversationRole = conversationRole
        self.showSectionCount = showSectionCount
        rows = clipSection ? ParticipantsSectionViewModel.computeRows(participants,
                                                                      totalParticipantsCount: totalParticipantsCount,
                                                                      maxParticipants: maxParticipants,
                                                                      maxDisplayedParticipants: maxDisplayedParticipants) :
                             participants.map(ParticipantsRowType.init)
    }
    
    static func computeRows(_ participants: [UserType], totalParticipantsCount: Int, maxParticipants: Int, maxDisplayedParticipants: Int) -> [ParticipantsRowType] {
        guard participants.count > maxParticipants else { return participants.map(ParticipantsRowType.init) }
        return participants[0..<maxDisplayedParticipants].map(ParticipantsRowType.init) + [.showAll(totalParticipantsCount)]
    }
}

extension UserCell: ParticipantsCellConfigurable {
    func configure(with rowType: ParticipantsRowType, conversation: GroupDetailsConversationType, showSeparator: Bool) {
        guard case let .user(user) = rowType else { preconditionFailure() }
        configure(with: user, selfUser: SelfUser.current, conversation: conversation as? ZMConversation)
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
    private let conversation: GroupDetailsConversationType
    private var token: AnyObject?
    
    init(participants: [UserType],
         conversationRole: ConversationRole,
         conversation: GroupDetailsConversationType,
         delegate: GroupDetailsSectionControllerDelegate,
         totalParticipantsCount: Int,
         clipSection: Bool = true,
         maxParticipants: Int = Int.ConversationParticipants.maxNumberWithoutTruncation,
         maxDisplayedParticipants: Int = Int.ConversationParticipants.maxNumberOfDisplayed,
         showSectionCount: Bool = true) {
        viewModel = .init(users: participants,
                          conversationRole: conversationRole,
                          totalParticipantsCount: totalParticipantsCount,
                          clipSection: clipSection,
                          maxParticipants: maxParticipants,
                          maxDisplayedParticipants: maxDisplayedParticipants,
                          showSectionCount: showSectionCount)
        self.conversation = conversation
        self.delegate = delegate
        super.init()
        
        if let userSession = ZMUserSession.shared() {
            token = UserChangeInfo.add(userObserver: self, in: userSession)
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
        (cell as? SectionListCellType)?.cellIdentifier = "participants.section.participants.cell"
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
        case .user(let user):
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
