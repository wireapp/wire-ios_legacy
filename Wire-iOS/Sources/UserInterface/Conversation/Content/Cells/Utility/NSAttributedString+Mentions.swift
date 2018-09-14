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

struct MentionToken {
    let value: String
    let name: String
}

struct MentionWithToken {
    let mention: Mention
    let token: MentionToken
}

extension Mention {
    static func link(for index: Int) -> URL {
        return URL(string: "wire-mention://id/\(index)")!
    }
}

extension NSMutableString {
    @objc(removeMentions:)
    func remove(_ mentions: [Mention]) {
        return mentions.sorted {
            return $0.range.location > $1.range.location
        }.forEach { mention in
            self.replaceCharacters(in: mention.range, with: "")
        }
    }
    
    @discardableResult func replaceMentions(_ mentions: [Mention]) -> [MentionWithToken] {
        return mentions.sorted {
            return $0.range.location > $1.range.location
        } .map { mention in
            let token = UUID().transportString()
            let name = self.substring(with: mention.range).replacingOccurrences(of: "@", with: "")
            self.replaceCharacters(in: mention.range, with: token)
            
            return MentionWithToken(mention: mention, token: MentionToken(value: token, name: name))
        }
    }
}

extension NSMutableAttributedString {
    static private func mention(for user: UserType, name: String, link: URL, suggestedFontSize: CGFloat? = nil) -> NSAttributedString {
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
        
        let fontSize = suggestedFontSize ?? UIFont.normalMediumFont.pointSize
        
        let atFont: UIFont = UIFont.systemFont(ofSize: fontSize - 2, contentSizeCategory: UIApplication.shared.preferredContentSizeCategory, weight: .light)
        let mentionFont: UIFont = UIFont.systemFont(ofSize: fontSize,
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
        
        let mentionText = name && mentionAttributes
        
        return atString + mentionText
    }
    
    func highlight(mentions: [MentionWithToken]) {
        
        let mutableString = self.mutableString
        
        var index = mentions.count - 1
        
        mentions.forEach { mentionWithToken in
            let mentionRange = mutableString.range(of: mentionWithToken.token.value)
            
            guard mentionRange.location != NSNotFound else {
                log.error("Cannot process mention: \(mentionWithToken)")
                return
            }
            
            let currentFont = self.attributes(at: mentionRange.location, effectiveRange: nil)[.font] as? UIFont
            
            let replacementString = NSMutableAttributedString.mention(for: mentionWithToken.mention.user,
                                                                      name: mentionWithToken.token.name,
                                                                      link: Mention.link(for: index),
                                                                      suggestedFontSize: currentFont?.pointSize)
            
            self.replaceCharacters(in: mentionRange, with: replacementString)
            
            index = index - 1
        }
    }
}
