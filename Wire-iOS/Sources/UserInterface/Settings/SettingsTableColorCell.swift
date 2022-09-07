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

class SettingsTableColorCell: SettingsTableCell {
    override var preview: SettingsCellPreview {
        didSet {
            switch preview {
            case .accentColor(let accentColor):
                colorNameLabel.text = accentColor.name
                colorView.image = .none
                colorView.backgroundColor = UIColor(for: accentColor)
                colorView.accessibilityValue = "color"
                colorView.isAccessibilityElement = true
            default:
                return
            }
        }
    }

    override var titleText: String {
        didSet {
            profileCellNameLabel.text = titleText
        }
    }

    let profileCellNameLabel: UILabel = {
        let label = DynamicFontLabel(
            fontSpec: .normalSemiboldFont,
            color: .textForeground)
        label.textColor = SemanticColors.Label.textDefault
        label.numberOfLines = 0
        return label
    }()

    let colorNameLabel: UILabel = {
        let valueLabel = DynamicFontLabel(
            fontSpec: .mediumRegularFont,
            color: .textForeground)
        valueLabel.textColor = SemanticColors.Label.textDefault
        valueLabel.textAlignment = .right
        return valueLabel
    }()

    let colorView: UIImageView = {
        let colorView = UIImageView()
        colorView.clipsToBounds = true
        colorView.layer.cornerRadius = 15
        colorView.contentMode = .scaleAspectFill
        colorView.accessibilityIdentifier = "colorView"

        return colorView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
        createConstraints()
    }

    private func createConstraints() {
        [profileCellNameLabel, colorNameLabel, colorView].prepareForLayout()

        NSLayoutConstraint.activate([
            profileCellNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            profileCellNameLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 22),

            colorNameLabel.topAnchor.constraint(equalTo: profileCellNameLabel.bottomAnchor),
            colorNameLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 22),

            colorView.widthAnchor.constraint(equalTo: colorView.heightAnchor),
            colorView.heightAnchor.constraint(equalToConstant: 30),
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
    }

    private func setupView() {
        [profileCellNameLabel, colorNameLabel, colorView].forEach {
            contentView.addSubview($0)
        }

        badge.isHidden = true
        cellNameLabel.isHidden = true
        valueLabel.isHidden = true
        imagePreview.isHidden = true
    }
}
