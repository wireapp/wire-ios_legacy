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

class DetailsCollectionViewCell: SeparatorCollectionViewCell {

    let leftIconView = UIImageView()
    let accessoryIconView = UIImageView()
    let titleLabel = UILabel()
    let statusLabel = UILabel()
    var contentStackView : UIStackView!

    override func setUp() {
        super.setUp()

        leftIconView.translatesAutoresizingMaskIntoConstraints = false
        leftIconView.contentMode = .scaleAspectFit
        leftIconView.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)

        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSpec.init(.normal, .light).font!

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = FontSpec.init(.normal, .light).font!
        statusLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)

        let avatarSpacer = UIView()
        avatarSpacer.addSubview(leftIconView)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false
        avatarSpacer.widthAnchor.constraint(equalToConstant: 64).isActive = true
        avatarSpacer.heightAnchor.constraint(equalTo: leftIconView.heightAnchor).isActive = true
        avatarSpacer.centerXAnchor.constraint(equalTo: leftIconView.centerXAnchor).isActive = true
        avatarSpacer.centerYAnchor.constraint(equalTo: leftIconView.centerYAnchor).isActive = true

        let iconViewSpacer = UIView()
        iconViewSpacer.translatesAutoresizingMaskIntoConstraints = false
        iconViewSpacer.widthAnchor.constraint(equalToConstant: 8).isActive = true

        contentStackView = UIStackView(arrangedSubviews: [avatarSpacer, titleLabel, statusLabel, iconViewSpacer, accessoryIconView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)
        contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true

    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        let sectionTextColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSectionText, variant: colorSchemeVariant)
        backgroundColor = .wr_color(fromColorScheme: ColorSchemeColorBarBackground, variant: colorSchemeVariant)
        titleLabel.textColor = .wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: colorSchemeVariant)
        statusLabel.textColor = sectionTextColor
    }

}
