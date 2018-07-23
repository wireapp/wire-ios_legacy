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


private func localizationKey(with pathComponent: String, senderIsSelfUser: Bool) -> String {
    let senderPath = senderIsSelfUser ? "you" : "other"
    return "content.system.conversation.\(senderPath).\(pathComponent)"
}


private enum ConversationActionType {

    case none, started(withName: String?), added(herself: Bool), removed, left, teamMemberLeave

    func formatKey(senderIsSelfUser: Bool) -> String {
        switch self {
        case .left: return localizationKey(with: "left", senderIsSelfUser: senderIsSelfUser)
        case .added(herself: true): return "content.system.conversation.guest.joined"
        case .added(herself: false): return localizationKey(with: "added", senderIsSelfUser: senderIsSelfUser)
        case .removed: return localizationKey(with: "removed", senderIsSelfUser: senderIsSelfUser)
        case .started(withName: .none), .none: return localizationKey(with: "started", senderIsSelfUser: senderIsSelfUser)
        case .started(withName: .some): return "content.system.conversation.with_name.participants"
        case .teamMemberLeave: return "content.system.conversation.team.member-leave"
        }
    }
}


private extension ZMConversationMessage {
    var actionType: ConversationActionType {
        guard let systemMessage = systemMessageData else { return .none }
        switch systemMessage.systemMessageType {
        case .participantsRemoved where systemMessage.userIsTheSender: return .left
        case .participantsRemoved where !systemMessage.userIsTheSender: return .removed
        case .participantsAdded: return .added(herself: systemMessage.userIsTheSender)
        case .newConversation: return .started(withName: systemMessage.text)
        case .teamMemberLeave: return .teamMemberLeave
        default: return .none
        }
    }
}


struct ParticipantsCellViewModel {

    let font, boldFont, largeFont: UIFont?
    let textColor: UIColor?
    let message: ZMConversationMessage

    func image() -> UIImage? {
        return UIImage(for: iconType(for: message), iconSize: .tiny, color: textColor)
    }
    
    func sortedUsers() -> [ZMUser] {
        guard let sender = message.sender else { return [] }
        
        switch message.actionType {
        case .left,
             .added(herself: true),
             .teamMemberLeave:
            return [sender]
        default:
            guard let systemMessage = message.systemMessageData else { return [] }
            return systemMessage.users.subtracting([sender]).sorted { name(for: $0) < name(for: $1) }
        }
    }

    func sortedUsersWithoutSelf() -> [ZMUser] {
        return sortedUsers().filter { !$0.isSelfUser }
    }

    private func iconType(for message: ZMConversationMessage) -> ZetaIconType {
        switch message.actionType {
        case .started, .none: return .conversation
        case .added: return .plus
        case .removed, .left, .teamMemberLeave: return .minus
        }
    }

    func attributedHeading() -> NSAttributedString? {
        guard let sender = message.sender, let font = font, let boldFont = boldFont, let largeFont = largeFont, let textColor = textColor else { return nil }
        guard case let .started(withName: conversationName?) = message.actionType else { return nil }
        
        let senderName = sender.isSelfUser ? "content.system.you_nominative".localized.capitalized : name(for: sender)
        var text = "content.system.conversation.with_name.title".localized(pov: sender.pov, args: senderName) && font && textColor
        if !sender.isSelfUser {
            text = text.adding(font: boldFont, to: senderName)
        }
        let title = conversationName.attributedString && largeFont && textColor
        return [text, title].joined(separator: "\n".attributedString) && .lineSpacing(4)
    }
    
    var showInviteButton: Bool {
        guard case .started = message.actionType,
                let conversation = message.conversation else { return false }
        return conversation.canManageAccess && conversation.allowGuests
    }

    func attributedTitle() -> NSAttributedString? {
        guard let sender = message.sender,
            let labelFont = font,
            let labelBoldFont = boldFont,
            let labelTextColor = textColor else { return nil }

        let senderName = sender.isSelfUser ? "content.system.you_nominative".localized.capitalized : name(for: sender)
        let formatKey = message.actionType.formatKey

        switch message.actionType {
        case .left, .teamMemberLeave:
            let title = formatKey(sender.isSelfUser).localized(args: senderName) && labelFont && labelTextColor
            return title.adding(font: labelBoldFont, to: senderName)
        case .removed, .added, .started(withName: .none):
            let title = formatKey(sender.isSelfUser).localized(args: senderName, names) && labelFont && labelTextColor
            return title.adding(font: labelBoldFont, to: senderName).adding(font: labelBoldFont, to: names)
        case .started(withName: .some):
            return attributedStartedConversationTitle(sender: sender, font: labelFont, boldFont: labelBoldFont, textColor: labelTextColor)
        case .none: return nil
        }
    }
    
