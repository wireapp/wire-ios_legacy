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
import WireCommonComponents

final class ActionCell: UITableViewCell, CellConfigurationConfigurable {

    private let imageContainer = UIView()
    private let iconImageView = UIImageView()
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = SemanticColors.View.backgroundUserCell
        selectedBackgroundView = backgroundView
        imageContainer.addSubview(iconImageView)
        iconImageView.setIcon(.link, size: .tiny, color: SemanticColors.Icon.foregroundDefault)
        iconImageView.setTemplateIcon(.link, size: .tiny)
        iconImageView.tintColor = SemanticColors.Icon.foregroundDefault
        label.textColor = SemanticColors.Label.textDefault
        label.font = FontSpec(.normal, .semibold).font
        [imageContainer, label].forEach(contentView.addSubview)
    }

    private func createConstraints() {
        [label, imageContainer, iconImageView].prepareForLayout()
        NSLayoutConstraint.activate([
          imageContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
          imageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
          imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
          imageContainer.widthAnchor.constraint(equalToConstant: 64),
            iconImageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
          label.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
          label.topAnchor.constraint(equalTo: contentView.topAnchor),
          label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
          label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
          label.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .leadingButton(title, identifier, _) = configuration else { preconditionFailure() }
        accessibilityIdentifier = identifier
        label.text = title
        backgroundColor = SemanticColors.View.backgroundUserCell
    }
}
