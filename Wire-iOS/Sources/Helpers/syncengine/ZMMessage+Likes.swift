//
//  ZMUser+Likes.swift
//  Wire-iOS
//
//  Created by Mihail Gerasimenko on 9/1/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
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
                ZMMessage.removeReaction(onMessage: self)
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
        return message.usersReaction.count > 0
    }
}