    private func attributedStartedConversationTitle(
        sender: ZMUser,
        font: UIFont,
        boldFont: UIFont,
        textColor: UIColor
        ) -> NSAttributedString {

        let formatKey = message.actionType.formatKey
        let start = formatKey(sender.isSelfUser).localized && font && textColor
        
        // TODO: Move `allTeamUsersAdded` and `numberOfGuestsAdded` to ZMSystemMessageData protocol
        if let systemMessage = message as? ZMSystemMessage, systemMessage.allTeamUsersAdded, message.conversation?.canManageAccess == true {
            let link: String = {
                if systemMessage.numberOfGuestsAdded > 0 {
                    return "content.system.started_conversation.complete_team.guests".localized(args: "\(systemMessage.numberOfGuestsAdded)")
                } else {
                    return "content.system.started_conversation.complete_team".localized
                }
            }()
            
            let title = NSMutableAttributedString(attributedString: start + " " + link && font && textColor)
            title.addAttributes(linkAttributes, to: link)
            return title
        }
        
        let title = NSMutableAttributedString(attributedString: start + " " + attributedNames)
        
        // Append `and XYZ others` in case we collapsed the names.
        if let collapsedPart = collapsedNamesString, let emphasized = emphasizedCollapsedNameStringComponent {
            title.append(" " && font)
            title.append(collapsedPart && font && textColor)
            title.addAttributes(linkAttributes, to: emphasized)
        }

        return title
    }
    
    static let showMoreLinkURL = NSURL(string: "action://show-all")!
    
    private var linkAttributes: [NSAttributedStringKey: AnyObject] {
        return [.link: ParticipantsCellViewModel.showMoreLinkURL]
    }
    
    // Users not displayed in the system message but
    // collapsed into a link e.g. `and 5 others`.
    private var truncatedUsers: [ZMUser] {
        let users = sortedUsersWithoutSelf().filter { !$0.isSelfUser }
        guard users.count > maxShownUsers else { return [] }
        return Array(users.dropFirst(maxShownUsersWhenCollapsed))
    }

    var selectedUsers: [ZMUser] {
        switch message.actionType {
        case .added: return truncatedUsers
        default: return []
        }
    }

    private var maxShownUsers: Int {
        return isSelfIncludedInUsers ? 16 : 17
    }

    private var maxShownUsersWhenCollapsed: Int {
        return isSelfIncludedInUsers ? 14 : 15
    }

    // Users displayed in the system message, up to 17 when not collapsed
    // but only 15 when there are more than 15 users and we collapse them.
    var shownUsers: [ZMUser] {
        let users = sortedUsersWithoutSelf()
        
        if users.count <= maxShownUsers {
            if isSelfIncludedInUsers {
                return users  + [.selfUser()]
            } else {
                return users
            }
        } else {
            let truncatedUsers = users[..<maxShownUsersWhenCollapsed]
            if isSelfIncludedInUsers {
                return truncatedUsers + [.selfUser()]
            }
            return Array(truncatedUsers)
        }
    }
    
    var isSelfIncludedInUsers: Bool {
        return sortedUsers().any { $0.isSelfUser }
    }
    
    private var shownNames: String {
        return names
    }
    
    private var collapsedNamesString: String? {
        return emphasizedCollapsedNameStringComponent.map {
            "content.system.started_conversation.truncated_people".localized(args: $0)
        }
    }
    
    private var emphasizedCollapsedNameStringComponent: String? {
        guard truncatedUsers.count > 0 else { return nil }
        return "content.system.started_conversation.truncated_people.others".localized(args: "\(truncatedUsers.count)")
    }

    private var names: String {
        return shownUsers.map {
            if $0.isSelfUser {
                if case .started = message.actionType {
                    return "content.system.you_dative".localized
                }
                return "content.system.you_accusative".localized
            }
            return name(for: $0)
        }.joined(separator: ", ")
    }
    
    private var attributedNames: NSAttributedString {
        guard let font = font, let boldFont = boldFont, let color = textColor else { preconditionFailure() }
        
        func attributedString(for user: ZMUser, collapsed: Bool) -> NSAttributedString {
            if user.isSelfUser {
                if collapsed {
                    return "content.system.you_dative".localized && font && color
                } else {
                    return "content.system.and_you_dative".localized && font && color
                }
            }
            return name(for: user) && boldFont && color
        }
        
        let collapsed = truncatedUsers.count > 0
        let mutableString = NSMutableAttributedString()
        for (index, user) in shownUsers.enumerated() {
            mutableString.append(attributedString(for: user, collapsed: collapsed))

            if index == shownUsers.count - 2, shownUsers[index + 1].isSelfUser, !collapsed {
                mutableString.append(.breakingSpace && boldFont && color)
            } else if index < shownUsers.count - 1 {
                mutableString.append(", "  && boldFont && color)
            }
        }
        
        return mutableString
    }

    private func name(for user: ZMUser) -> String {
        if user.isSelfUser {
            return "content.system.you_nominative".localized
        }
        if let conversation = message.conversation, conversation.activeParticipants.contains(user) {
            return user.displayName(in: conversation)
        } else {
            return user.displayName
        }
    }

}
