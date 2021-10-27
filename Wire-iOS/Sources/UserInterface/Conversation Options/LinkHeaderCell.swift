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

final class LinkHeaderCell: UITableViewCell, CellConfigurationConfigurable {

    private let topSeparator = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

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

    private func setupViews() {
        [topSeparator, titleLabel, subtitleLabel].forEach(contentView.addSubview)
        titleLabel.font = FontSpec(.small, .semibold).font
        titleLabel.text = "guest_room.link.header.title".localized(uppercased: true)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = FontSpec(.medium, .regular).font
        subtitleLabel.text = "guest_room.link.header.subtitle".localized
    }

    private func createConstraints() {
        constrain(contentView, topSeparator, titleLabel, subtitleLabel) { contentView, topSeparator, titleLabel, subtitleLabel in
            topSeparator.top == contentView.top
            topSeparator.leading == contentView.leading + 16
            topSeparator.trailing == contentView.trailing - 16
            topSeparator.height == .hairline

            titleLabel.top == topSeparator.bottom + 24
            titleLabel.leading == topSeparator.leading
            titleLabel.trailing == topSeparator.trailing

            subtitleLabel.top == titleLabel.bottom + 16
            subtitleLabel.leading == topSeparator.leading
            subtitleLabel.trailing == topSeparator.trailing
            subtitleLabel.bottom == contentView.bottom - 24
        }
    }

    private func styleViews() {
        let color = UIColor.from(scheme: .textDimmed, variant: variant)
        topSeparator.backgroundColor = UIColor.from(scheme: .cellSeparator, variant: variant)
        titleLabel.textColor = color
        subtitleLabel.textColor = color
        backgroundColor = .clear
    }

    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        self.variant = variant
    }

}
