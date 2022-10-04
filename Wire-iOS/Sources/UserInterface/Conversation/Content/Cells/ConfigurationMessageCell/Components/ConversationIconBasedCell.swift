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
import WireDataModel

class ConversationIconBasedCell: UIView {

    let imageContainer = UIView()
    let imageView = UIImageView()
    let textLabel = WebLinkTextView()
    let lineView = UIView()

    let topContentView = UIView()
    let bottomContentView = UIView()
    let labelFont: UIFont = .mediumFont

    private var containerWidthConstraint: NSLayoutConstraint!
    private var textLabelTrailingConstraint: NSLayoutConstraint!
    private var textLabelTopConstraint: NSLayoutConstraint!
    private var topContentViewTrailingConstraint: NSLayoutConstraint!

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected: Bool = false

    var selectionView: UIView? {
        return textLabel
    }

    var selectionRect: CGRect {
        return textLabel.bounds
    }

    var attributedText: NSAttributedString? {
        didSet {
            textLabel.attributedText = attributedText
            textLabel.accessibilityLabel = attributedText?.string

            let font = attributedText?.attributes(at: 0, effectiveRange: nil)[.font] as? UIFont
            if let lineHeight = font?.lineHeight {
                textLabelTopConstraint.constant = (32 - lineHeight) / 2
            } else {
                textLabelTopConstraint.constant = 0
            }
        }
    }

    private var trailingTextMargin: CGFloat {
        return -conversationHorizontalMargins.right * 2
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    func configureSubviews() {
        imageView.contentMode = .center
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "Icon"

        textLabel.isAccessibilityElement = true
        textLabel.backgroundColor = .clear
        textLabel.font = labelFont
        textLabel.delegate = self

        textLabel.linkTextAttributes = [
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle().rawValue as NSNumber,
            NSAttributedString.Key.foregroundColor: SelfUser.provider?.selfUser.accentColor ?? UIColor.accent()
        ]

        lineView.backgroundColor = SemanticColors.View.backgroundSeparatorConversationView

        imageContainer.addSubview(imageView)
        addSubview(imageContainer)
        addSubview(textLabel)
        addSubview(topContentView)
        addSubview(bottomContentView)
        addSubview(lineView)
    }

    func configureConstraints() {
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        topContentView.translatesAutoresizingMaskIntoConstraints = false
        bottomContentView.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false

        topContentViewTrailingConstraint = topContentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: trailingTextMargin)
        containerWidthConstraint = imageContainer.widthAnchor.constraint(equalToConstant: conversationHorizontalMargins.left)
        textLabelTrailingConstraint = textLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: trailingTextMargin)
        textLabelTopConstraint = textLabel.topAnchor.constraint(equalTo: topContentView.bottomAnchor)

        // We want the content view to at least be below the image container
        let contentViewTopConstraint = bottomContentView.topAnchor.constraint(equalTo: imageContainer.bottomAnchor)
        contentViewTopConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            // imageContainer
            containerWidthConstraint,
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageContainer.topAnchor.constraint(equalTo: topContentView.bottomAnchor, constant: 0),
            imageContainer.heightAnchor.constraint(equalTo: imageView.heightAnchor),
            imageContainer.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: 0),

            // imageView
            imageView.widthAnchor.constraint(equalToConstant: 32),
            imageView.heightAnchor.constraint(equalToConstant: 32),
            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),

            // topContentView
            topContentView.topAnchor.constraint(equalTo: topAnchor),
            topContentView.leadingAnchor.constraint(equalTo: textLabel.leadingAnchor),
            topContentViewTrailingConstraint,

            // textLabel
            textLabel.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            textLabelTopConstraint,
            textLabelTrailingConstraint,

            // lineView
            lineView.leadingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 16),
            lineView.heightAnchor.constraint(equalToConstant: .hairline),
            lineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            lineView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),

            // bottomContentView
            bottomContentView.leadingAnchor.constraint(equalTo: textLabel.leadingAnchor),
            bottomContentView.topAnchor.constraint(greaterThanOrEqualTo: textLabel.bottomAnchor),
            bottomContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentViewTopConstraint
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        containerWidthConstraint.constant = conversationHorizontalMargins.left
        textLabelTrailingConstraint.constant = trailingTextMargin
        topContentViewTrailingConstraint.constant = trailingTextMargin
    }

}

extension ConversationIconBasedCell: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // Fixes Swift 5.0 release build child class overridden method not called bug
        return false
    }
}
