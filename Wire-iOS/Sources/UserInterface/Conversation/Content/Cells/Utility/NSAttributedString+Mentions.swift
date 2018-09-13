//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireExtensionComponents

private let log = ZMSLog(tag: "Mentions")

@objc class MentionWithUser: NSObject {
    let mention: Mention
    let user: UserType
    
    init(mention: Mention, user: UserType) {
        self.mention = mention
        self.user = user
        super.init()
    }
}

struct MentionToken {
    let value: String
}

struct MentionWithToken {
    let mention: MentionWithUser
    let token: MentionToken
}

extension ZMMessage {
    @objc var mentionsWithUsers: [MentionWithUser] {
        guard let managedObjectContext = self.managedObjectContext else {
            fatal("userSession.managedObjectContext == nil")
        }
        
        return self.textMessageData?.mentions?.compactMap { mention in
            guard let user = ZMUser(remoteID: mention.userId, createIfNeeded: false, in: managedObjectContext) else {
                return nil
            }
            return MentionWithUser(mention: mention, user: user)
        } ?? []
    }
}

extension Mention {
    public var link: URL {
        return URL(string: "wire-user://id/" + userId.transportString())!
    }
}

extension NSMutableString {
    func replaceMentionsWithTokens(_ mentions: [MentionWithUser]) -> [MentionWithToken] {
        return mentions.sorted {
            return $0.mention.range.location > $1.mention.range.location
            } .prefix(500).compactMap { mentionWithUser in
                
                let mention = mentionWithUser.mention
                
                guard mention.range.location >= 0,
                      mention.range.length > 0,
                     (mention.range.location + mention.range.length) <= self.length else {
                      log.error("Cannot process mention: \(mention)")
                        return nil
                }
                
                let token = UUID().transportString()
                self.replaceCharacters(in: mention.range, with: token)
                
                return MentionWithToken(mention: mentionWithUser, token: MentionToken(value: token))
        }
    }
}

extension NSMutableAttributedString {
    static func mention(for user: UserType, link: URL, suggestedSize: CGFloat? = nil) -> NSAttributedString {
        let color: UIColor
        let backgroundColor: UIColor
        
        if user.isSelfUser {
            color = .white
            backgroundColor = ColorScheme.default.accentColor
        }
        else {
            color = ColorScheme.default.accentColor
            backgroundColor = .clear
        }
        
        let size = suggestedSize ?? 16
        
        let atFont: UIFont = UIFont.systemFont(ofSize: size - 2, contentSizeCategory: UIApplication.shared.preferredContentSizeCategory, weight: .light)
        let mentionFont: UIFont = UIFont.systemFont(ofSize: size,
                                                    contentSizeCategory: UIApplication.shared.preferredContentSizeCategory,
                                                    weight: .semibold)
        
        var atAttributes = [NSAttributedStringKey.font: atFont,
                            NSAttributedStringKey.foregroundColor: color,
                            NSAttributedStringKey.backgroundColor: backgroundColor]
        
        if !user.isSelfUser {
            atAttributes[NSAttributedStringKey.link] = link as NSObject
        }
        
        let atString = "@" && atAttributes
        
        var mentionAttributes = [NSAttributedStringKey.font: mentionFont,
                                 NSAttributedStringKey.foregroundColor: color,
                                 NSAttributedStringKey.backgroundColor: backgroundColor]
        
        if !user.isSelfUser {
            mentionAttributes[NSAttributedStringKey.link] = link as NSObject
        }
        
        let mentionText = (user.name ?? user.displayName) && mentionAttributes
        
        return atString + mentionText
    }
    
    func highlight(mentions: [MentionWithToken]) {
        
        let mutableString = self.mutableString
        
        mentions.forEach { mentionWithToken in
            let mentionRange = mutableString.range(of: mentionWithToken.token.value)
            let mention = mentionWithToken.mention.mention
            let user = mentionWithToken.mention.user
            
            guard mentionRange.location != NSNotFound
                else {
                log.error("Cannot process mention: \(mentionWithToken)")
                return
            }
            
            let currentFont = self.attributes(at: mentionRange.location, effectiveRange: nil)[.font] as? UIFont
            
            let replacementString = NSMutableAttributedString.mention(for: user, link: mention.link, suggestedSize: currentFont?.pointSize)
            
            self.replaceCharacters(in: mentionRange, with: replacementString)
        }
    }
}
