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

typealias ContactsCellActionButtonHandler = (ZMSearchUser?) -> Void

/// A UITableViewCell version of UserCell, with simpler functionality for contact Screen with table view index bar
class ContactsCell: UITableViewCell, SeparatorViewProtocol {
    var user: UserType? = nil {
        didSet {
            avatar.user = user
            updateTitleLabel()

            if let subtitle = subtitle(forRegularUser: user), subtitle.length > 0 {
                subtitleLabel.isHidden = false
                subtitleLabel.attributedText = subtitle
            } else {
                subtitleLabel.isHidden = true
            }
        }
    }

    var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    // if nil the background color is the default content background color for the theme
    var contentBackgroundColor: UIColor? = nil {
        didSet {
            guard oldValue != contentBackgroundColor else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    final func contentBackgroundColor(for colorSchemeVariant: ColorSchemeVariant) -> UIColor {
        return contentBackgroundColor ?? UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)
    }

    static let boldFont: UIFont = .smallRegularFont
    static let lightFont: UIFont = .smallLightFont

    let avatar: BadgeUserImageView = {
        let badgeUserImageView = BadgeUserImageView()
        badgeUserImageView.userSession = ZMUserSession.shared()
        badgeUserImageView.initialsFont = .avatarInitial
        badgeUserImageView.size = .small
        badgeUserImageView.translatesAutoresizingMaskIntoConstraints = false

        return badgeUserImageView
    }()

    let avatarSpacer = UIView()
    let buttonSpacer = UIView()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .normalLightFont
        label.accessibilityIdentifier = "contact_cell.name"

        return label
    }()

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .smallRegularFont
        label.accessibilityIdentifier = "contact_cell.username"

        return label
    }()

    let actionButton: Button = {
        let button = Button(style: .full)
        button.setTitle("contacts_ui.action_button.invite".localized, for: .normal)

        return button
    }()
    var actionButtonHandler: ContactsCellActionButtonHandler?


    /// needed to calculate button width
    var allActionButtonTitles: [String] = [] {
        didSet {
            if let titleLabelFont = actionButton.titleLabel?.font {
                actionButtonWidth = CGFloat(actionButtonWidth(forTitles: allActionButtonTitles, textTransform: actionButton.textTransform, contentInsets: actionButton.contentEdgeInsets, textAttributes: [NSAttributedString.Key.font: titleLabelFont]))
            }
        }
    }

    var actionButtonWidth: CGFloat = 0 {
        didSet {
            actionButtonWidthConstraint.constant = actionButtonWidth
        }
    }
    var actionButtonWidthConstraint: NSLayoutConstraint!

    var titleStackView: UIStackView!
    var contentStackView: UIStackView!

    // SeparatorCollectionViewCell
    let separator = UIView()
    var separatorInsetConstraint: NSLayoutConstraint!
    var separatorLeadingInset: CGFloat = 64 {
        didSet {
            separatorInsetConstraint?.constant = separatorLeadingInset
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUp() {
        avatarSpacer.addSubview(avatar)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false

        buttonSpacer.addSubview(actionButton)
        buttonSpacer.translatesAutoresizingMaskIntoConstraints = false

        titleStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStackView.axis = .vertical
        titleStackView.distribution = .equalSpacing
        titleStackView.alignment = .leading
        titleStackView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView = UIStackView(arrangedSubviews: [avatarSpacer, titleStackView, buttonSpacer])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)

        createConstraints()

        actionButton.addTarget(self, action: #selector(ContactsCell.actionButtonPressed(sender:)), for: .touchUpInside)
    }

    private func configureSubviews() {

        setUp()

        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        createSeparatorConstraints()

        applyColorScheme(ColorScheme.default.variant)
    }

    func createConstraints() {

        let buttonMargin: CGFloat = 16

        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 28),
            avatar.heightAnchor.constraint(equalToConstant: 28),
            avatarSpacer.widthAnchor.constraint(equalToConstant: 64),
            avatarSpacer.heightAnchor.constraint(equalTo: avatar.heightAnchor),
            avatarSpacer.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarSpacer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -buttonMargin)
            ])

        constrain(actionButton, buttonSpacer){ actionButton, buttonSpacer in
            buttonSpacer.top == actionButton.top
            buttonSpacer.bottom == actionButton.bottom

            actionButtonWidthConstraint = actionButton.width == actionButtonWidth
            buttonSpacer.trailing == actionButton.trailing
            buttonSpacer.leading == actionButton.leading - buttonMargin

        }
    }

    func actionButtonWidth(forTitles actionButtonTitles: [String], textTransform: TextTransform, contentInsets: UIEdgeInsets, textAttributes: [NSAttributedString.Key : Any]?) -> Float {
        var width: CGFloat = 0
        for title: String in actionButtonTitles {
            let transformedTitle = title.applying(transform: textTransform)
            let titleWidth = transformedTitle.size(withAttributes: textAttributes).width

            if titleWidth > width {
                width = titleWidth
            }
        }
        return ceilf(Float(contentInsets.left + width + contentInsets.right))
    }

    private func updateTitleLabel() {
        guard let user = self.user else {
            return
        }

        titleLabel.attributedText = user.nameIncludingAvailability(color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant))
    }

    @objc func actionButtonPressed(sender: Any?) {
        if let user = user as? ZMSearchUser {
            actionButtonHandler?(user)
        }
    }
}

extension ContactsCell: Themeable {
    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        separator.backgroundColor = UIColor.from(scheme: .separator, variant: colorSchemeVariant)

        let sectionTextColor = UIColor.from(scheme: .sectionText, variant: colorSchemeVariant)
        backgroundColor = contentBackgroundColor(for: colorSchemeVariant)

        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        subtitleLabel.textColor = sectionTextColor

        updateTitleLabel()
    }

}

extension ContactsCell: UserCellSubtitleProtocol {
    static var correlationFormatters:  [ColorSchemeVariant : AddressBookCorrelationFormatter] = [:]
}
