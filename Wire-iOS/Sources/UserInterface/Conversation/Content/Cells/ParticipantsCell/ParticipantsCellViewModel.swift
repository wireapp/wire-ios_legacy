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

    case none, started(withName: String?), added, removed, left, teamMemberLeave

    func formatKey(senderIsSelfUser: Bool) -> String {
        switch self {
        case .left: return localizationKey(with: "left", senderIsSelfUser: senderIsSelfUser)
        case .added: return localizationKey(with: "added", senderIsSelfUser: senderIsSelfUser)
        case .removed: return localizationKey(with: "removed", senderIsSelfUser: senderIsSelfUser)
        case .started(withName: .none), .none: return localizationKey(with: "started", senderIsSelfUser: senderIsSelfUser)
        case .started(withName: .some): return "content.system.conversation.with_name.participants"
        case .teamMemberLeave: return "content.system.conversation.team.member-leave"
        }
    }
}


private extension ZMConversationMessage {
    var actionType: ConversationActionType {
        guard let systemMessage = systemMessageData, let sender = sender else { return .none }
        switch systemMessage.systemMessageType {
        case .participantsRemoved where systemMessage.users == [sender]: return .left
        case .participantsRemoved where systemMessage.users != [sender]: return .removed
        case .participantsAdded: return .added
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
        case .left: return [sender]
        default:
            guard let systemMessage = message.systemMessageData else { return [] }
            return systemMessage.users.subtracting([sender]).sorted { name(for: $0.0) < name(for: $0.1) }
        }
    }

    private func iconType(for message: ZMConversationMessage) -> ZetaIconType {
        switch message.actionType {
        case .started, .none: return .conversation
        case .added: return .plus
        case .removed, .left, .teamMemberLeave: return .minus
        }
    }

    func attributedHeading() -> NSAttributedString? {
        guard let sender = message.sender, let font = font, let largeFont = largeFont, let textColor = textColor else { return nil }
        guard case let .started(withName: conversationName?) = message.actionType else { return nil }
        
        let senderName = sender.isSelfUser ? "content.system.you_nominative".localized.capitalized : name(for: sender)
        let text = "content.system.conversation.with_name.title".localized(args: senderName) && font && textColor
        let title = conversationName.attributedString && largeFont && textColor
        return [text, title].joined(separator: "\n".attributedString) && .lineHeight(4)
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
            let title = formatKey(sender.isSelfUser).localized(args: names) && labelFont && labelTextColor
            let withBold = title.adding(font: labelBoldFont, to: names)
            return withBold
        case .none: return nil
        }
    }

    private var names: String {
        return sortedUsers().map{
            if $0.isSelfUser {
                if case .started = message.actionType {
                    return "content.system.you_dative".localized
                }
                return "content.system.you_accusative".localized
            }
            return name(for: $0)
            }.joined(separator: ", ")
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
