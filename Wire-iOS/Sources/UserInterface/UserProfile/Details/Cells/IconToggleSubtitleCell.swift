//
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

import UIKit
import Cartography

final class IconToggleSubtitleCell: UITableViewCell, CellConfigurationConfigurable {
    private let imageContainer = UIView()
    private var iconImageView = UIImageView()
    private let topContainer = UIView()
    private let titleLabel = UILabel()
    private let toggle = UISwitch()
    private let subtitleLabel = UILabel()
    
    private var action: ((Bool) -> Void)?
    private var variant: ColorSchemeVariant = .light {
        didSet {
            styleViews()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
        styleViews()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        [imageContainer, titleLabel, toggle].forEach(topContainer.addSubview)
        imageContainer.addSubview(iconImageView)
        [topContainer, subtitleLabel].forEach(contentView.addSubview)
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = FontSpec(.medium, .regular).font
        titleLabel.font = FontSpec(.normal, .light).font
        accessibilityElements = [titleLabel, toggle]
    }
    
    private func createConstraints() { ///fixme: no cartography
        constrain(topContainer, titleLabel, toggle, iconImageView, imageContainer) { topContainer, titleLabel, toggle, iconImageView, imageContainer in
            imageContainer.width == 64 ///TODO: constant share with IconActionCell
            iconImageView.centerY == topContainer.centerY
            titleLabel.leading == iconImageView.trailing + 16 ///FIXME: constant share with toggle cell
            iconImageView.leading == topContainer.leading + 16

            toggle.centerY == topContainer.centerY
            toggle.trailing == topContainer.trailing - 16
            titleLabel.centerY == topContainer.centerY
        }
        constrain(contentView, topContainer, subtitleLabel) { contentView, topContainer, subtitleLabel in
            topContainer.top == contentView.top
            topContainer.leading == contentView.leading
            topContainer.trailing == contentView.trailing
            topContainer.height == 56
            
            subtitleLabel.leading == contentView.leading + 16
            subtitleLabel.trailing == contentView.trailing - 16
            subtitleLabel.top == topContainer.bottom + 16
            subtitleLabel.bottom == contentView.bottom - 24
        }
    }
    
    private func styleViews() {
        topContainer.backgroundColor = UIColor.from(scheme: .barBackground, variant: variant)
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        subtitleLabel.textColor = UIColor.from(scheme: .textDimmed, variant: variant)
        backgroundColor = .clear
    }
    
    @objc private func toggleChanged(_ sender: UISwitch) {
        action?(sender.isOn)
    }
    
    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .iconToggle(title,
                                   subtitle,
                                   identifier,
                                   titleIdentifier,
                                   icon,
                                   color,
                                   get,
                                   set) = configuration else { preconditionFailure() }
        let mainColor = variant.mainColor(color: color)

        iconImageView.setIcon(icon, size: .tiny, color: mainColor)

        titleLabel.text = title
        titleLabel.textColor = mainColor

        subtitleLabel.text = subtitle
        action = set
        toggle.accessibilityIdentifier = identifier
        titleLabel.accessibilityIdentifier = titleIdentifier
        toggle.isOn = get()
        self.variant = variant
    }
}
