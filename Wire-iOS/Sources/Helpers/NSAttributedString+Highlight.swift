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
    
    func containsCharacters(from characterSet: CharacterSet) -> Bool {
        return self.rangeOfCharacter(from: characterSet) != .none
    }
    
    func range(of strings: [String], options: CompareOptions, range: Range<String.Index>) -> Range<String.Index>? {
        return strings.flatMap {
                self.range(of: $0,
                           options: options,
                           range: range,
                           locale: nil)
            }.sorted { $0.lowerBound < $1.lowerBound }.first
    }
    
    static let ellipsis: String = "…"
}

extension NSString {
    func range(of strings: [String], options: NSString.CompareOptions, range: NSRange) -> NSRange {
        return strings.flatMap {
            self.range(of: $0,
                       options: options,
                       range: range,
                       locale: nil)
            }.sorted { $0.location < $1.location }.first ?? NSRange(location: NSNotFound, length: 0)
    }
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
        
        let rangeUntilFrom = NSRange(location: 0, length: from)
        let previousSpace = text.rangeOfCharacter(from: .whitespacesAndNewlines, options: [.backwards], range: rangeUntilFrom)
        
        // There is no prior whitespace
        if previousSpace.location == NSNotFound {
            return self.attributedSubstring(from: NSRange(location: from, length: self.length - from))
        }
        else {
            // Check if we accidentally jumped to the previous line
            let textSkipped = text.substring(with: NSRange(location: previousSpace.location + previousSpace.length, length:from - previousSpace.location))
            let skippedNewline = textSkipped.containsCharacters(from: .newlines)
            
            if skippedNewline {
                return self.attributedSubstring(from: NSRange(location: from, length: self.length - from))
            }
        }
        
        let rangeUntilPreviousSpace = NSRange(location: 0, length: previousSpace.location)
        var prePreviousSpace = text.rangeOfCharacter(from: .whitespacesAndNewlines, options: [.backwards], range: rangeUntilPreviousSpace)
        
        // There is no whitespace before the previousSpace
        if prePreviousSpace.location == NSNotFound {
            prePreviousSpace = previousSpace
        }
        else {
            // Check if we accidentally jumped to the previous line
            let textSkipped = text.substring(with: NSRange(location: prePreviousSpace.location + prePreviousSpace.length, length:from - prePreviousSpace.location))
            let preSkippedNewline = textSkipped.containsCharacters(from: .newlines)

            if preSkippedNewline {
                prePreviousSpace = previousSpace
            }
        }
        
        let rangeFromPrePreviousSpaceToFrom = NSRange(location: prePreviousSpace.location + prePreviousSpace.length,
                                                      length: from - (prePreviousSpace.location + prePreviousSpace.length))
        
        let textFromNextSpace = self.attributedSubstring(from: rangeFromPrePreviousSpaceToFrom)
        
        let textSize = textFromNextSpace.layoutSize()
        
        if textSize.width > fittingIntoWidth {
            return self.attributedSubstring(from: NSRange(location: from, length: self.length - from)).prefixedWithEllipsis()
        }
        else {
            let rangeFromPrePreviousSpaceToEnd = NSRange(location: prePreviousSpace.location + prePreviousSpace.length,
                                                         length: self.length - (prePreviousSpace.location + prePreviousSpace.length))
            
            return self.attributedSubstring(from: rangeFromPrePreviousSpaceToEnd).prefixedWithEllipsis()
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
    
    func highlightingAppearances(of query: [String], with attributes: [String: Any], totalMatches resultTotalMatches: inout Int, upToWidth: CGFloat?) -> NSAttributedString {
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
