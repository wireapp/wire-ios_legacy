//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@objc public enum MessageReaction: UInt16 {
    case like

    public var unicodeValue: String {
        switch self {
        case .like: return "❤️"
        }
    }
}

extension ZMMessage {

    static func appendReaction(_ unicodeValue: String?, toMessage message: ZMConversationMessage) -> ZMClientMessage? {
        guard let message = message as? ZMMessage, let context = message.managedObjectContext, let messageID = message.nonce else { return nil }
        guard message.isSent else { return nil }

        let emoji = unicodeValue ?? ""
        let reaction = WireProtos.Reaction.createReaction(emoji: emoji, messageID: messageID)
        let genericMessage = GenericMessage(content: reaction)

        guard let conversation = message.conversation else { return nil }

        do {
            let clientMessage = try conversation.appendClientMessage(with: genericMessage, expires: false, hidden: true)
            message.addReaction(unicodeValue, forUser: .selfUser(in: context))
            return clientMessage
        } catch {
            Logging.messageProcessing.warn("Failed to append reaction. Reason: \(error.localizedDescription)")
            return nil
        }
    }

    @discardableResult
    @objc public static func addReaction(_ reaction: MessageReaction, toMessage message: ZMConversationMessage) -> ZMClientMessage? {
        // confirmation that we understand the emoji
        // the UI should never send an emoji we dont handle
        if Reaction.transportReaction(from: reaction.unicodeValue) == .none {
            fatal("We can't append this reaction \(reaction.unicodeValue), this is a programmer error.")
        }

        return appendReaction(reaction.unicodeValue, toMessage: message)
    }

    @objc public static func removeReaction(onMessage message: ZMConversationMessage) {
        _ = appendReaction(nil, toMessage: message)
    }

    @objc public func addReaction(_ unicodeValue: String?, forUser user: ZMUser) {
        removeReaction(forUser: user)
        guard let unicodeValue = unicodeValue,
            unicodeValue.count > 0 else {
                updateCategoryCache()
                return
        }

        guard let reaction = self.reactions.first(where: {$0.unicodeValue! == unicodeValue}) else {
            // we didn't find a reaction, need to add a new one
            let newReaction = Reaction.insertReaction(unicodeValue, users: [user], inMessage: self)
            self.mutableSetValue(forKey: "reactions").add(newReaction)
            updateCategoryCache()
            return
        }
        reaction.mutableSetValue(forKey: ZMReactionUsersValueKey).add(user)
    }

    fileprivate func removeReaction(forUser user: ZMUser) {
        guard let reaction = self.reactions.first(where: {$0.users.contains(user)}) else {
            return
        }
        reaction.mutableSetValue(forKey: ZMReactionUsersValueKey).remove(user)
    }

    @objc public func clearAllReactions() {
        let oldReactions = self.reactions
        reactions.removeAll()
        guard let moc = managedObjectContext else { return }
        oldReactions.forEach(moc.delete)
    }

    @objc public func clearConfirmations() {
        let oldConfirmations = self.confirmations
        mutableSetValue(forKey: ZMMessageConfirmationKey).removeAllObjects()
        guard let moc = managedObjectContext else { return }
        oldConfirmations.forEach(moc.delete)
    }
}
