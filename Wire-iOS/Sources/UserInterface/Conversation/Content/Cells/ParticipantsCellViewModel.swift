//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import WireCommonComponents
import UIKit
import WireDataModel

enum ConversationActionType {

    case none, started(withName: String?), added(herself: Bool), removed, left, teamMemberLeave
    
    /// Some actions only involve the sender, others involve other users too.
    var involvesUsersOtherThanSender: Bool {
        switch self {
        case .left, .teamMemberLeave, .added(herself: true): return false
        default:                                             return true
        }
    }
    
    var allowsCollapsing: Bool {
        // Don't collapse when removing participants, since the collapsed
        // link is only used for participants in the conversation.
        switch self {
        case .removed:  return false
        default:        return true
        }
    }

    func image(with color: UIColor) -> UIImage {
        let icon: StyleKitIcon
        switch self {
        case .started, .none:                   icon = .conversation
        case .added:                            icon = .plus
        case .removed, .left, .teamMemberLeave: icon = .minus
        }
        
        return icon.makeImage(size: .tiny, color: color)
    }
}

extension ZMConversationMessage {
    var actionType: ConversationActionType {
        guard let systemMessage = systemMessageData else { return .none }
        switch systemMessage.systemMessageType {
        case .participantsRemoved:  return systemMessage.userIsTheSender ? .left : .removed
        case .participantsAdded:    return .added(herself: systemMessage.userIsTheSender)
        case .newConversation:      return .started(withName: systemMessage.text)
        case .teamMemberLeave:      return .teamMemberLeave
        default:                    return .none
        }
    }
}

class ParticipantsCellViewModel {
    
    private typealias NameList = ParticipantsStringFormatter.NameList
    static let showMoreLinkURL = NSURL(string: "action://show-all")!
    
    let font, boldFont, largeFont: UIFont?
    let textColor, iconColor: UIColor
    let message: ZMConversationMessage
    
    private var action: ConversationActionType {
        return message.actionType
    }
    
    private var maxShownUsers: Int {
        return isSelfIncludedInUsers ? 16 : 17
    }
    
    private var maxShownUsersWhenCollapsed: Int {
        return isSelfIncludedInUsers ? 14 : 15
    }
    
    var showInviteButton: Bool {
        guard case .started = action, let conversation = message.conversation else { return false }
        return conversation.canManageAccess && conversation.allowGuests
    }
    
    private var showServiceUserWarning: Bool {
        guard case .added = action, let messageData = message.systemMessageData, let conversation = message.conversation else { return false }
        guard let users = Array(messageData.userTypes) as? [UserType] else { return false }
        
        let selfAddedToServiceConversation = users.any(\.isSelfUser) && conversation.areServicesPresent
        let serviceAdded = users.any(\.isServiceUser)
        return selfAddedToServiceConversation || serviceAdded
    }
    
    /// Users displayed in the system message, up to 17 when not collapsed
    /// but only 15 when there are more than 15 users and we collapse them.
    lazy var shownUsers: [UserType] = {
        let users = sortedUsersWithoutSelf
        let boundary = users.count > maxShownUsers && action.allowsCollapsing ? maxShownUsersWhenCollapsed : users.count
        let result = users[..<boundary]
        return result + (isSelfIncludedInUsers ? [SelfUser.current] : [])
    }()
    
    /// Users not displayed in the system message but collapsed into a link.
    /// E.g. `and 5 others`.
    private lazy var collapsedUsers: [UserType] = {
        let users = sortedUsersWithoutSelf
        guard users.count > maxShownUsers, action.allowsCollapsing else { return [] }
        return Array(users.dropFirst(maxShownUsersWhenCollapsed))
    }()
    
    /// The users to display when opening the participants details screen.
    var selectedUsers: [UserType] {
        switch action {
        case .added: return sortedUsers
        default: return []
        }
    }
    
    lazy var isSelfIncludedInUsers: Bool = {
        return sortedUsers.any(\.isSelfUser)
    }()
    
    /// The users involved in the conversation action sorted alphabetically by
    /// name.
    lazy var sortedUsers: [UserType] = {
        guard let sender = message.senderUser else { return [] }
        guard action.involvesUsersOtherThanSender else { return [sender] }
        guard let systemMessage = message.systemMessageData else { return [] }
        
        let usersWithoutSender: Set<AnyHashable>
        if let hashableSender = sender as? AnyHashable {
            usersWithoutSender = systemMessage.userTypes.subtracting([hashableSender])
        } else {
            usersWithoutSender = systemMessage.userTypes
        }
        guard let users = Array(usersWithoutSender) as? [UserType] else { return [] }
        
        return users.sorted { name(for: $0) < name(for: $1) }
    }()

    init(
        font: UIFont?,
        boldFont: UIFont?,
        largeFont: UIFont?,
        textColor: UIColor,
        iconColor: UIColor,
        message: ZMConversationMessage
        ) {
        self.font = font
        self.boldFont = boldFont
        self.largeFont = largeFont
        self.textColor = textColor
        self.iconColor = iconColor
        self.message = message
    }
    
    lazy var sortedUsersWithoutSelf: [UserType] = {
        return sortedUsers.filter { !$0.isSelfUser }
    }()

    private func name(for user: UserType) -> String {
        if user.isSelfUser {
            return "content.system.you_\(grammaticalCase(for: user))".localized
        } else {
            return user.name ?? "conversation.status.someone".localized
        }
    }
    
    private var nameList: NameList {
        let userNames = shownUsers.map { self.name(for: $0) }
        return NameList(names: userNames, collapsed: collapsedUsers.count, selfIncluded: isSelfIncludedInUsers)
    }
    
    /// The user will, depending on the context, be in a specific case within the
    /// sentence. This is important for localization of "you".
    private func grammaticalCase(for user: UserType) -> String {
        // user is always the subject
        if message.isUserSender(user) { return "nominative" }
        // "started with ... user"
        if case .started = action { return "dative" }
        return "accusative"
    }
    
    // ------------------------------------------------------------
    
    func image() -> UIImage? {
        return action.image(with: iconColor)
    }
    
    func attributedHeading() -> NSAttributedString? {
        guard
            case let .started(withName: conversationName?) = action,
            let sender = message.senderUser,
            let formatter = formatter(for: message)
            else { return nil }
        
        let senderName = name(for: sender).capitalized
        return formatter.heading(senderName: senderName, senderIsSelf: sender.isSelfUser, convName: conversationName)
    }

    func attributedTitle() -> NSAttributedString? {
        guard
            let sender = message.senderUser,
            let formatter = formatter(for: message)
            else { return nil }
        
        let senderName = name(for: sender).capitalized
        
        if action.involvesUsersOtherThanSender {
            return formatter.title(senderName: senderName, senderIsSelf: sender.isSelfUser, names: nameList)
        } else {
            return formatter.title(senderName: senderName, senderIsSelf: sender.isSelfUser)
        }
    }
    
    func warning() -> String? {
        guard showServiceUserWarning else { return nil }
        return "content.system.services.warning".localized
    }
    
    private func formatter(for message: ZMConversationMessage) -> ParticipantsStringFormatter? {
        guard let font = font, let boldFont = boldFont, let largeFont = largeFont else { return nil }
        
        return ParticipantsStringFormatter(
            message: message, font: font, boldFont: boldFont,
            largeFont: largeFont, textColor: textColor
        )
    }
}
