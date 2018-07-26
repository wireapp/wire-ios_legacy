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


enum ConversationActionType {

    case none, started(withName: String?), added(herself: Bool), removed, left, teamMemberLeave
    // MOVE THIS OUT OF HERE
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
    
    var involvesUsersOtherThanSender: Bool {
        switch self {
        case .left, .teamMemberLeave, .added(herself: true): return false
        default: return true
        }
    }

    func image(with color: UIColor?) -> UIImage? {
        let icon: ZetaIconType
        switch self {
        case .started, .none:                   icon = .conversation
        case .added:                            icon = .plus
        case .removed, .left, .teamMemberLeave: icon = .minus
        }
        
        return UIImage(for: icon, iconSize: .tiny, color: color)
    }
    // THIS TOO
    private func localizationKey(with pathComponent: String, senderIsSelfUser: Bool) -> String {
        let senderPath = senderIsSelfUser ? "you" : "other"
        return "content.system.conversation.\(senderPath).\(pathComponent)"
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


struct ParticipantsCellViewModel {

    static let showMoreLinkURL = NSURL(string: "action://show-all")!
    
    let font, boldFont, largeFont: UIFont?
    let textColor: UIColor?
    let message: ZMConversationMessage
    
    private var maxShownUsers: Int {
        return isSelfIncludedInUsers ? 16 : 17
    }
    
    private var maxShownUsersWhenCollapsed: Int {
        return isSelfIncludedInUsers ? 14 : 15
    }
    
    var showInviteButton: Bool {
        guard case .started = message.actionType,
            let conversation = message.conversation else { return false }
        return conversation.canManageAccess && conversation.allowGuests
    }
    
    /// Users displayed in the system message, up to 17 when not collapsed
    /// but only 15 when there are more than 15 users and we collapse them.
    var shownUsers: [ZMUser] {
        let users = sortedUsersWithoutSelf()
        let boundary = users.count <= maxShownUsers ? users.count : maxShownUsersWhenCollapsed
        let result = users[..<boundary]
        return result + (isSelfIncludedInUsers ? [.selfUser()] : [])
    }
    
    /// Users not displayed in the system message but collapsed into a link.
    /// E.g. `and 5 others`.
    private var collapsedUsers: [ZMUser] {
        let users = sortedUsersWithoutSelf()
        guard users.count > maxShownUsers else { return [] }
        return Array(users.dropFirst(maxShownUsersWhenCollapsed))
    }
    
    /// The users represented by the collapsed link after being added to the
    /// conversation.
    var selectedUsers: [ZMUser] {
        switch message.actionType {
        case .added: return collapsedUsers
        default: return []
        }
    }
    
    var isSelfIncludedInUsers: Bool {
        return sortedUsers().any { $0.isSelfUser }
    }
    
    /// The users involved in the conversation action sorted alphabetically by
    /// name.
    func sortedUsers() -> [ZMUser] {
        guard let sender = message.sender else { return [] }
        guard message.actionType.involvesUsersOtherThanSender else { return [sender] }
        guard let systemMessage = message.systemMessageData else { return [] }
        return systemMessage.users.subtracting([sender]).sorted { name(for: $0) < name(for: $1) }
    }

    func sortedUsersWithoutSelf() -> [ZMUser] {
        return sortedUsers().filter { !$0.isSelfUser }
    }

    private func name(for user: ZMUser) -> String {
        if user.isSelfUser {
            return "content.system.you_\(grammaticalCase(for: user))".localized
        }
        if let conversation = message.conversation, conversation.activeParticipants.contains(user) {
            return user.displayName(in: conversation)
        } else {
            return user.displayName
        }
    }
    
    /// The user will, depending on the context, be in a specific case within the
    /// sentence. This is important for localization of "you".
    private func grammaticalCase(for user: ZMUser) -> String {
        if user == message.sender {
            // sender is always the subject doing the action
            return "nominative"
        } else if case ConversationActionType.started = message.actionType {
            // "sender started the conversation WITH ... user"
            return "dative"
        } else {
            return "accusative"
        }
    }
    
    // ------------------------------------------------------------
    
    func image() -> UIImage? {
        return message.actionType.image(with: textColor)
    }
    
    func attributedHeading() -> NSAttributedString? {
        guard
            case let .started(withName: conversationName?) = message.actionType,
            let sender = message.sender,
            let font = font,
            let boldFont = boldFont,
            let largeFont = largeFont,
            let textColor = textColor
            else { return nil }
        
        let formatter = ParticipantsStringFormatter(
            message: message,
            font: font,
            boldFont: boldFont,
            largeFont: largeFont,
            textColor: textColor
        )
        
        let senderName = name(for: sender).capitalized
        return formatter.heading(senderName: senderName, senderIsSelf: sender.isSelfUser, convName: conversationName)
    }
    
    func attributedTitle() -> NSAttributedString? {
        guard
            let sender = message.sender,
            let font = font,
            let boldFont = boldFont,
            let textColor = textColor
            else { return nil }
        
        // REFACTOR THIS, DON'T WANT TO PASS THE LARGE FONT HERE
        let formatter = ParticipantsStringFormatter(
            message: message,
            font: font,
            boldFont: boldFont,
            largeFont: largeFont!,
            textColor: textColor
        )
        
        let senderName = name(for: sender).capitalized
        
        if message.actionType.involvesUsersOtherThanSender {
            let userNames = shownUsers.map { self.name(for: $0) }
            let nameList = NameList(names: userNames, collapsed: collapsedUsers.count, selfIncluded: isSelfIncludedInUsers)
            return formatter.title(senderName: senderName, senderIsSelf: sender.isSelfUser, names: nameList)
        } else {
            return formatter.title(senderName: senderName, senderIsSelf: sender.isSelfUser)
        }
    }

}


private typealias Attributes = [NSAttributedStringKey : AnyObject]

private class FormatSequence {
    typealias SubstringAttrs = (substring: String, attrs: Attributes)
    var string = String()
    var componentAttributes = [SubstringAttrs]()
    
    func append(_ component: String, with attrs: Attributes) {
        string.append(component)
        define(attrs, forComponent: component)
    }
    
    func define(_ attrs: Attributes, forComponent string: String) {
        componentAttributes.append(SubstringAttrs(string, attrs))
    }
    
    func applyComponentAttributes(to attributedString: NSAttributedString) -> NSAttributedString {
        let mutableCopy = NSMutableAttributedString(attributedString: attributedString)
        componentAttributes.forEach {
            mutableCopy.addAttributes($0.attrs, to: $0.substring)
        }
        return mutableCopy
    }
}


private struct NameList {
    let names: [String]
    let collapsed: Int
    let selfIncluded: Bool
}

private class ParticipantsStringFormatter {
    
    private let kYouStartedTheConversation = "content.system.conversation.with_name.title-you"
    private let kXStartedTheConversation = "content.system.conversation.with_name.title"
    private let kXOthers = "content.system.started_conversation.truncated_people.others"
    private let kAndX = "content.system.started_conversation.truncated_people"
    private let kWith = "content.system.conversation.with_name.participants"
    private let kXAndY = "content.system.participants_1_other"
    private let kCompleteTeam = "content.system.started_conversation.complete_team"
    private let kCompleteTeamWithGuests = "content.system.started_conversation.complete_team.guests"
    
    private let font, boldFont, largeFont: UIFont
    private let textColor: UIColor
    
    private let message: ZMConversationMessage
    
    private var normalAttributes: Attributes {
        return [.font: font, .foregroundColor: textColor]
    }
    
    private var boldAttributes: Attributes {
        return [.font: boldFont, .foregroundColor: textColor]
    }
    
    private var largeAttributes: Attributes {
        return [.font: largeFont, .foregroundColor: textColor]
    }
    
    private var linkAttributes: Attributes {
        return [.link: ParticipantsCellViewModel.showMoreLinkURL]
    }
    
    init(message: ZMConversationMessage, font: UIFont, boldFont: UIFont, largeFont: UIFont, textColor: UIColor) {
        self.message = message
        self.font = font
        self.boldFont = boldFont
        self.largeFont = largeFont
        self.textColor = textColor
    }
    
    func heading(senderName: String, senderIsSelf: Bool, convName: String) -> NSAttributedString {
        // "... started the conversation"
        var text: NSAttributedString
        if senderIsSelf {
            text = kYouStartedTheConversation.localized(args: senderName) && font
        } else {
            text = kXStartedTheConversation.localized(args: senderName) && font
            text = text.adding(font: boldFont, to: senderName)
        }
        // "Italy Trip"
        let title = convName.attributedString && largeFont
        return [text, title].joined(separator: "\n".attributedString) && textColor && .lineSpacing(4)
    }

    // title involving only subject (sender)
    func title(senderName: String, senderIsSelf: Bool) -> NSAttributedString? {
        switch message.actionType {
        case .left, .teamMemberLeave, .added(herself: true):
            let formatKey = message.actionType.formatKey
            let title = formatKey(senderIsSelf).localized(args: senderName) && font && textColor
            return senderIsSelf ? title : title.adding(font: boldFont, to: senderName)
        default: return nil
        }
    }
    
    // title involving subject (sender) and object(s) (users)
    func title(senderName: String, senderIsSelf: Bool, names: NameList) -> NSAttributedString? {
        let formatKey = message.actionType.formatKey
        let namesFormat = nameListFormat(for: names)
        
        switch message.actionType {
        case .removed, .added(herself: false), .started(withName: .none):
            var title = formatKey(senderIsSelf).localized(args: senderName, namesFormat.string) && font && textColor
            if !senderIsSelf { title = title.adding(font: boldFont, to: senderName) }
            return namesFormat.applyComponentAttributes(to: title)
            
        case .started(withName: .some):
            let title = "\(kWith.localized) \(namesFormat.string)" && font && textColor
            // this could be refactored
            return namesFormat.applyComponentAttributes(to: title)
        default: return nil
        }
    }
    
    /// Returns a `FormatSequence` describing a list of names. The list is comprised
    /// of usernames for shown users (complete with punctuation) and a count string
    /// for collapsed users, if any.
    /// E.g: "x, y, z, and 3 others"

    private func nameListFormat(for nameList: NameList) -> FormatSequence {
        // there must be some names
        guard !nameList.names.isEmpty else { preconditionFailure() }

        let result = FormatSequence()

        // all team users added?
        if let linkText = linkTextForWholeTeam() {
            result.append(linkText, with: linkAttributes)
            return result
        }
        
        let attrsForLastName = nameList.selfIncluded ? normalAttributes : boldAttributes
        let names = nameList.names
        
        switch names.count {
        case 1:
            // "x"
            result.append(names.last!, with: attrsForLastName)
        case 2:
            // "x and y"
            let part = kAndX.localized(args: names)
            result.append(part, with: normalAttributes)
            result.define(boldAttributes, forComponent: names.first!)
            result.define(attrsForLastName, forComponent: names.last!)
        default:
            // "x, y, "
            result.append(names.dropLast().map { $0 + ", " }.joined(), with: boldAttributes)
            
            if nameList.collapsed > 0 {
                // "you/z, "
                result.append(names.last! + ", ", with: attrsForLastName)
                // "and X others
                let linkText = kXOthers.localized(args: "\(nameList.collapsed)")
                let linkPart = kAndX.localized(args: linkText)
                result.append(linkPart, with: normalAttributes)
                result.define(linkAttributes, forComponent: linkText)
            } else {
                // "and you/z"
                let lastPart = kAndX.localized(args: names.last!)
                result.append(lastPart, with: normalAttributes)
                result.define(attrsForLastName, forComponent: names.last!)
            }
        }
        
        return result
    }
    
    private func linkTextForWholeTeam() -> String? {
        guard
            let systemMessage = message as? ZMSystemMessage,
            systemMessage.allTeamUsersAdded,
            message.conversation?.canManageAccess ?? false
            else { return nil }
        
        
        if systemMessage.numberOfGuestsAdded > 0 {
            return kCompleteTeamWithGuests.localized(args: String(systemMessage.numberOfGuestsAdded))
        } else {
            return kCompleteTeam.localized
        }
    }
}
