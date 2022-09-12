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

class SettingsAppearanceCell: SettingsTableCell, CellConfigurationConfigurable {
    let titleLabel: UILabel = {
        let label = DynamicFontLabel(
            fontSpec: .normalSemiboldFont,
            color: .textForeground)
        label.textColor = SemanticColors.Label.textDefault
        label.numberOfLines = 0
        return label
    }()

    let subtitleLabel: UILabel = {
        let valueLabel = DynamicFontLabel(
            fontSpec: .mediumRegularFont,
            color: .textForeground)
        valueLabel.textColor = SemanticColors.Label.textDefault
        valueLabel.textAlignment = .right
        return valueLabel
    }()

    let iconImageView: UIImageView = {
        let iconView = UIImageView()
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 15
        iconView.contentMode = .scaleAspectFill
        iconView.accessibilityIdentifier = "iconView"

        return iconView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
        createConstraints()
    }

    private func createConstraints() {
        [titleLabel, subtitleLabel, iconImageView].prepareForLayout()

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 22),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 22),

            iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
    }

    private func setupView() {
        [titleLabel, subtitleLabel, iconImageView].forEach {
            contentView.addSubview($0)
        }

    }

    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .appearance(title) = configuration else { preconditionFailure() }
        titleLabel.text = title
        subtitleLabel.text = AccentColor.current.name
        iconImageView.backgroundColor = .accent()
    }
}

private extension AccentColor {
    static var current: AccentColor {
        return AccentColor(ZMAccentColor: UIColor.indexedAccentColor()) ?? .blue
    }
}
