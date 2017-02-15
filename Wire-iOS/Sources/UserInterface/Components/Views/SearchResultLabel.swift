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

@objc final public class SearchResultLabel: UILabel, Copyable {
    public convenience init(instance: SearchResultLabel) {
        self.init()
        self.font = instance.font
        self.textColor = instance.textColor
        self.resultText = instance.resultText
        self.query = instance.query
    }

    public var resultText: String? = .none {
        didSet {
            self.updateText()
        }
    }
    
    public var query: String? = .none {
        didSet {
            self.updateText()
        }
    }
    
    public override var font: UIFont! {
        didSet {
            self.updateText()
        }
    }
    
    public override var textColor: UIColor! {
        didSet {
            self.updateText()
        }
    }
    
    public var estimatedMatchesCount: Int = 0
    
    fileprivate var previousLayoutBounds: CGRect = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.lineBreakMode = .byTruncatingTail
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatal("init?(coder:) is not implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard !self.bounds.equalTo(self.previousLayoutBounds) else {
            return
        }
        
        self.previousLayoutBounds = self.bounds
        
        self.updateText()
    }
    
    private func updateText() {
        guard let text = self.resultText,
              let query = self.query,
              let font = self.font,
              let color = self.textColor else {
                self.attributedText = .none
                return
        }
        
        let attributedText = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: color])
        let queryComponents = query.components(separatedBy: .whitespacesAndNewlines)
        
        let currentRange = text.range(of: queryComponents,
                                      options: [.diacriticInsensitive, .caseInsensitive])
        
        if let range = currentRange {
            let nsRange = text.nsRange(from: range)
            
            let highlightedAttributes = [NSFontAttributeName: font,
                                         NSBackgroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorAccentDarken)]
            
            if self.fits(attributedText: attributedText, fromRange: nsRange) {
                self.attributedText = attributedText.highlightingAppearances(of: queryComponents,
                                                                             with: highlightedAttributes,
                                                                             upToWidth: self.bounds.width,
                                                                             totalMatches: &estimatedMatchesCount)
            }
            else {
                self.attributedText = attributedText.cutAndPrefixedWithEllipsis(from: nsRange.location, fittingIntoWidth: self.bounds.width)
                    .highlightingAppearances(of: queryComponents,
                                             with: highlightedAttributes,
                                             upToWidth: self.bounds.width,
                                             totalMatches: &estimatedMatchesCount)
            }
        }
        else {
            self.attributedText = attributedText
        }
    }
    
    fileprivate func fits(attributedText: NSAttributedString, fromRange: NSRange) -> Bool {
        let textCutToRange = attributedText.attributedSubstring(from: NSRange(location: 0, length: fromRange.location + fromRange.length))
        
        let labelSize = textCutToRange.layoutSize()
        
        return labelSize.height <= self.bounds.height && labelSize.width <= self.bounds.width
    }
}
