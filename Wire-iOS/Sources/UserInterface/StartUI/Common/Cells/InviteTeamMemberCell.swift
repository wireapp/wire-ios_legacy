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

import Foundation
import Cartography
import WireCommonComponents

class StartUIIconCell: UICollectionViewCell {

    fileprivate let iconView = UIImageView()
    fileprivate let titleLabel = UILabel()
    fileprivate let separator = UIView()

    fileprivate var icon: StyleKitIcon? {
        didSet {
            iconView.image = icon?.makeImage(size: .tiny, color: .white)
        }
    }

    fileprivate var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .init(white: 0, alpha: 0.08) : .clear
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setupViews() {
        iconView.contentMode = .center
        titleLabel.font = FontSpec(.normal, .light).font
        titleLabel.textColor = .white
        [iconView, titleLabel, separator].forEach(contentView.addSubview)
        separator.backgroundColor = UIColor.from(scheme: .cellSeparator, variant: .dark)
    }

    fileprivate  func createConstraints() {
        let iconSize: CGFloat = 32.0

        constrain(contentView, iconView, titleLabel, separator) { container, iconView, titleLabel, separator in
            iconView.width == iconSize
            iconView.height == iconSize
            iconView.leading == container.leading + 16
            iconView.centerY == container.centerY

            titleLabel.leading == container.leading + 64
            titleLabel.trailing == container.trailing
            titleLabel.top == container.top
            titleLabel.bottom == container.bottom

            separator.leading == titleLabel.leading
            separator.trailing == container.trailing
            separator.bottom == container.bottom
            separator.height == .hairline
        }
    }

}

final class InviteTeamMemberCell: StartUIIconCell  {

    override func setupViews() {
        super.setupViews()
        icon = .envelope
        title = "peoplepicker.invite_team_members".localized
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits.insert(.button)
        accessibilityIdentifier = "button.searchui.invite_team"
    }

}

final class CreateGroupCell: StartUIIconCell  {

    override func setupViews() {
        super.setupViews()
        icon = .createConversation
        title = "peoplepicker.quick-action.create-conversation".localized
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits.insert(.button)
        accessibilityIdentifier = "button.searchui.creategroup"
    }

}

final class CreateGuestRoomCell: StartUIIconCell  {

    override func setupViews() {
        super.setupViews()
        icon = .guest
        title = "peoplepicker.quick-action.create-guest-room".localized
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits.insert(.button)
        accessibilityIdentifier = "button.searchui.createguestroom"
    }

}

final class OpenServicesAdminCell: StartUIIconCell, Themeable  {
    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    @objc dynamic var contentBackgroundColor: UIColor? = nil {
        didSet {
            guard oldValue != contentBackgroundColor else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        backgroundColor = contentBackgroundColor(for: colorSchemeVariant)
        separator.backgroundColor = UIColor.from(scheme: .cellSeparator, variant: colorSchemeVariant)
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        iconView.image = icon?.makeImage(size: .tiny, color: UIColor.from(scheme: .iconNormal, variant: colorSchemeVariant))
    }

    func contentBackgroundColor(for colorSchemeVariant: ColorSchemeVariant) -> UIColor {
        return contentBackgroundColor ?? UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? UIColor(white: 0, alpha: 0.08)
                : contentBackgroundColor(for: colorSchemeVariant)
        }
    }

    override func setupViews() {
        super.setupViews()
        icon = .bot
        title = "peoplepicker.quick-action.admin-services".localized
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityIdentifier = "button.searchui.open-services"
        applyColorScheme(ColorScheme.default.variant)
    }

}
