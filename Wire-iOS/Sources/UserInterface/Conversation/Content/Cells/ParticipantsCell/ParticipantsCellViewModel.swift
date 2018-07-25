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
    
    var hasGrammaticalObjects: Bool {
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

    let font, boldFont, largeFont: UIFont?
    let textColor: UIColor?
    let message: ZMConversationMessage

    func image() -> UIImage? {
        return message.actionType.image(with: textColor)
    }
    
    func sortedUsers() -> [ZMUser] {
        guard let sender = message.sender else { return [] }
        
        if message.actionType.hasGrammaticalObjects {
            guard let systemMessage = message.systemMessageData else { return [] }
            return systemMessage.users.subtracting([sender]).sorted { name(for: $0) < name(for: $1) }
        } else {
            return [sender]
        }
    }

    func sortedUsersWithoutSelf() -> [ZMUser] {
        return sortedUsers().filter { !$0.isSelfUser }
    }


    func attributedHeading() -> NSAttributedString? {
        guard
            let sender = message.sender,
            let font = font,
            let boldFont = boldFont,
            let largeFont = largeFont,
            let textColor = textColor
            else { return nil }
        
        guard case let .started(withName: conversationName?) = message.actionType else { return nil }
        
        let formatter = ParticipantsStringFormatter(
            message: message,
            font: font,
            boldFont: boldFont,
            largeFont: largeFont,
            textColor: textColor
        )
        
        return formatter.heading(sender: sender, conversationName: conversationName)
    }
    
    var showInviteButton: Bool {
        guard case .started = message.actionType,
                let conversation = message.conversation else { return false }
        return conversation.canManageAccess && conversation.allowGuests
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
        
        if message.actionType.hasGrammaticalObjects {
            return formatter.title(sender: sender, shownUsers: shownUsers, collapsedUsers: truncatedUsers)
        } else {
            return formatter.title(sender: sender)
        }
    }
    
    static let showMoreLinkURL = NSURL(string: "action://show-all")!
    
//    private var linkAttributes: [NSAttributedStringKey: AnyObject] {
//        return [.link: ParticipantsCellViewModel.showMoreLinkURL]
//    }
    
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
    
//    private var shownNames: String {
//        return names
//    }
    
//    private var collapsedNamesString: String? {
//        return emphasizedCollapsedNameStringComponent.map {
//            "content.system.started_conversation.truncated_people".localized(args: $0)
//        }
//    }
//
//    private var emphasizedCollapsedNameStringComponent: String? {
//        guard truncatedUsers.count > 0 else { return nil }
//        return "content.system.started_conversation.truncated_people.others".localized(args: "\(truncatedUsers.count)")
//    }

//    private var names: String {
//        return shownUsers.map {
//            if $0.isSelfUser {
//                if case .started = message.actionType {
//                    return "content.system.you_dative".localized
//                }
//                return "content.system.you_accusative".localized
//            }
//            return name(for: $0)
//        }.joined(separator: ", ")
//    }
    
//    private var attributedNames: NSAttributedString {
//        guard let font = font, let boldFont = boldFont, let color = textColor else { preconditionFailure() }
//
//        func attributedString(for user: ZMUser, collapsed: Bool) -> NSAttributedString {
//            if user.isSelfUser {
//                if collapsed {
//                    return "content.system.you_dative".localized && font && color
//                } else {
//                    return "content.system.and_you_dative".localized && font && color
//                }
//            }
//            return name(for: user) && boldFont && color
//        }
//
//        let collapsed = truncatedUsers.count > 0
//        let mutableString = NSMutableAttributedString()
//        for (index, user) in shownUsers.enumerated() {
//            mutableString.append(attributedString(for: user, collapsed: collapsed))
//
//            if index == shownUsers.count - 2, shownUsers[index + 1].isSelfUser, !collapsed {
//                mutableString.append(.breakingSpace && boldFont && color)
//            } else if index < shownUsers.count - 1 {
//                mutableString.append(", "  && boldFont && color)
//            }
//        }
//
//        return mutableString
//    }

    
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

private extension ConversationActionType {
    
    /// The object of an action may be in accusative or dative form.
    var objectGrammarCase: GrammarCase {
        switch self {
        case .started: return .dative
        default: return .accusative
        }
    }
}

private enum GrammarCase: String {
    case nominative, accusative, dative
}

private class ParticipantsStringFormatter {
    
    private let kStartedTheConversation = "content.system.conversation.with_name.title"
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
    
    private func name(for user: ZMUser, grammarCase: GrammarCase, conversation: ZMConversation?) -> String {
        if user.isSelfUser {
            return nameForSelfUser(grammarCase: grammarCase)
        }
        else if let conv = conversation, conv.activeParticipants.contains(user) {
            return user.displayName(in: conv)
        }
        else {
            return user.displayName
        }
    }
    
    private func nameForSelfUser(grammarCase: GrammarCase) -> String {
        return "content.system.you_\(grammarCase.rawValue)".localized
    }
    
    
    func heading(sender: ZMUser, conversationName: String) -> NSAttributedString {
        // "You/Bob"
        let senderName = name(for: sender, grammarCase: .nominative, conversation: message.conversation).capitalized
        // "started the conversation"
        var text = kStartedTheConversation.localized(pov: sender.pov, args: senderName) && font
        if !sender.isSelfUser { text = text.adding(font: boldFont, to: senderName) }
        // "Italy Trip"
        let title = conversationName.attributedString && largeFont
        return [text, title].joined(separator: "\n".attributedString) && textColor && .lineSpacing(4)
    }
    
    // title involving only subject (sender)
    func title(sender: ZMUser) -> NSAttributedString? {
        let senderName = name(for: sender, grammarCase: .nominative, conversation: message.conversation).capitalized
        let formatKey = message.actionType.formatKey
        
        switch message.actionType {
        case .left, .teamMemberLeave, .added(herself: true):
            let title = formatKey(sender.isSelfUser).localized(args: senderName) && font && textColor
            return sender.isSelfUser ? title : title.adding(font: boldFont, to: senderName)
        default: return nil
        }
    }
    
    // title involving subject (sender) and object(s) (users)
    func title(sender: ZMUser, shownUsers: [ZMUser], collapsedUsers: [ZMUser]) -> NSAttributedString? {
        let senderName = name(for: sender, grammarCase: .nominative, conversation: message.conversation).capitalized
        let formatKey = message.actionType.formatKey
        
        let grammarCase = message.actionType.objectGrammarCase
        let names = nameList(for: shownUsers, collapsedUsers: collapsedUsers, grammarCase: grammarCase)
        
        switch message.actionType {
        case .removed, .added(herself: false), .started(withName: .none):
            // "x, y, and 3 others"
            var title = formatKey(sender.isSelfUser).localized(args: senderName, names.string) && font && textColor
            if !sender.isSelfUser { title = title.adding(font: boldFont, to: senderName) }
            return names.applyComponentAttributes(to: title)
            
        case .started(withName: .some):
            let title = "\(kWith.localized) \(names.string)" && font && textColor
            return names.applyComponentAttributes(to: title)
        
        default: return nil
        }
        
    }
    
    
    /// Returns a `FormatSequence` describing a list of names. The list is comprised
    /// of usernames for shown users (complete with punctuation) and a count string
    /// for collapsed users, if any.
    /// E.g: "x, y, z, and 3 others"
    private func nameList(for shownUsers: [ZMUser], collapsedUsers: [ZMUser], grammarCase: GrammarCase) -> FormatSequence {
        guard !shownUsers.isEmpty else { preconditionFailure() }
        
        let result = FormatSequence()
        
        // all team users added?
        if let linkText = linkTextForWholeTeam() {
            result.append(linkText, with: linkAttributes)
            return result
        }
        
        let lastUser = shownUsers.last!
        
        // check if self user is shown & if so, it is the last
        let selfIncluded = shownUsers.any { $0.isSelfUser }
        guard !selfIncluded || (lastUser.isSelfUser) else { preconditionFailure() }
        
        // get the names of the users (with separator)
        let separator = shownUsers.count > 2 ? ", " : ""
        let userNames = shownUsers.map {
            name(for: $0, grammarCase: grammarCase, conversation: message.conversation) + separator
        }
        
        switch shownUsers.count {
        case 1:
            // "x"
            result.append(userNames.first!, with: selfIncluded ? normalAttributes : boldAttributes)
        case 2:
            // "x and y"
            let part = kAndX.localized(args: userNames)
            result.append(part, with: normalAttributes)
            result.define(boldAttributes, forComponent: userNames.first!)
            result.define(selfIncluded ? normalAttributes : boldAttributes, forComponent: userNames.last!)
        default:
            // "x, y, "
            result.append(userNames.dropLast().joined(), with: boldAttributes)
            
            // collapsed
            if let linkText = linkText(for: collapsedUsers) {
                // "you/z, "
                result.append(userNames.last!, with: selfIncluded ? normalAttributes : boldAttributes)
                
                // "and X others"
                let linkPart = kAndX.localized(args: linkText)
                result.append(linkPart, with: normalAttributes)
                result.define(linkAttributes, forComponent: linkText)
            }
            else {
                // trim the ", " off the end
                let lastName = String(userNames.last!.dropLast(2))
                // "and you/z"
                let lastPart = kAndX.localized(args: lastName)
                result.append(lastPart, with: normalAttributes)
                if !selfIncluded { result.define(boldAttributes, forComponent: lastName) }
            }
        }
        
        return result
    }
    
    
    private func linkText(for users: [ZMUser]) -> String? {
        guard !users.isEmpty else { return nil }
        return kXOthers.localized(args: "\(users.count)")
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
