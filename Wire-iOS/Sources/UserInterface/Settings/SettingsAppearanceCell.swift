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

    // MARK: - Properties

    private let titleLabel: UILabel = {
        let label = DynamicFontLabel(
            fontSpec: .normalSemiboldFont,
            color: SemanticColors.Label.textDefault)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let valueLabel = DynamicFontLabel(
            fontSpec: .mediumRegularFont,
            color: SemanticColors.Label.textDefault)
        valueLabel.textAlignment = .right
        return valueLabel
    }()

    private let iconImageView: UIImageView = {
        let iconView = UIImageView()
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 15
        iconView.contentMode = .scaleAspectFill

        return iconView
    }()

    private let accessoryIconView: UIImageView = {
        let iconView = UIImageView()
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFill
        iconView.setTemplateIcon(.pencil, size: .tiny)
        iconView.tintColor = SemanticColors.Icon.foregroundDefault

        return iconView
    }()

    private lazy var titleLabelToIconInset: NSLayoutConstraint = titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 22)

    var isAccessoryIconHidden: Bool = true {
        didSet {
            accessoryIconView.isHidden = isAccessoryIconHidden
        }
    }

    var type: SettingsCellPreview = .none {
        didSet {
            switch type {
            case .image(let image):
                iconImageView.image = image
                iconImageView.backgroundColor = UIColor.clear
                subtitleLabel.text = nil
                titleLabelToIconInset.isActive = true
            case .color(let color):
                iconImageView.backgroundColor = color
                iconImageView.image = .none
                subtitleLabel.text = AccentColor.current.name
                titleLabelToIconInset.isActive = true
            default:
                subtitleLabel.text = nil
                iconImageView.backgroundColor = UIColor.clear
                iconImageView.image = .none
                titleLabelToIconInset.isActive = false
            }
            layoutIfNeeded()
        }
    }

    // MARK: - Life Cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
        createConstraints()
    }

    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .appearance(title) = configuration else { preconditionFailure() }
        titleLabel.text = title
    }

    // MARK: - Helpers

    private func createConstraints() {
        [titleLabel, subtitleLabel, iconImageView, accessoryIconView].prepareForLayout()

        let centerConstraint = titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        centerConstraint.priority = .defaultLow

        let leadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        leadingConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            centerConstraint,

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            subtitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 22),

            iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            leadingConstraint,
            accessoryIconView.widthAnchor.constraint(equalTo: accessoryIconView.heightAnchor),
            accessoryIconView.heightAnchor.constraint(equalToConstant: 16),
            accessoryIconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            accessoryIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
    }

    private func setupView() {
        [titleLabel, subtitleLabel, iconImageView, accessoryIconView].forEach {
            contentView.addSubview($0)
        }
    }

}

private extension AccentColor {
    static var current: AccentColor {
        return AccentColor(ZMAccentColor: UIColor.indexedAccentColor()) ?? .blue
    }
}
