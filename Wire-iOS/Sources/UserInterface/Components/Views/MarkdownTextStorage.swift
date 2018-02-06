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

class MarkdownTextStorage: NSTextStorage {
    
    private let storage = NSTextStorage()
    
    override var string: String { return storage.string }
    
    var currentMarkdown: Markdown = .none
    private var needsUpdate: Bool = false
    
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [String : Any] {
        return storage.attributes(at: location, effectiveRange: range)
    }
    
    override func setAttributes(_ attrs: [String : Any]?, range: NSRange) {
        beginEditing()
        storage.setAttributes(attrs, range: range)
        
        // this is a workaround for the case where the markdown id is not included
        // in attrs after autocorrect or automatic fullstop insertions. We only
        // update immediately text has changed and the attributes are missing
        // the markdown id.
        if  needsUpdate,
            let attrs = attrs,
            attrs[MarkdownIDAttributeName] == nil
        {
            storage.addAttribute(MarkdownIDAttributeName, value: currentMarkdown, range: editedRange)
            edited(.editedAttributes, range: editedRange, changeInLength: 0)
            needsUpdate = false
        }
        
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        storage.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
        endEditing()
        // this method is called when the os enters text automatically
        // (for autocorrect or fullstops), in this case we need to make
        // sure the markdown id attribute is added.
        needsUpdate = true
    }
}
