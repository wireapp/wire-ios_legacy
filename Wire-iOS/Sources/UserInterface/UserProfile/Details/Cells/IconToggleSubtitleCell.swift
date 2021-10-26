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

final class IconToggleSubtitleCell: UITableViewCell, CellConfigurationConfigurable {
    private let imageContainer = UIView()
    private var iconImageView = UIImageView()
    private let topContainer = UIView()
    private let titleLabel = UILabel()
    private let toggle = UISwitch()
    private let subtitleLabel = UILabel()

    private var action: ((Bool, UIView?) -> Void)?
    private var variant: ColorSchemeVariant = .light {
        didSet {
            styleViews()
        }
    }

    private var imageContainerWidthConstraint: NSLayoutConstraint?
    private var iconImageViewLeadingConstraint: NSLayoutConstraint?

    private var subtitleTopConstraint: NSLayoutConstraint?
    private var subtitleBottomConstraint: NSLayoutConstraint?
    private let subtitleInsets = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)

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

    private func createConstraints() {
        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          self.imageContainerWidthConstraint = imageContainer.widthAnchor.constraint(equalTo: CGFloat.IconCell.IconWidthAnchor),
          iconImageView.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor),
          titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: CGFloat.IconCell.IconSpacing),
          self.iconImageViewLeadingConstraint = iconImageView.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor, constant: CGFloat.IconCell.IconSpacing),

          toggle.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor),
          toggle.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor, constant: -CGFloat.IconCell.IconSpacing),
          titleLabel.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor)
        ])
        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          topContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
          topContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
          topContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
          topContainer.heightAnchor.constraint(equalToConstant: 56),

          subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: self.subtitleInsets.leading),
          subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -self.subtitleInsets.trailing),
          self.subtitleTopConstraint = subtitleLabel.topAnchor.constraint(equalTo: topContainer.bottomAnchor, constant: self.subtitleInsets.top),
          self.subtitleBottomConstraint = subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -self.subtitleInsets.bottom)
        ])
    }

    private func styleViews() {
        topContainer.backgroundColor = UIColor.from(scheme: .barBackground, variant: variant)
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        subtitleLabel.textColor = UIColor.from(scheme: .textDimmed, variant: variant)
        backgroundColor = .clear
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        action?(sender.isOn, self)
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

        if let icon = icon {
            iconImageView.setIcon(icon, size: .tiny, color: mainColor)
            imageContainerWidthConstraint?.constant = CGFloat.IconCell.IconWidth
            iconImageViewLeadingConstraint?.constant = CGFloat.IconCell.IconSpacing
        } else {
            imageContainerWidthConstraint?.constant = 0
            iconImageViewLeadingConstraint?.constant = 0
        }

        titleLabel.textColor = mainColor

        titleLabel.text = title

        subtitleLabel.text = subtitle

        if subtitle.isEmpty {
            subtitleLabel.isHidden = true
            subtitleTopConstraint?.constant = 0
            subtitleBottomConstraint?.constant = 0
        } else {
            subtitleLabel.isHidden = false
            subtitleTopConstraint?.constant = subtitleInsets.top
            subtitleBottomConstraint?.constant = -(subtitleInsets.bottom)
        }

        action = set
        toggle.accessibilityIdentifier = identifier
        titleLabel.accessibilityIdentifier = titleIdentifier
        toggle.isOn = get()
        self.variant = variant
    }
}
