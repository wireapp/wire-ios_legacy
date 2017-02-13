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
import Cartography

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
    
    func prefixWithEllipsis(from: Int, fittingIntoWidth: CGFloat) -> NSAttributedString {
        let text = self.string as NSString
        
        let nextSpace = text.rangeOfCharacter(from: .whitespacesAndNewlines, options: [.backwards], range: NSRange(location: 0, length: from))
        
        // There is no prior whitespace
        if nextSpace.location == NSNotFound {
            return self.attributedSubstring(from: NSRange(location: from, length: self.length - from))
        }
        
        let textFromNextSpace = self.attributedSubstring(from: NSRange(location: nextSpace.location + nextSpace.length, length: from - (nextSpace.location + nextSpace.length)))
        
        let textSize = textFromNextSpace.layoutSize()
        
        if textSize.width > fittingIntoWidth {
            return self.attributedSubstring(from: NSRange(location: from, length: self.length - from)).prefixWithEllipsis()
        }
        else {
            return self.attributedSubstring(from: NSRange(location: nextSpace.location + nextSpace.length, length: self.length - (nextSpace.location + nextSpace.length))).prefixWithEllipsis()
        }
    }
    
    func prefixWithEllipsis() -> NSAttributedString {
        guard !self.string.isEmpty else {
            return self
        }
        
        var attributes = self.attributes(at: 0, effectiveRange: .none)
        attributes[NSBackgroundColorAttributeName] = .none
        
        let ellipsisString = NSAttributedString(string: String.ellipsis, attributes: attributes)
        return ellipsisString + self
    }
}

@objc internal class TextSearchResultCell: UITableViewCell, Reusable {
    fileprivate let messageTextLabel = UILabel()
    fileprivate let header = CollectionCellHeader()
    fileprivate let userImageViewContainer = UIView()
    fileprivate let userImageView = UserImageView(magicPrefix: "content.author_image")
    fileprivate let separatorView = UIView()
    fileprivate let resultCountView = UILabel()
    fileprivate var previousLayoutBounds: CGRect = .zero
    
    public var messageFont: UIFont? {
        didSet {
            self.updateTextView()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.header)
        
        self.messageTextLabel.numberOfLines = 1
        self.messageTextLabel.lineBreakMode = .byTruncatingTail
        
        self.contentView.addSubview(self.messageTextLabel)
        
        self.userImageViewContainer.addSubview(self.userImageView)
        
        self.contentView.addSubview(self.userImageViewContainer)
        
        self.separatorView.cas_styleClass = "separator"
        self.contentView.addSubview(self.separatorView)
        
        constrain(self.userImageView, self.userImageViewContainer) { userImageView, userImageViewContainer in
            userImageView.height == 24
            userImageView.width == userImageView.height
            userImageView.center == userImageViewContainer.center
        }
        
        constrain(self.contentView, self.header, self.messageTextLabel, self.userImageViewContainer, self.separatorView) { contentView, header, messageTextLabel, userImageViewContainer, separatorView in
            userImageViewContainer.leading == contentView.leading
            userImageViewContainer.top == contentView.top
            userImageViewContainer.bottom == contentView.bottom
            userImageViewContainer.width == 48
            
            messageTextLabel.top == contentView.top + 8
            messageTextLabel.leading == userImageViewContainer.trailing
            messageTextLabel.trailing == contentView.trailing - 24
            messageTextLabel.bottom == header.top - 8
            
            header.leading == userImageViewContainer.trailing
            header.trailing == contentView.trailing - 24
            header.bottom == contentView.bottom - 8
            
            separatorView.leading == userImageViewContainer.trailing
            separatorView.trailing == contentView.trailing
            separatorView.bottom == contentView.bottom
            separatorView.height == CGFloat.hairline
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.message = .none
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard !self.bounds.equalTo(self.previousLayoutBounds) else {
            return
        }
        
        self.previousLayoutBounds = self.bounds
        
        self.updateTextView()
    }
    
    private func updateTextView() {
        
        guard !self.bounds.equalTo(CGRect.zero),
            let text = message?.textMessageData?.messageText,
            let query = self.query,
            let font = self.messageFont else {
                self.messageTextLabel.attributedText = .none
                return
        }
        
        let attributedText = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: font])
        
        let currentRange = text.range(of: query,
                                      options: [.diacriticInsensitive, .caseInsensitive],
                                      range: text.startIndex..<text.endIndex,
                                      locale: nil)
        
        if let range = currentRange {
            let nsRange = text.nsRange(from: range)
            
            attributedText.setAttributes([NSFontAttributeName: font,
                                          NSBackgroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorAccentDarken)],
                                         range: nsRange)
            if self.fits(attributedText: attributedText, fromRange: nsRange) {
                self.messageTextLabel.attributedText = attributedText
            }
            else {
                self.messageTextLabel.attributedText = attributedText.prefixWithEllipsis(from: nsRange.location, fittingIntoWidth: messageTextLabel.bounds.width)
            }
        }
    }
    
    fileprivate func fits(attributedText: NSAttributedString, fromRange: NSRange) -> Bool {
        let textCutToRange = attributedText.attributedSubstring(from: NSRange(location: 0, length: fromRange.location + fromRange.length))
        
        let labelSize = textCutToRange.layoutSize()
        
        return labelSize.width <= messageTextLabel.bounds.width
    }
    
    var message: ZMConversationMessage? = .none {
        didSet {
            self.updateTextView()
            self.header.message = self.message
            self.userImageView.user = self.message?.sender
        }
    }
    
    var query: String? = .none {
        didSet {
            self.updateTextView()
        }
    }
}
