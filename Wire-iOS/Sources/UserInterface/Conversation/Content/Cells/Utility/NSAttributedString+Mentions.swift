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
    static let mentionScheme = "wire-mention"
    
    var link: URL {
        return URL(string: "\(Mention.mentionScheme)://location/\(range.location)")!
    }
    
    @objc var location: Int {
        return range.location
    }
}

extension NSURL {
    @objc var isMentionURL: Bool {
        return scheme == Mention.mentionScheme
    }
    
    @objc var mentionLocation: Int {
        guard self.isMentionURL, let indexString = pathComponents?.last, let index = Int(indexString) else {
            return NSNotFound
        }
        
        return index
    }
}

extension NSMutableString {
    @objc(removeMentions:)
    func remove(_ mentions: [Mention]) {
        return mentions.sorted {
            return $0.range.location > $1.range.location
        }.forEach { mention in
            guard self.length >= (mention.range.location + mention.range.length) else {
                log.error("Wrong mention: \(mention)")
                return
            }
            self.replaceCharacters(in: mention.range, with: "")
        }
    }
    
    @discardableResult func replaceMentions(_ mentions: [Mention]) -> [MentionWithToken] {
        return mentions.sorted {
            return $0.range.location > $1.range.location
        } .compactMap { mention in
            guard self.length >= (mention.range.location + mention.range.length) else {
                log.error("Wrong mention: \(mention)")
                return nil
            }
            
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
            color = ColorScheme.default.color(named: .textForeground)
            if ColorScheme.default.variant == .dark {
                backgroundColor = ColorScheme.default.accentColor.withAlphaComponent(0.48)
            }
            else {
                backgroundColor = ColorScheme.default.accentColor.withAlphaComponent(0.16)
            }
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
        
        var atAttributes = [NSAttributedString.Key.font: atFont,
                            NSAttributedString.Key.foregroundColor: color,
                            NSAttributedString.Key.backgroundColor: backgroundColor]
        
        if !user.isSelfUser {
            atAttributes[NSAttributedString.Key.link] = link as NSObject
        }
        
        let atString = "@" && atAttributes
        
        var mentionAttributes = [NSAttributedString.Key.font: mentionFont,
                                 NSAttributedString.Key.foregroundColor: color,
                                 NSAttributedString.Key.backgroundColor: backgroundColor]
        
        if !user.isSelfUser {
            mentionAttributes[NSAttributedString.Key.link] = link as NSObject
        }
        
        let mentionText = name && mentionAttributes
        
        return atString + mentionText
    }
    
    func highlight(mentions: [MentionWithToken]) {
        
        let mutableString = self.mutableString
        
        mentions.forEach { mentionWithToken in
            let mentionRange = mutableString.range(of: mentionWithToken.token.value)
            
            guard mentionRange.location != NSNotFound else {
                log.error("Cannot process mention: \(mentionWithToken)")
                return
            }
            
            let currentFont = self.attributes(at: mentionRange.location, effectiveRange: nil)[.font] as? UIFont
            
            let replacementString = NSMutableAttributedString.mention(for: mentionWithToken.mention.user,
                                                                      name: mentionWithToken.token.name,
                                                                      link: mentionWithToken.mention.link,
                                                                      suggestedFontSize: currentFont?.pointSize)
            
            self.replaceCharacters(in: mentionRange, with: replacementString)
        }
    }
}
