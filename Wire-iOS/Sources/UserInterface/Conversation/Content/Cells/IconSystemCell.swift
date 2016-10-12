//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import TTTAttributedLabel

// Class for the new system message that is having a following design with icon, text and separator line:
// <Icon> Lorem ipsum system message ----
//        by user A, B, C

open class IconSystemCell: ConversationCell, TTTAttributedLabelDelegate {
    var leftIconView: UIImageView!
    var leftIconContainer: UIView!
    var labelView: TTTAttributedLabel!
    var lineView: UIView!
    
    var labelTextColor: UIColor?
    var labelTextBlendedColor: UIColor?
    var labelFont: UIFont?
    var labelBoldFont: UIFont?
    
    var initialIconConstraintsCreated: Bool

    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.initialIconConstraintsCreated = false
        
        self.leftIconView = UIImageView(frame: CGRect.zero)
        self.leftIconView.contentMode = .center
        self.leftIconView.isAccessibilityElement = true
        self.leftIconView.accessibilityLabel = "Icon"
        
        self.labelView = TTTAttributedLabel(frame: CGRect.zero)
        self.labelView.extendsLinkTouchArea = true
        self.labelView.numberOfLines = 0
        self.labelView.isAccessibilityElement = true
        self.labelView.accessibilityLabel = "Text"
        self.labelView.linkAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleNone.rawValue,
                                        NSForegroundColorAttributeName: ZMUser.selfUser().accentColor]
        
        self.lineView = UIView(frame: CGRect.zero)
        self.leftIconContainer = UIView(frame: CGRect.zero)
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.labelView.delegate = self
        self.contentView.addSubview(self.leftIconContainer)
        self.leftIconContainer.addSubview(self.leftIconView)
        self.messageContentView.addSubview(self.labelView)
        self.contentView.addSubview(self.lineView)
        
        var accessibilityElements = self.accessibilityElements ?? []
        accessibilityElements.append(contentsOf: [self.labelView, self.leftIconView])
        self.accessibilityElements = accessibilityElements
        
        CASStyler.default().styleItem(self)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func updateConstraints() {
        if !self.initialIconConstraintsCreated {
            
            let inset: CGFloat = 16
            constrain(self.leftIconContainer, self.leftIconView, self.labelView, self.messageContentView, self.authorLabel) { leftIconContainer, leftIconView, labelView, messageContentView, authorLabel in
                leftIconContainer.left == messageContentView.left
                leftIconContainer.right == authorLabel.left
                leftIconContainer.top == messageContentView.top + inset
                leftIconContainer.bottom <= messageContentView.bottom
                leftIconContainer.height == leftIconView.height
                leftIconView.center == leftIconContainer.center
                leftIconView.height == 16
                leftIconView.height == leftIconView.width
                labelView.left == leftIconContainer.right
                labelView.top == messageContentView.top + inset + 2
                labelView.right <= messageContentView.right - 72
                labelView.bottom <= messageContentView.bottom - inset
                messageContentView.height >= 32
            }
            
            constrain(self.lineView, self.contentView, self.labelView, self.messageContentView) { lineView, contentView, labelView, messageContentView in
                lineView.left == labelView.right + 16
                lineView.height == 0.5
                lineView.right == contentView.right
                lineView.top == messageContentView.top + inset + 8
            }
            
            self.initialIconConstraintsCreated = true
        }
        super.updateConstraints()
    }
    
    open override var canResignFirstResponder: Bool {
        get {
            return false
        }
    }
}
