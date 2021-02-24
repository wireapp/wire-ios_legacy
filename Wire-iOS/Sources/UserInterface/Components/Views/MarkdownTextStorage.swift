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
import UIKit
import Down

extension NSAttributedString.Key {
    public static let markdownID = NSAttributedString.Key(rawValue: "MarkdownIDAttributeName")
}

class MarkdownTextStorage: NSTextStorage {
    
    private let storage = NSTextStorage()
    
    override var string: String { return storage.string }
    
    var currentMarkdown: Markdown = .none
    private var needsCheck: Bool = false
    
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        return storage.attributes(at: location, effectiveRange: range)
    }
    
    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        storage.setAttributes(attrs, range: range)
        
        // This is a workaround for the case where the markdown id is missing
        // after automatically inserts corrections or fullstops after a space.
        // If the needsCheck flag is set (after characters are replaced) & the
        // attrs is missing the markdown id, then we need to included it.
        if  needsCheck, let attrs = attrs, attrs[NSAttributedString.Key.markdownID] == nil {
            needsCheck = false
            storage.addAttribute(NSAttributedString.Key.markdownID, value: currentMarkdown, range: range)
        }
        
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    override func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        beginEditing()
        storage.addAttributes(attrs, range: range)
        
        // This is a workaround for the case where the markdown id is missing
        // after automatically inserts corrections or fullstops after a space.
        // If the needsCheck flag is set (after characters are replaced) & the
        // attrs is missing the markdown id, then we need to included it.
        if  needsCheck, attrs[NSAttributedString.Key.markdownID] == nil {
            needsCheck = false
            storage.addAttribute(NSAttributedString.Key.markdownID, value: currentMarkdown, range: range)
        }
        
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        storage.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
        endEditing()
        
        // see setAttributes(_ :range:)
        needsCheck = true
    }
}
