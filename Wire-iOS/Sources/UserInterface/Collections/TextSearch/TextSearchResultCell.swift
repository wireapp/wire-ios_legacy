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

@objc internal class TextSearchResultCell: UITableViewCell, Reusable {
    fileprivate let textView = UITextView()
    fileprivate let header = CollectionCellHeader()
    
    public var messageFont: UIFont? {
        didSet {
            self.updateTextView()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.header)
        
        self.textView.isEditable = false
        self.textView.isSelectable = false
        self.textView.isScrollEnabled = false
        self.textView.textContainerInset = .zero
        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.isUserInteractionEnabled = false
        
        self.contentView.addSubview(self.textView)
        
        constrain(self.contentView, self.header, self.textView) { contentView, header, textView in
            header.top == contentView.top + 8
            header.leading == contentView.leading + 24
            header.trailing == contentView.trailing - 24
            
            textView.top == header.bottom
            textView.leading == contentView.leading + 24
            textView.trailing == contentView.trailing - 24
            textView.bottom == contentView.bottom
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.message = .none
    }
    
    private func updateTextView() {
        guard let text = message?.textMessageData?.messageText,
            let query = self.query,
            let font = self.messageFont else {
                self.textView.attributedText = .none
                return
        }
        
        
        let attributedText = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: font])
        
        let textString = text as NSString
        var queryRange = NSMakeRange(0, textString.length)
        var currentRange: NSRange = NSMakeRange(NSNotFound, 0)
        
        repeat {
            currentRange = textString.range(of: query, options: .caseInsensitive, range: queryRange)
            if currentRange.location != NSNotFound {
                queryRange.location = currentRange.location + currentRange.length
                queryRange.length = textString.length - queryRange.location
                attributedText.setAttributes([NSFontAttributeName: font,
                                              NSBackgroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorAccentDarken)], range: currentRange)
            }
        }
        while currentRange.location != NSNotFound
        
        self.textView.attributedText = attributedText
        self.textView.layoutIfNeeded()
    }
    
    var message: ZMConversationMessage? = .none {
        didSet {
            self.updateTextView()
            self.header.message = self.message
        }
    }
    
    var query: String? = .none {
        didSet {
            self.updateTextView()
        }
    }
}
