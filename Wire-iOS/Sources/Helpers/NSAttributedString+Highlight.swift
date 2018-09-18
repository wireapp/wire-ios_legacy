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
        return NSRange(range, in: self)
    }
    
    func containsCharacters(from characterSet: CharacterSet) -> Bool {
        return self.rangeOfCharacter(from: characterSet) != .none
    }
    
    func range(of strings: [String], options: CompareOptions = [], range: Range<String.Index>? = .none) -> Range<String.Index>? {
        return strings.compactMap {
                self.range(of: $0,
                           options: options,
                           range: range,
                           locale: nil)
            }.sorted { $0.lowerBound < $1.lowerBound }.first
    }
    
    static let ellipsis: String = "…"
}

extension NSString {
    func range(of strings: [String], options: NSString.CompareOptions = [], range: NSRange? = .none) -> NSRange {
        let queryRange = range ?? NSRange(location: 0, length: self.length)

        return strings.compactMap {
            self.range(of: $0,
                       options: options,
                       range: queryRange,
                       locale: nil)
            }.sorted { $0.location < $1.location }.first ?? NSRange(location: NSNotFound, length: 0)
    }
    
    func allRanges(of strings: [String], options: NSString.CompareOptions = [], range: NSRange? = .none) -> [String: [NSRange]] {
        let initialQueryRange = range ?? NSRange(location: 0, length: self.length)
        var result = [String: [NSRange]]()
        
        for query in strings {
            var queryRange = initialQueryRange
            var currentRange: NSRange = NSMakeRange(NSNotFound, 0)
        
            var queryResult = [NSRange]()
            
            repeat {
                currentRange = self.range(of: query, options: [.caseInsensitive, .diacriticInsensitive], range: queryRange)
                if currentRange.location != NSNotFound {
                    queryRange.location = currentRange.location + currentRange.length
                    queryRange.length = self.length - queryRange.location
                    
                    queryResult.append(currentRange)
                }
            }
            while currentRange.location != NSNotFound
            if queryResult.count > 0 {
                result[query] = queryResult
            }
        }
        
        return result
    }
}

extension NSAttributedString {
    func layoutSize() -> CGSize {
        let framesetter = CTFramesetterCreateWithAttributedString(self)
        let targetSize = CGSize(width: 10000, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.length), nil, targetSize, nil)
        
        return labelSize
    }
    
    // This method cuts the prefix from `self` up to the beginning of the word prior to the word on position @c from.
    // The result is then prefixed with ellipsis of the same style as the beginning of the string.
    func cutAndPrefixedWithEllipsis(from: Int, fittingIntoWidth: CGFloat) -> NSAttributedString {
        let text = self.string as NSString
        
        let rangeUntilFrom = NSRange(location: 0, length: from)
        let previousSpace = text.rangeOfCharacter(from: .whitespacesAndNewlines, options: [.backwards], range: rangeUntilFrom)
        
        // There is no prior whitespace
        if previousSpace.location == NSNotFound {
            return self.attributedSubstring(from: NSRange(location: from, length: self.length - from)).prefixedWithEllipsis()
        }
        else {
            // Check if we accidentally jumped to the previous line
            let textSkipped = text.substring(with: NSRange(location: previousSpace.location + previousSpace.length, length:from - previousSpace.location))
            let skippedNewline = textSkipped.containsCharacters(from: .newlines)
            
            if skippedNewline {
                return self.attributedSubstring(from: NSRange(location: from, length: self.length - from)).prefixedWithEllipsis()
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
    
    private func prefixedWithEllipsis() -> NSAttributedString {
        guard !self.string.isEmpty else {
            return self
        }
        
        var attributes = self.attributes(at: 0, effectiveRange: .none)
        attributes[.backgroundColor] = .none
        
        let ellipsisString = NSAttributedString(string: String.ellipsis, attributes: attributes)
        return ellipsisString + self
    }
    
    @objc func highlightingAppearances(of query: [String],
                                       with attributes: [NSAttributedString.Key: Any],
                                       upToWidth: CGFloat,
                                       totalMatches: UnsafeMutablePointer<Int>?) -> NSAttributedString {
        
        let attributedText = self.mutableCopy() as! NSMutableAttributedString
        
        let allRanges = (self.string as NSString).allRanges(of: query, options: [.caseInsensitive, .diacriticInsensitive])
        
        if let totalMatches = totalMatches {
            totalMatches.pointee = allRanges.map { $1.count }.reduce(0, +)
        }
        
        for (_, results) in allRanges {
            for currentRange in results {
                let substring = self.attributedSubstring(from: NSRange(location: 0, length: currentRange.location + currentRange.length))

                if upToWidth == 0 || substring.layoutSize().width < upToWidth {
                    attributedText.addAttributes(attributes, range: currentRange)
                }
                else {
                    break
                }
            }
        }
        
        return NSAttributedString(attributedString: attributedText)
    }
}
