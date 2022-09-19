//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireCommonComponents

final class SettingsLinkTableCell: SettingsTableCellProtocol {

    // MARK: - Properties

    private let cellLinkLabel = CopyableLabel()

    private let cellNameLabel: UILabel = {
        let label = DynamicFontLabel(
            fontSpec: .normalSemiboldFont,
            color: .textForeground)

        label.textColor = SemanticColors.Label.textDefault
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        label.adjustsFontSizeToFitWidth = true

        return label
    }()

    var titleText: String = "" {
        didSet {
            cellNameLabel.text = titleText
        }
    }

    var linkText: NSAttributedString? {
        didSet {
            cellLinkLabel.attributedText = linkText
        }
    }

    var preview: SettingsCellPreview = .none

    var icon: StyleKitIcon?

    var descriptor: SettingsCellDescriptorType?

    // MARK: - Logic

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func setup() {
        backgroundView = UIView()
        selectedBackgroundView = UIView()

        [cellNameLabel, cellLinkLabel].forEach {
            contentView.addSubview($0)
        }

        cellLinkLabel.textColor = SemanticColors.Label.textDefault
        cellLinkLabel.font = FontSpec(.normal, .light).font
        cellLinkLabel.numberOfLines = 0
        cellLinkLabel.lineBreakMode = .byClipping

        createConstraints()
        setupAccessibility()
        backgroundView?.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func createConstraints() {
        let leadingConstraint = cellNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        leadingConstraint.priority = .defaultHigh

        [cellNameLabel, cellLinkLabel].prepareForLayout()

        NSLayoutConstraint.activate([
            leadingConstraint,
            cellNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cellNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellNameLabel.heightAnchor.constraint(equalToConstant: 32),

            cellLinkLabel.topAnchor.constraint(equalTo: cellNameLabel.bottomAnchor, constant: 12),
            cellLinkLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellLinkLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cellLinkLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 112)
        ])
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

}
