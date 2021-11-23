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

class SenderNameCellComponent: UIView {

    let label = UILabel()
    let indicatorView = UIImageView()
    private var indicatorImageViewTrailing: NSLayoutConstraint!

    var senderName: String? {
        get { return label.text }
        set { label.text = newValue }
    }

    var indicatorIcon: UIImage? {
        get { return indicatorView.image }
        set { indicatorView.image = newValue }
    }

    var indicatorLabel: String? {
        get {
            return indicatorView.accessibilityLabel
        }
        set {
            indicatorView.accessibilityLabel = newValue
            indicatorView.isAccessibilityElement = newValue != nil
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func configureSubviews() {
        label.accessibilityIdentifier = "author.name"
        label.numberOfLines = 1
        addSubview(label)
        addSubview(indicatorView)
    }

    private func configureConstraints() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false

        indicatorImageViewTrailing = indicatorView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -conversationHorizontalMargins.right)

        NSLayoutConstraint.activate([
            // indicatorView
            indicatorImageViewTrailing,
            indicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),

            // label
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.trailingAnchor.constraint(equalTo: indicatorView.leadingAnchor, constant: -8)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        indicatorImageViewTrailing.constant = -conversationHorizontalMargins.right
    }

}
