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

struct TextMarker<A> {
    
    let replacementText: String
    let token: String
    let value: A
    
    init(_ value: A, replacementText: String) {
        self.value = value
        self.replacementText = replacementText
        self.token = UUID().transportString()
    }
}

extension TextMarker {
    
    func range(in string: String) -> Range<Int>? {
        return Range((string as NSString).range(of: token))
    }
    
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

extension NSMutableAttributedString {
    
    static private func mention(for user: UserType, name: String, link: URL, suggestedFontSize: CGFloat? = nil) -> NSAttributedString {
        let color: UIColor
        let backgroundColor: UIColor
        
        if user.isSelfUser {
            color = ColorScheme.default.color(named: .textForeground)
            if ColorScheme.default.variant == .dark {
                backgroundColor = UIColor.accent().withAlphaComponent(0.48)
            }
            else {
                backgroundColor = UIColor.accent().withAlphaComponent(0.16)
            }
        }
        else {
            color = .accent()
            backgroundColor = .clear
        }
        
        let fontSize = suggestedFontSize ?? UIFont.normalMediumFont.pointSize
        
        let atFont: UIFont = UIFont.systemFont(ofSize: fontSize - 2, contentSizeCategory: UIApplication.shared.preferredContentSizeCategory, weight: .light)
        let mentionFont: UIFont = UIFont.systemFont(ofSize: fontSize,
                                                    contentSizeCategory: UIApplication.shared.preferredContentSizeCategory,
                                                    weight: .semibold)
        
        var atAttributes: [NSAttributedString.Key: Any] = [.font: atFont,
                                                           .foregroundColor: color,
                                                           .backgroundColor: backgroundColor]
        
        if !user.isSelfUser {
            atAttributes[NSAttributedString.Key.link] = link as NSObject
        }
        
        let atString = "@" && atAttributes
        
        var mentionAttributes: [NSAttributedString.Key: Any] = [.font: mentionFont,
                                                                .foregroundColor: color,
                                                                .backgroundColor: backgroundColor]
        
        if !user.isSelfUser {
            mentionAttributes[NSAttributedString.Key.link] = link as NSObject
        }
        
        let mentionText = name && mentionAttributes
        
        return atString + mentionText
    }
    
    func highlight(mentions: [TextMarker<(Mention)>]) {
        
        let mutableString = self.mutableString
        
        mentions.forEach { textObject in
            let mentionRange = mutableString.range(of: textObject.token)
            
            guard mentionRange.location != NSNotFound else {
                log.error("Cannot process mention: \(textObject)")
                return
            }
            
            let currentFont = self.attributes(at: mentionRange.location, effectiveRange: nil)[.font] as? UIFont
            
            let replacementString = NSMutableAttributedString.mention(for: textObject.value.user,
                                                                      name: textObject.replacementText,
                                                                      link: textObject.value.link,
                                                                      suggestedFontSize: currentFont?.pointSize)
            
            self.replaceCharacters(in: mentionRange, with: replacementString)
        }
    }
}
