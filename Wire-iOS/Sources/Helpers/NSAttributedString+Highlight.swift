//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension String {
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let from = range.lowerBound.samePosition(in: utf16)
        let to = range.upperBound.samePosition(in: utf16)
        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                       length: utf16.distance(from: from, to: to))
    }
    
    static let ellipsis: String = "…"
}

extension NSAttributedString {
    func layoutSize() -> CGSize {
        let framesetter = CTFramesetterCreateWithAttributedString(self)
        let targetSize = CGSize(width: 10000, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.length), nil, targetSize, nil)
        
        return labelSize
    }
    
    func cutAndPrefixedWithEllipsis(from: Int, fittingIntoWidth: CGFloat) -> NSAttributedString {
        let text = self.string as NSString
        
        let nextSpace = text.rangeOfCharacter(from: .whitespacesAndNewlines, options: [.backwards], range: NSRange(location: 0, length: from))
        
        // There is no prior whitespace
        if nextSpace.location == NSNotFound {
            return self.attributedSubstring(from: NSRange(location: from, length: self.length - from))
        }
        
        let textFromNextSpace = self.attributedSubstring(from: NSRange(location: nextSpace.location + nextSpace.length, length: from - (nextSpace.location + nextSpace.length)))
        
        let textSize = textFromNextSpace.layoutSize()
        
        if textSize.width > fittingIntoWidth {
            return self.attributedSubstring(from: NSRange(location: from, length: self.length - from)).prefixedWithEllipsis()
        }
        else {
            return self.attributedSubstring(from: NSRange(location: nextSpace.location + nextSpace.length, length: self.length - (nextSpace.location + nextSpace.length))).prefixedWithEllipsis()
        }
    }
    
    func prefixedWithEllipsis() -> NSAttributedString {
        guard !self.string.isEmpty else {
            return self
        }
        
        var attributes = self.attributes(at: 0, effectiveRange: .none)
        attributes[NSBackgroundColorAttributeName] = .none
        
        let ellipsisString = NSAttributedString(string: String.ellipsis, attributes: attributes)
        return ellipsisString + self
    }
    
    func highlightingAppearances(of query: String, with attributes: [String: Any], totalMatches resultTotalMatches: inout Int, upToWidth: CGFloat?) -> NSAttributedString {
        let attributedText = self.mutableCopy() as! NSMutableAttributedString
        
        let textString = self.string as NSString
        var queryRange = NSMakeRange(0, textString.length)
        var currentRange: NSRange = NSMakeRange(NSNotFound, 0)
        
        var totalMatches: Int = 0
        
        repeat {
            currentRange = textString.range(of: query, options: [.caseInsensitive, .diacriticInsensitive], range: queryRange)
            if currentRange.location != NSNotFound {
                queryRange.location = currentRange.location + currentRange.length
                queryRange.length = textString.length - queryRange.location
                
                let substring = self.attributedSubstring(from: NSRange(location: 0, length: currentRange.location + currentRange.length))
                
                if upToWidth == nil || substring.layoutSize().width < upToWidth {
                    attributedText.setAttributes(attributes, range: currentRange)
                }
                
                totalMatches = totalMatches + 1
            }
        }
            while currentRange.location != NSNotFound
        
        resultTotalMatches = totalMatches
        
        return NSAttributedString(attributedString: attributedText)
    }
}
