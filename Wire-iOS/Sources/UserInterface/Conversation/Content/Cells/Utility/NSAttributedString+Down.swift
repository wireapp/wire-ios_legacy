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
import Down

extension NSMutableAttributedString {
    @objc
    static func markdown(from text: String, style: DownStyle) -> NSMutableAttributedString {
        let down = Down(markdownString: text)
        let result: NSMutableAttributedString
        
        if let attrStr = try? down.toAttributedString(using: style) {
            result = NSMutableAttributedString(attributedString: attrStr)
        } else {
            result = NSMutableAttributedString(string: text)
        }
        
        if result.string.last == "\n" {
            result.deleteCharacters(in: NSMakeRange(result.length - 1, 1))
        }
        
        return result
    }
    
    /**
     * Parses the markdown and adding the @-mentions highlights.
     * The logic is the following:
     * 1. Replace @-mention ranges with UUID strings.
     * 2. Process markdown styling.
     * 3. Replace UUID with mentions.
     * This is necessary, since markdown parsing might change the string length.
     * @param userSource is used to find the user's names
     */
    @objc
    static func markdown(from text: String,
                         style: DownStyle,
                         mentions: [Mention]) -> NSMutableAttributedString {
        
        let mutableText = NSMutableString(string: text)
        let mentionsWithTokens = mutableText.replaceMentions(mentions)
        let parsedMarkdown = self.markdown(from: mutableText as String, style: style)
        parsedMarkdown.highlight(mentions: mentionsWithTokens)
        
        return parsedMarkdown
    }
}
