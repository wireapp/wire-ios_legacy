// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import UIKit
import WireCommonComponents

extension UIView {
    func rotate(to angleInDegrees: CGFloat) {
        transform = transform.rotated(by: angleInDegrees / 180 * CGFloat.pi)
    }
}

typealias TapHandler = (_ collapsed: Bool) -> Void

final class ConversationListHeaderView: UICollectionReusableView {
    private let spacing: CGFloat = 8

    var folderBadge: Int = 0 {
        didSet {
            let isHidden = folderBadge <= 0

            badgeView.updateCollapseConstraints(isCollapsed: isHidden)
            badgeView.isHidden = isHidden
            badgeMarginConstraint?.constant = isHidden ? 0 : -spacing
            badgeWidthConstraint?.constant = isHidden ? 0 : 28

            let text: String?
            switch folderBadge {
            case 1...99:
                text = String(folderBadge)
            case 100...:
                text = "99+"
            default:
                text = nil
            }
            badgeView.textLabel.text = text
        }
    }

    var collapsed = false {
        didSet {
            guard collapsed != oldValue else { return }
            // update rotation

            if collapsed {
                arrowIconImageView.rotate(to: -90)
            } else {
                arrowIconImageView.transform = .identity
            }
        }
    }

    var tapHandler: TapHandler?

    private var badgeMarginConstraint: NSLayoutConstraint?
    private var badgeWidthConstraint: NSLayoutConstraint?

    private let titleLabel: UILabel = {
        let label = DynamicFontLabel(
            fontSpec: .smallRegularFont,
            color: .white)
        label.textColor = SemanticColors.Label.textConversationListCell
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    let badgeView: RoundedTextBadge = {
        let margin: CGFloat = 12
        let roundedTextBadge = RoundedTextBadge(contentInset: UIEdgeInsets(top: 2, left: margin, bottom: 2, right: margin), font: FontSpec(.medium, .semibold).font!)

        roundedTextBadge.textLabel.textColor = SemanticColors.Label.conversationListTableViewCellBadge
        roundedTextBadge.backgroundColor = SemanticColors.View.backgroundConversationListTableViewCellBadge
        roundedTextBadge.isHidden = true

        return roundedTextBadge
    }()

    /// display title of the header
    var title: String? {
        get {
            return titleLabel.text
        }

        set {
            titleLabel.text = newValue
        }
    }

    override var accessibilityLabel: String? {
        get {
            return title
        }

        set {
            super.accessibilityLabel = newValue
        }
    }

    override var accessibilityValue: String? {
        get {
            typealias ConversationListHeader = L10n.Accessibility.ConversationsListHeader

            let state = collapsed
                        ? ConversationListHeader.CollapsedButton.description
                        : ConversationListHeader.ExpandedButton.description
            return state + " \(folderBadge)"
        }

        set {
            super.accessibilityValue = newValue
        }
    }

    private let arrowIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = SemanticColors.Label.textConversationListCell
        imageView.setTemplateIcon(.downArrow, size: .tiny)
        return imageView
    }()

    required override init(frame: CGRect) {
        super.init(frame: frame)

        [titleLabel, arrowIconImageView, badgeView].forEach(addSubview)

        createConstraints()

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggledCollapsed)))

        isAccessibilityElement = true
        shouldGroupAccessibilityChildren = true
        backgroundColor = SemanticColors.View.backgroundConversationList
        addBorder(for: .bottom)
    }

    @objc
    private func toggledCollapsed() {
        let newCollaped = !collapsed

        UIView.animate(withDuration: 0.2, animations: {
            self.collapsed = newCollaped
             })
        tapHandler?(newCollaped)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        [arrowIconImageView, titleLabel].prepareForLayout()

        arrowIconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        badgeMarginConstraint = titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: badgeView.leadingAnchor, constant: 0)
        badgeWidthConstraint = badgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)

        NSLayoutConstraint.activate([
            arrowIconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat.ConversationList.horizontalMargin),
            arrowIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: arrowIconImageView.trailingAnchor, constant: spacing),

            badgeMarginConstraint!,
            badgeView.heightAnchor.constraint(equalToConstant: 20),
            badgeWidthConstraint!,
            badgeView.centerYAnchor.constraint(equalTo: centerYAnchor),
            badgeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CGFloat.ConversationList.horizontalMargin)
            ]
        )
    }
}
