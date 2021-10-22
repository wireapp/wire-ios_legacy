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
import Cartography

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
        backgroundView.backgroundColor = .init(white: 0, alpha: 0.08)
        selectedBackgroundView = backgroundView
        imageContainer.addSubview(iconImageView)
        iconImageView.setIcon(.link, size: .tiny, color: .strongBlue)
        label.textColor = .strongBlue
        label.font = FontSpec(.normal, .light).font
        [imageContainer, label].forEach(contentView.addSubview)
    }

    private func createConstraints() {
        constrain(contentView, label, imageContainer, iconImageView) { contentView, label, imageContainer, imageView in
            imageContainer.top == contentView.top
            imageContainer.bottom == contentView.bottom
            imageContainer.leading == contentView.leading
            imageContainer.width == 64
            imageView.center == imageContainer.center
            label.leading == imageContainer.trailing
            label.top == contentView.top
            label.trailing == contentView.trailing
            label.bottom == contentView.bottom
            label.height == 56
        }
    }

    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .leadingButton(title, identifier, _) = configuration else { preconditionFailure() }
        accessibilityIdentifier = identifier
        label.text = title
        backgroundColor = UIColor.from(scheme: .barBackground, variant: variant)
    }
}
