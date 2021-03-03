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

import Foundation
import UIKit
import WireCommonComponents
import WireDataModel

final class UserClientCell: SeparatorCollectionViewCell {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let deviceTypeIconView = UIImageView()
    private let accessoryIconView = UIImageView()
    private let verifiedIconView = UIImageView()

    private var contentStackView: UIStackView!
    private var titleStackView: UIStackView!
    private var iconStackView: UIStackView!

    private let boldFingerprintFont: UIFont = .smallSemiboldFont
    private let fingerprintFont: UIFont = .smallFont

    private weak var client: UserClientType?

    override func setUp() {
        super.setUp()

        accessibilityIdentifier = "device_cell"
        shouldGroupAccessibilityChildren = true

        deviceTypeIconView.image = StyleKitIcon.devices.makeImage(size: .tiny, color: .white)
        deviceTypeIconView.translatesAutoresizingMaskIntoConstraints = false
        deviceTypeIconView.contentMode = .center

        verifiedIconView.image = WireStyleKit.imageOfShieldverified
        verifiedIconView.translatesAutoresizingMaskIntoConstraints = false
        verifiedIconView.contentMode = .center
        verifiedIconView.isAccessibilityElement = true
        verifiedIconView.accessibilityIdentifier = "device_cell.verifiedShield"

        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .smallSemiboldFont
        titleLabel.accessibilityIdentifier = "device_cell.name"

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .smallRegularFont
        subtitleLabel.accessibilityIdentifier = "device_cell.identifier"

        iconStackView = UIStackView(arrangedSubviews: [verifiedIconView, accessoryIconView])
        iconStackView.spacing = 16
        iconStackView.axis = .horizontal
        iconStackView.distribution = .fill
        iconStackView.alignment = .center
        iconStackView.translatesAutoresizingMaskIntoConstraints = false
        iconStackView.setContentHuggingPriority(.required, for: .horizontal)

        titleStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStackView.spacing = 4
        titleStackView.axis = .vertical
        titleStackView.distribution = .equalSpacing
        titleStackView.alignment = .leading
        titleStackView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView = UIStackView(arrangedSubviews: [deviceTypeIconView, titleStackView, iconStackView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)

        createConstraints()
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            deviceTypeIconView.widthAnchor.constraint(equalToConstant: 64),
            deviceTypeIconView.heightAnchor.constraint(equalToConstant: 64),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)

        let sectionTextColor = UIColor.from(scheme: .sectionText, variant: colorSchemeVariant)
        let textForegroundColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        backgroundColor = contentBackgroundColor(for: colorSchemeVariant)
        accessoryIconView.setIcon(.disclosureIndicator, size: 12, color: sectionTextColor)
        titleLabel.textColor = textForegroundColor
        subtitleLabel.textColor = textForegroundColor

        updateDeviceIcon()
    }

    func configure(with client: UserClientType) {
        self.client = client

        let attributes: [NSAttributedString.Key: AnyObject] = [NSAttributedString.Key.font: fingerprintFont.monospaced()]
        let boldAttributes: [NSAttributedString.Key: AnyObject] = [NSAttributedString.Key.font: boldFingerprintFont.monospaced()]

        verifiedIconView.image = client.verified ? WireStyleKit.imageOfShieldverified : WireStyleKit.imageOfShieldnotverified
        verifiedIconView.accessibilityLabel = client.verified ? "device.verified".localized : "device.not_verified".localized

        titleLabel.text = client.deviceClass?.localizedDescription.localizedUppercase ?? client.type.localizedDescription.localizedUppercase
        subtitleLabel.attributedText = client.attributedRemoteIdentifier(attributes, boldAttributes: boldAttributes, uppercase: true)

        updateDeviceIcon()
    }

    private func updateDeviceIcon() {
        switch client?.deviceClass {
        case .legalHold?:
            deviceTypeIconView.image = StyleKitIcon.legalholdactive.makeImage(size: .tiny, color: .vividRed)
            deviceTypeIconView.accessibilityIdentifier = "img.device_class.legalhold"
        default:
            deviceTypeIconView.setIcon(.devices, size: .tiny, color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant))
            deviceTypeIconView.accessibilityIdentifier = client?.deviceClass == .desktop ? "img.device_class.desktop" : "img.device_class.phone"
        }
    }
}
