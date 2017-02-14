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

internal class SearchResultCountBadge: UIView {
    public var textLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(textLabel)
        
        textLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        textLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        
        constrain(self, textLabel) { selfView, textLabel in
            textLabel.leading == selfView.leading + 4
            textLabel.trailing == selfView.trailing - 4
            textLabel.top == selfView.top + 2
            textLabel.bottom == selfView.bottom - 2
            
            selfView.width >= selfView.height
        }
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = ceil(self.bounds.height / 2.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = ceil(self.bounds.height / 2.0)
    }
}

@objc internal class TextSearchResultCell: UITableViewCell, Reusable {
    fileprivate let messageTextLabel = UILabel()
    fileprivate let header = CollectionCellHeader()
    fileprivate let userImageViewContainer = UIView()
    fileprivate let userImageView = UserImageView(magicPrefix: "content.author_image")
    fileprivate let separatorView = UIView()
    fileprivate let resultCountView = SearchResultCountBadge()
    fileprivate var previousLayoutBounds: CGRect = .zero
    
    public var messageFont: UIFont? {
        didSet {
            self.updateTextView()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.header)
        
        self.messageTextLabel.accessibilityIdentifier = "text search result"
        self.messageTextLabel.numberOfLines = 1
        self.messageTextLabel.lineBreakMode = .byTruncatingTail
        
        self.contentView.addSubview(self.messageTextLabel)
        
        self.userImageViewContainer.addSubview(self.userImageView)
        
        self.contentView.addSubview(self.userImageViewContainer)
        
        self.separatorView.cas_styleClass = "separator"
        self.contentView.addSubview(self.separatorView)
        
        self.resultCountView.textLabel.accessibilityIdentifier = "count of matches"
        self.contentView.addSubview(self.resultCountView)
        
        constrain(self.userImageView, self.userImageViewContainer) { userImageView, userImageViewContainer in
            userImageView.height == 24
            userImageView.width == userImageView.height
            userImageView.center == userImageViewContainer.center
        }
        
        constrain(self.contentView, self.header, self.messageTextLabel, self.userImageViewContainer, self.resultCountView) { contentView, header, messageTextLabel, userImageViewContainer, resultCountView in
            userImageViewContainer.leading == contentView.leading
            userImageViewContainer.top == contentView.top
            userImageViewContainer.bottom == contentView.bottom
            userImageViewContainer.width == 48
            
            messageTextLabel.top == contentView.top + 8
            messageTextLabel.leading == userImageViewContainer.trailing
            messageTextLabel.trailing == resultCountView.leading - 16
            messageTextLabel.bottom == header.top - 8
            
            header.leading == userImageViewContainer.trailing
            header.trailing == contentView.trailing - 16
            header.bottom == contentView.bottom - 8
            
            resultCountView.trailing == contentView.trailing - 16
            resultCountView.centerY == messageTextLabel.centerY
        }
        
        constrain(self.contentView, self.separatorView, self.userImageViewContainer) { contentView, separatorView, userImageViewContainer in
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
        let queryComponents = query.components(separatedBy: .whitespacesAndNewlines)
        
        let currentRange = text.range(of: queryComponents,
                                      options: [.diacriticInsensitive, .caseInsensitive],
                                      range: text.startIndex..<text.endIndex)
        
        if let range = currentRange {
            let nsRange = text.nsRange(from: range)
            
            let highlightedAttributes = [NSFontAttributeName: font,
                                         NSBackgroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorAccentDarken)]
            
            var totalMatches: Int = 0
            
            if self.fits(attributedText: attributedText, fromRange: nsRange) {
                self.messageTextLabel.attributedText = attributedText.highlightingAppearances(of: queryComponents, with: highlightedAttributes, totalMatches: &totalMatches, upToWidth: messageTextLabel.bounds.width)
            }
            else {
                self.messageTextLabel.attributedText = attributedText.cutAndPrefixedWithEllipsis(from: nsRange.location, fittingIntoWidth: messageTextLabel.bounds.width)
                    .highlightingAppearances(of: queryComponents, with: highlightedAttributes, totalMatches: &totalMatches, upToWidth: messageTextLabel.bounds.width)
            }
            
            resultCountView.isHidden = totalMatches <= 1
            resultCountView.textLabel.text = "\(totalMatches)"
        }
        else {
            self.messageTextLabel.attributedText = attributedText
        }
    }
    
    fileprivate func fits(attributedText: NSAttributedString, fromRange: NSRange) -> Bool {
        let textCutToRange = attributedText.attributedSubstring(from: NSRange(location: 0, length: fromRange.location + fromRange.length))
        
        let labelSize = textCutToRange.layoutSize()
        
        return labelSize.height <= messageTextLabel.bounds.height && labelSize.width <= messageTextLabel.bounds.width
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
