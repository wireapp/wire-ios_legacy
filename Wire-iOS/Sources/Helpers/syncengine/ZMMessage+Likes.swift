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
import zmessaging

public enum ZMMessageReaction: String {
    case Like = "💖"
}

extension ZMConversationMessage {

    var canBeLiked: Bool {
        let sentOrDelivered = [ZMDeliveryState.Sent, .Delivered].contains(deliveryState)
        let likableType = Message.isNormalMessage(self) && !Message.isKnockMessage(self)
        return sentOrDelivered && likableType
    }

    var liked: Bool {
        set {
            let reaction: String? = newValue ? ZMMessageReaction.Like.rawValue : .None
            ZMMessage.addReaction(reaction, toMessage: self)
        }
        get {
            return likers().contains(.selfUser())
        }
    }

    func hasReactions() -> Bool {
        return self.usersReaction.map { (_, users) in
                return users.count
            }.reduce(0, combine: +) > 0
    }
    
    func likers() -> [ZMUser] {
        return usersReaction.filter { (reaction, _) -> Bool in
            reaction == ZMMessageReaction.Like.rawValue
            }.map { (_, users) in
                return users
            }.first ?? []
    }

}

public extension Message {

    @objc static func isLikedMessage(message: ZMMessage) -> Bool {
        return message.liked
    }
    
    @objc static func hasReactions(message: ZMMessage) -> Bool {
        return message.hasReactions()
    }
    
    @objc static func hasLikers(message: ZMMessage) -> Bool {
        return !message.likers().isEmpty
    }

    class func messageCanBeLiked(message: ZMMessage) -> Bool {
        return message.canBeLiked
    }

}
