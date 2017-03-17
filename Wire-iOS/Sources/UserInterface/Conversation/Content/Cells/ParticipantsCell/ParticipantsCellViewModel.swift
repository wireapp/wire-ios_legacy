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


struct ParticipantsCellViewModel {

    let font, boldFont: UIFont?
    let textColor: UIColor?
    let message: ZMConversationMessage

    func image() -> UIImage? {
        return message.systemMessageData.map {
            UIImage(for: iconType(for: $0), iconSize: .tiny, color: textColor)
        }
    }

    func sortedUsers() -> [ZMUser] {
        guard let systemMessage = message.systemMessageData else { return [] }
        return systemMessage.users.subtracting([.selfUser()]).sorted { name(for: $0.0) < name(for: $0.1) }
    }

    private func iconType(for message: ZMSystemMessageData) -> ZetaIconType {
        switch message.systemMessageType {
        case .participantsAdded: return .plus
        case .participantsRemoved: return .minus
        default: return .conversation
        }
    }

    func attributedTitle() -> NSAttributedString? {
        guard let systemMessage = message.systemMessageData,
            let sender = message.sender.map(name),
            let labelFont = font,
            let labelBoldFont = boldFont,
            let labelTextColor = textColor else { return nil }

        let names = sortedUsers().map(name).joined(separator: ", ")
        let title = formatKey(for: systemMessage).localized(args: sender, names) && labelFont && labelTextColor
        return title.adding(font: labelBoldFont, to: sender)
    }

    func formatKey(for message: ZMSystemMessageData) -> String {
        switch message.systemMessageType {
        case .participantsAdded: return key(with: "added")
        case .participantsRemoved: return key(with: "removed")
        default: return key(with: "started")
        }
    }

    private func name(for user: ZMUser) -> String {
        if user.isSelfUser {
            return key(with: "you").localized
        } else if let conversation = message.conversation, conversation.activeParticipants.contains(user) {
            return user.displayName(in: conversation)
        } else {
            return user.displayName
        }
    }

    private func key(with pathComponent: String) -> String {
        return "content.system.conversation.\(pathComponent)"
    }

}
