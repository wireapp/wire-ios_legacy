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

    private let leftIconView = UIImageView()
    private let accessoryIconView = UIImageView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()

    private var contentStackView : UIStackView!
    private var leftIconContainer: UIView!
    private var contentLeadingConstraint: NSLayoutConstraint!

    // MARK: - Properties

    var icon: UIImage? {
        get { return leftIconView.image }
        set { updateIcon(newValue) }
    }

    var accessory: UIImage? {
        get { return accessoryIconView.image }
        set { updateAccessory(newValue) }
    }

    var title: String? {
        get { return titleLabel.text }
        set { updateTitle(newValue) }
    }

    var status: String? {
        get { return statusLabel.text }
        set { updateStatus(newValue) }
    }
    
    var disabled: Bool = false {
        didSet {
            updateDisabledState()
        }
    }

    // MARK: - Configuration

    override func setUp() {
        super.setUp()

        leftIconView.translatesAutoresizingMaskIntoConstraints = false
        leftIconView.contentMode = .scaleAspectFit
        leftIconView.setContentHuggingPriority(.required, for: .horizontal)

        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSpec.init(.normal, .light).font!

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = FontSpec.init(.normal, .light).font!
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)

        leftIconContainer = UIView()
        leftIconContainer.addSubview(leftIconView)
        leftIconContainer.translatesAutoresizingMaskIntoConstraints = false
        leftIconContainer.widthAnchor.constraint(equalToConstant: 64).isActive = true
        leftIconContainer.heightAnchor.constraint(equalTo: leftIconView.heightAnchor).isActive = true
        leftIconContainer.centerXAnchor.constraint(equalTo: leftIconView.centerXAnchor).isActive = true
        leftIconContainer.centerYAnchor.constraint(equalTo: leftIconView.centerYAnchor).isActive = true

        let iconViewSpacer = UIView()
        iconViewSpacer.translatesAutoresizingMaskIntoConstraints = false
        iconViewSpacer.widthAnchor.constraint(equalToConstant: 8).isActive = true

        contentStackView = UIStackView(arrangedSubviews: [leftIconContainer, titleLabel, statusLabel, iconViewSpacer, accessoryIconView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)
        contentLeadingConstraint = contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        contentLeadingConstraint.isActive = true

        contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        let sectionTextColor = UIColor(scheme: .sectionText, variant: colorSchemeVariant)
        backgroundColor = UIColor(scheme: .barBackground, variant: colorSchemeVariant)
        statusLabel.textColor = sectionTextColor
        updateDisabledState()
    }

    // MARK: - Layout

    private func updateIcon(_ newValue: UIImage?) {
        if let value = newValue {
            leftIconView.image = value
            leftIconView.isHidden = false
            leftIconContainer.isHidden = false

            contentLeadingConstraint.constant = 0
            separatorLeadingInset = 64
        } else {
            leftIconView.isHidden = true
            leftIconContainer.isHidden = true

            contentLeadingConstraint.constant = 24
            separatorLeadingInset = 24
        }
    }

    private func updateTitle(_ newValue: String?) {
        if let value = newValue {
            titleLabel.text = value
            titleLabel.isHidden = false
        } else {
            titleLabel.isHidden = true
        }
    }

    private func updateStatus(_ newValue: String?) {
        if let value = newValue {
            statusLabel.text = value
            statusLabel.isHidden = false
        } else {
            statusLabel.isHidden = true
        }
    }

    private func updateAccessory(_ newValue: UIImage?) {
        if let value = newValue {
            accessoryIconView.image = value
            accessoryIconView.isHidden = false
        } else {
            accessoryIconView.isHidden = true
        }
    }
    
    private func updateDisabledState() {
        titleLabel.textColor = UIColor(scheme: disabled ? .textPlaceholder : .textForeground, variant: colorSchemeVariant)
    }

}
