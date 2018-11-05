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
    let leftIconView = UIImageView(frame: .zero)
    let leftIconContainer = UIView(frame: .zero)
    let lineView = UIView(frame: .zero)

    let labelView: UILabel
    
    var labelTextColor: UIColor? = .from(scheme: .textForeground)
    var labelTextBlendedColor: UIColor? = .from(scheme: .textDimmed)

    var lineBaseLineConstraint: NSLayoutConstraint?

    var attributedText: NSAttributedString? {
        didSet {
            labelView.attributedText = attributedText
            labelView.accessibilityLabel = attributedText?.string
            (labelView as? TTTAttributedLabel)?.addLinks()
        }
    }

    let labelFont: UIFont = .mediumFont

    let labelBoldFont: UIFont = .mediumSemiboldFont

    var verticalInset: CGFloat {
        return 16
    }

    private var lineMedianYOffset: CGFloat {
        return labelView is TTTAttributedLabel ? 2 : 0
    }

    class var userRegularLabel: Bool {
        return false
    }

    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        labelView = type(of: self).userRegularLabel ? UILabel(frame: .zero) : TTTAttributedLabel(frame: .zero)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.leftIconView.contentMode = .center
        self.leftIconView.isAccessibilityElement = true
        self.leftIconView.accessibilityLabel = "Icon"

        self.labelView.numberOfLines = 0
        self.labelView.isAccessibilityElement = true
        labelView.backgroundColor = .clear

        if let label = labelView as? TTTAttributedLabel {
            label.extendsLinkTouchArea = true

            label.linkAttributes = [
                NSAttributedString.Key.underlineStyle: NSUnderlineStyle().rawValue as NSNumber,
                NSAttributedString.Key.foregroundColor: ZMUser.selfUser().accentColor
            ]

            label.delegate = self
        }
        self.contentView.addSubview(self.leftIconContainer)
        self.leftIconContainer.addSubview(self.leftIconView)
        self.messageContentView.addSubview(self.labelView)
        self.contentView.addSubview(self.lineView)
        lineView.backgroundColor = .from(scheme: .separator)

        var accessibilityElements = self.accessibilityElements ?? []
        accessibilityElements.append(contentsOf: [self.labelView, self.leftIconView])
        self.accessibilityElements = accessibilityElements
    }
    
    private func createConstraints() {
        let labelViewTopInset: CGFloat = verticalInset + lineMedianYOffset
        
        constrain(self.leftIconContainer, self.leftIconView, self.labelView, self.messageContentView, self.authorLabel) { leftIconContainer, leftIconView, labelView, messageContentView, authorLabel in
            leftIconContainer.leading == messageContentView.leading
            leftIconContainer.trailing == authorLabel.leading
            leftIconContainer.bottom <= messageContentView.bottom
            leftIconContainer.height == leftIconView.height
            leftIconView.center == leftIconContainer.center
            leftIconView.height == 16
            leftIconView.height == leftIconView.width
            labelView.leading == leftIconContainer.trailing
            labelView.top == messageContentView.top + labelViewTopInset
            labelView.trailing <= messageContentView.trailing - 72
            labelView.bottom <= messageContentView.bottom - verticalInset
            messageContentView.height >= 32
        }

        createLineViewConstraints()
        createBaselineConstraint()
        updateLineBaseLineConstraint()
    }
    
    private func createLineViewConstraints() {
        constrain(self.lineView, self.contentView, self.labelView, self.messageContentView) { lineView, contentView, labelView, messageContentView in
            lineView.leading == labelView.trailing + 16
            lineView.height == .hairline
            lineView.trailing == contentView.trailing
        }
    }
    
    private func createBaselineConstraint() {
        constrain(lineView, labelView, leftIconContainer) { lineView, labelView, icon in
            lineBaseLineConstraint = lineView.centerY == labelView.top
            icon.centerY == lineView.centerY
        }
    }

    private func updateLineBaseLineConstraint() {
        lineBaseLineConstraint?.constant = labelFont.median - lineMedianYOffset
    }

    open override var canResignFirstResponder: Bool {
        get {
            return false
        }
    }
}


extension UIFont {

    var median: CGFloat {
        return ascender - (xHeight / 2)
    }

}
