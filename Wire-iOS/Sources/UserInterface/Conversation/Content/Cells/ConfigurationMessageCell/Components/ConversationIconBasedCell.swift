//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import UIKit
import TTTAttributedLabel

class ConversationIconBasedCell: UIView, TTTAttributedLabelDelegate {

    let imageContainer = UIView()
    let imageView = UIImageView()
    let textLabel = TTTAttributedLabel(frame: .zero)
    let lineView = UIView()

    let contentView = UIView()
    let labelFont: UIFont = .mediumFont

    private var containerWidthConstraint: NSLayoutConstraint!
    private var labelTrailingConstraint: NSLayoutConstraint!
    private var labelTopConstraint: NSLayoutConstraint!

    var isSelected: Bool = false

    var selectionView: UIView? {
        return textLabel
    }

    var selectionRect: CGRect {
        return textLabel.bounds
    }

    var attributedText: NSAttributedString? {
        didSet {
            textLabel.text = attributedText
            textLabel.accessibilityLabel = attributedText?.string
            textLabel.addLinks()
            
            let font = attributedText?.attributes(at: 0, effectiveRange: nil)[.font] as? UIFont
            if let lineHeight = font?.lineHeight {
                labelTopConstraint.constant = (32 - lineHeight) / 2
            } else {
                labelTopConstraint.constant = 0
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
        configureConstraints()
    }

    func configureSubviews() {
        imageView.contentMode = .center
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "Icon"

        textLabel.numberOfLines = 0
        textLabel.isAccessibilityElement = true
        textLabel.backgroundColor = .clear
        textLabel.font = labelFont

        textLabel.extendsLinkTouchArea = true

        textLabel.linkAttributes = [
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle().rawValue as NSNumber,
            NSAttributedString.Key.foregroundColor: ZMUser.selfUser().accentColor
        ]

        textLabel.delegate = self
        lineView.backgroundColor = .from(scheme: .separator)

        imageContainer.addSubview(imageView)
        addSubview(imageContainer)
        addSubview(textLabel)
        addSubview(contentView)
        addSubview(lineView)
    }

    func configureConstraints() {
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false

        containerWidthConstraint = imageContainer.widthAnchor.constraint(equalToConstant: UIView.conversationLayoutMargins.left)
        labelTrailingConstraint = textLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UIView.conversationLayoutMargins.right)
        labelTopConstraint = textLabel.topAnchor.constraint(equalTo: topAnchor)
        
        // We want the content view to at least be below the image container
        let contentViewTopConstraint = contentView.topAnchor.constraint(equalTo: imageContainer.bottomAnchor)
        contentViewTopConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            // imageContainer
            containerWidthConstraint,
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageContainer.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            imageContainer.heightAnchor.constraint(equalTo: imageView.heightAnchor),
            imageContainer.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: 0),

            // imageView
            imageView.widthAnchor.constraint(equalToConstant: 32),
            imageView.heightAnchor.constraint(equalToConstant: 32),
            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            
            // label
            textLabel.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            labelTopConstraint,
            labelTrailingConstraint,
        
            // lineView
            lineView.leadingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 16),
            lineView.heightAnchor.constraint(equalToConstant: .hairline),
            lineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            lineView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),

            // contentView
            contentView.leadingAnchor.constraint(equalTo: textLabel.leadingAnchor),
            contentView.topAnchor.constraint(greaterThanOrEqualTo: textLabel.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentViewTopConstraint
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        containerWidthConstraint.constant = UIView.conversationLayoutMargins.left
        labelTrailingConstraint.constant = -UIView.conversationLayoutMargins.right
    }

}
