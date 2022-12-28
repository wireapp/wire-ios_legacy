//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import CoreLocation
import Contacts
import WireDataModel
import WireCommonComponents

class ClientTableViewCell: UITableViewCell, DynamicTypeCapable {

    // MARK: - Properties
    typealias LabelColors = SemanticColors.Label

    let nameLabel = DynamicFontLabel(fontSpec: .normalSemiboldFont,
                                     color: LabelColors.textDefault)
    let labelLabel = DynamicFontLabel(fontSpec: .smallSemiboldFont,
                                      color: LabelColors.textDefault)
    let activationLabel = UILabel(frame: CGRect.zero)
    let fingerprintLabel = UILabel(frame: CGRect.zero)
    let verifiedLabel = DynamicFontLabel(fontSpec: .smallFont,
                                         color: LabelColors.textDefault)

    private let activationLabelFont = FontSpec.smallLightFont
    private let activationLabelDateFont = FontSpec.smallSemiboldFont

    var showVerified: Bool = false {
        didSet {
            updateVerifiedLabel()
        }
    }

    var showLabel: Bool = false {
        didSet {
            updateLabel()
        }
    }

    var fingerprintLabelFont: FontSpec? {
        didSet {
            updateFingerprint()
        }
    }
    var fingerprintLabelBoldFont: FontSpec? {
        didSet {
            updateFingerprint()
        }
    }
    var fingerprintTextColor: UIColor? {
        didSet {
            updateFingerprint()
        }
    }

    var userClient: UserClient? {
        didSet {
            guard let userClient = userClient else { return }
            if let userClientModel = userClient.model {
                nameLabel.text = userClientModel
            } else if userClient.isLegalHoldDevice {
                nameLabel.text = L10n.Localizable.Device.Class.legalhold
            }

            updateLabel()

            activationLabel.text = ""
            if let date = userClient.activationDate?.formattedDate {
                let text = L10n.Localizable.Registration.Devices.activated(date)
                var attrText = NSAttributedString(string: text) && activationLabelFont.font
                attrText = attrText.adding(font: activationLabelDateFont.font!, to: date)
                activationLabel.attributedText = attrText
            }

            updateFingerprint()
            updateVerifiedLabel()
        }
    }

    var wr_editable: Bool

    var variant: ColorSchemeVariant?

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        wr_editable = true
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        createConstraints()
        setupStyle()
    }

    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override method
    override func setEditing(_ editing: Bool, animated: Bool) {
        if wr_editable {
            super.setEditing(editing, animated: animated)
        }
    }

    // MARK: - Methods
    func setupStyle() {
        let textColor = SemanticColors.Label.textDefault
        nameLabel.accessibilityIdentifier = "device name"
        labelLabel.accessibilityIdentifier = "device label"
        activationLabel.accessibilityIdentifier = "device activation date"
        fingerprintLabel.accessibilityIdentifier = "device fingerprint"
        verifiedLabel.accessibilityIdentifier = "device verification status"

        activationLabel.numberOfLines = 0
        activationLabel.textColor = textColor

        fingerprintLabelFont = .smallLightFont
        fingerprintLabelBoldFont = .smallSemiboldFont
        fingerprintTextColor = textColor

        backgroundColor = SemanticColors.View.backgroundUserCell

        addBorder(for: .bottom)
    }

    private func createConstraints() {
        [nameLabel, labelLabel, activationLabel, fingerprintLabel, verifiedLabel].forEach(contentView.addSubview)

        [nameLabel, labelLabel, activationLabel, fingerprintLabel, verifiedLabel].prepareForLayout()

        // Setting the constraints for the view
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            nameLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            labelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            labelLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            labelLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            fingerprintLabel.topAnchor.constraint(equalTo: labelLabel.bottomAnchor, constant: 4),
            fingerprintLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            fingerprintLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),
            fingerprintLabel.heightAnchor.constraint(equalToConstant: 16),

            activationLabel.topAnchor.constraint(equalTo: fingerprintLabel.bottomAnchor, constant: 8),
            activationLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            activationLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            verifiedLabel.topAnchor.constraint(equalTo: activationLabel.bottomAnchor, constant: 4),
            verifiedLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            verifiedLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),
            verifiedLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    private func updateVerifiedLabel() {
        if let userClient = userClient,
           showVerified {

            if userClient.verified {
                verifiedLabel.text = L10n.Localizable.Device.verified.capitalized
            } else {
                verifiedLabel.text = L10n.Localizable.Device.notVerified.capitalized
            }
        } else {
            verifiedLabel.text = ""
        }
    }

    private func updateFingerprint() {
        if let fingerprintLabelBoldMonoFont = fingerprintLabelBoldFont?.font?.monospaced(),
           let fingerprintLabelMonoFont = fingerprintLabelFont?.font?.monospaced(),
           let fingerprintLabelTextColor = fingerprintTextColor,
           let userClient = userClient, userClient.remoteIdentifier != nil {

            fingerprintLabel.attributedText =  userClient.attributedRemoteIdentifier(
                [.font: fingerprintLabelMonoFont, .foregroundColor: fingerprintLabelTextColor],
                boldAttributes: [.font: fingerprintLabelBoldMonoFont, .foregroundColor: fingerprintLabelTextColor],
                uppercase: true
            )
        }
    }

    private func updateLabel() {
        if let userClientLabel = userClient?.label, showLabel {
            labelLabel.text = userClientLabel
        } else {
            labelLabel.text = ""
        }
    }

    func redrawFont() {
        updateFingerprint()
        updateLabel()
    }
}
