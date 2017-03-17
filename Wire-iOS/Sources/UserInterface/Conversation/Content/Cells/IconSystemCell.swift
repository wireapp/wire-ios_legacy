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
import Classy

// Class for the new system message that is having a following design with icon, text and separator line:
// <Icon> Lorem ipsum system message ----
//        by user A, B, C

open class IconSystemCell: ConversationCell, TTTAttributedLabelDelegate {
    let leftIconView = UIImageView(frame: .zero)
    let leftIconContainer = UIView(frame: .zero)
    let labelView = TTTAttributedLabel(frame: .zero)
    let lineView = UIView(frame: .zero)
    
    var labelTextColor: UIColor?
    var labelTextBlendedColor: UIColor?
    var labelFont: UIFont?
    var labelBoldFont: UIFont?

    var verticalInset: CGFloat {
        return 16
    }

    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupViews()
        CASStyler.default().styleItem(self)
        createConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.leftIconView.contentMode = .center
        self.leftIconView.isAccessibilityElement = true
        self.leftIconView.accessibilityLabel = "Icon"

        self.labelView.extendsLinkTouchArea = true
        self.labelView.numberOfLines = 0
        self.labelView.isAccessibilityElement = true
        self.labelView.accessibilityLabel = "Text"
        self.labelView.linkAttributes = [
            NSUnderlineStyleAttributeName: NSUnderlineStyle.styleNone.rawValue,
            NSForegroundColorAttributeName: ZMUser.selfUser().accentColor
        ]

        self.labelView.delegate = self
        self.contentView.addSubview(self.leftIconContainer)
        self.leftIconContainer.addSubview(self.leftIconView)
        self.messageContentView.addSubview(self.labelView)
        self.contentView.addSubview(self.lineView)

        var accessibilityElements = self.accessibilityElements ?? []
        accessibilityElements.append(contentsOf: [self.labelView, self.leftIconView])
        self.accessibilityElements = accessibilityElements
    }
    
    private func createConstraints() {
        constrain(self.leftIconContainer, self.leftIconView, self.labelView, self.messageContentView, self.authorLabel) { (leftIconContainer: LayoutProxy, leftIconView: LayoutProxy, labelView: LayoutProxy, messageContentView: LayoutProxy, authorLabel: LayoutProxy) -> () in
            leftIconContainer.leading == messageContentView.leading
            leftIconContainer.trailing == authorLabel.leading
            leftIconContainer.top == messageContentView.top + verticalInset
            leftIconContainer.bottom <= messageContentView.bottom
            leftIconContainer.height == leftIconView.height
            leftIconView.center == leftIconContainer.center
            leftIconView.height == 16
            leftIconView.height == leftIconView.width
            labelView.leading == leftIconContainer.trailing
            labelView.top == messageContentView.top + verticalInset + 3
            labelView.trailing <= messageContentView.trailing - 72
            labelView.bottom <= messageContentView.bottom - verticalInset
            messageContentView.height >= 32
        }

        constrain(self.lineView, self.contentView, self.labelView, self.messageContentView) { (lineView: LayoutProxy, contentView: LayoutProxy, labelView: LayoutProxy, messageContentView: LayoutProxy) -> () in
            lineView.leading == labelView.trailing + 16
            lineView.height == .hairline
            lineView.trailing == contentView.trailing
            lineView.top == messageContentView.top + verticalInset + 8
        }
    }

    open override var canResignFirstResponder: Bool {
        get {
            return false
        }
    }
}
