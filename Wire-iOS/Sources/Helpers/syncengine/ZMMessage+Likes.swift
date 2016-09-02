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

public enum ZMMessgeReaction: String {
    case Like = "❤️"
}

extension ZMConversationMessage {
    
    var liked: Bool {
        set {
            if newValue {
                ZMMessage.addReaction(ZMMessgeReaction.Like.rawValue, toMessage: self)
            }
            else {
                ZMMessage.addReaction(.None, toMessage: self)
            }
        }
        get {
            let onlyLikes = self.usersReaction.filter { (reaction, users) in
                reaction == ZMMessgeReaction.Like.rawValue
            }
            
            for (_, users) in onlyLikes {
                if users.contains(ZMUser.selfUser()) {
                    return true
                }
            }
            
            return false
        }
    }
    
    func hasReactions() -> Bool {
        return self.usersReaction.map { (_, users) in
                return users.count
            }.reduce(0, combine: +) > 0
    }
    
    func likers() -> [ZMUser] {
        return usersReaction.filter { (reaction, _) -> Bool in
            reaction == ZMMessgeReaction.Like.rawValue
            }.map { (_, users) in
                return users
            }.first ?? []
    }
}

extension Message {
    @objc public static func isLikedMessage(message: ZMMessage) -> Bool {
        return message.liked
    }
    
    @objc public static func hasReactions(message: ZMMessage) -> Bool {
        return message.hasReactions()
    }
}
