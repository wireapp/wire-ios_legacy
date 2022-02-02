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

final class IconActionCell: SettingsTableCell, CellConfigurationConfigurable {

    private let separator = UIView()
    private let imageContainer = UIView()
    private let iconImageView = UIImageView()
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
    }

    private func setupViews() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .init(white: 0, alpha: 0.08)
        selectedBackgroundView = backgroundView
        backgroundColor = .clear
        imageContainer.addSubview(iconImageView)
        label.font = FontSpec(.normal, .light).font
        [imageContainer, label, separator].forEach(contentView.addSubview)
    }

    private func createConstraints() {
        [label,
         separator,
         imageContainer,
         iconImageView].prepareForLayout()
        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageContainer.widthAnchor.constraint(equalToConstant: CGFloat.IconCell.IconWidth),
            iconImageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),

            label.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            label.heightAnchor.constraint(equalToConstant: 56),

            separator.heightAnchor.constraint(equalToConstant: .hairline),
            separator.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .iconAction(title, icon, color, _) = configuration else { preconditionFailure() }
        let mainColor = variant.mainColor(color: color)
        iconImageView.setIcon(icon, size: .tiny, color: mainColor)
        label.textColor = mainColor
        label.text = title
        separator.backgroundColor = UIColor.from(scheme: .cellSeparator, variant: variant)
    }

}

extension IconActionCell: IconActionCellDelegate {

    func updateLayout() {
        descriptor?.featureCell(self)
    }

}
