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
import Cartography
import CoreLocation
import Contacts
import WireDataModel

class ClientTableViewCell: UITableViewCell {

    let nameLabel = UILabel(frame: CGRect.zero)
    let labelLabel = UILabel(frame: CGRect.zero)
    let activationLabel = UILabel(frame: CGRect.zero)
    let fingerprintLabel = UILabel(frame: CGRect.zero)
    let verifiedLabel = UILabel(frame: CGRect.zero)

    private let activationLabelFont = UIFont.smallLightFont
    private let activationLabelDateFont = UIFont.smallSemiboldFont

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

    var fingerprintLabelFont: UIFont? {
        didSet {
            updateFingerprint()
        }
    }
    var fingerprintLabelBoldFont: UIFont? {
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
                nameLabel.text = "device.class.legalhold".localized
            }

            updateLabel()

            activationLabel.text = ""
            if let date = userClient.activationDate?.formattedDate {
                let text = "registration.devices.activated".localized(args: date)
                var attrText = NSAttributedString(string: text) && activationLabelFont
                attrText = attrText.adding(font: activationLabelDateFont, to: date)
                activationLabel.attributedText = attrText
            }

            updateFingerprint()
            updateVerifiedLabel()
        }
    }

    var wr_editable: Bool

    var variant: ColorSchemeVariant? {
        didSet {
            switch variant {
            case .dark?, .none:
                verifiedLabel.textColor = UIColor(white: 1, alpha: 0.4)
                fingerprintTextColor = .white
                nameLabel.textColor = .white
                labelLabel.textColor = .white
                activationLabel.textColor = .white
            case .light?:
                let textColor = UIColor.from(scheme: .textForeground, variant: .light)
                verifiedLabel.textColor = textColor
                fingerprintTextColor = textColor
                nameLabel.textColor = textColor
                labelLabel.textColor = textColor
                activationLabel.textColor = textColor
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        wr_editable = true

        nameLabel.accessibilityIdentifier = "device name"
        labelLabel.accessibilityIdentifier = "device label"
        activationLabel.accessibilityIdentifier = "device activation date"
        fingerprintLabel.accessibilityIdentifier = "device fingerprint"
        verifiedLabel.accessibilityIdentifier = "device verification status"
        verifiedLabel.isAccessibilityElement = true

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        [nameLabel, labelLabel, activationLabel, fingerprintLabel, verifiedLabel].forEach(contentView.addSubview)

        constrain(contentView, nameLabel, labelLabel) { contentView, nameLabel, labelLabel in
            nameLabel.top == contentView.top + 16
            nameLabel.left == contentView.left + 16
            nameLabel.right <= contentView.right - 16

            labelLabel.top == nameLabel.bottom + 2
            labelLabel.left == contentView.left + 16
            labelLabel.right <= contentView.right - 16
        }

        constrain(contentView, labelLabel, activationLabel, fingerprintLabel, verifiedLabel) { contentView, labelLabel, activationLabel, fingerprintLabel, verifiedLabel in

            fingerprintLabel.top == labelLabel.bottom + 4
            fingerprintLabel.left == contentView.left + 16
            fingerprintLabel.right <= contentView.right - 16
            fingerprintLabel.height == 16

            activationLabel.top == fingerprintLabel.bottom + 8
            activationLabel.left == contentView.left + 16
            activationLabel.right <= contentView.right - 16

            verifiedLabel.top == activationLabel.bottom + 4
            verifiedLabel.left == contentView.left + 16
            verifiedLabel.right <= contentView.right - 16
            verifiedLabel.bottom == contentView.bottom - 16
        }

        backgroundColor = UIColor.clear
        backgroundView = UIView()
        selectedBackgroundView = UIView()

        setupStyle()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        if wr_editable {
            super.setEditing(editing, animated: animated)
        }
    }

    func setupStyle() {
        nameLabel.font = .normalSemiboldFont
        labelLabel.font = .smallSemiboldFont
        verifiedLabel.font = .smallFont
        fingerprintLabelFont = .smallLightFont
        fingerprintLabelBoldFont = .smallSemiboldFont
    }

    func updateVerifiedLabel() {
        if let userClient = userClient,
            showVerified {

            if userClient.verified {
                verifiedLabel.text = NSLocalizedString("device.verified", comment: "")
            }
            else {
                verifiedLabel.text = NSLocalizedString("device.not_verified", comment: "")
            }
        }
        else {
            verifiedLabel.text = ""
        }
    }

    func updateFingerprint() {
        if let fingerprintLabelBoldMonoFont = fingerprintLabelBoldFont?.monospaced(),
            let fingerprintLabelMonoFont = fingerprintLabelFont?.monospaced(),
            let fingerprintLabelTextColor = fingerprintTextColor,
            let userClient = userClient, userClient.remoteIdentifier != nil {

                fingerprintLabel.attributedText =  userClient.attributedRemoteIdentifier(
                    [.font: fingerprintLabelMonoFont, .foregroundColor: fingerprintLabelTextColor],
                    boldAttributes: [.font: fingerprintLabelBoldMonoFont, .foregroundColor: fingerprintLabelTextColor],
                    uppercase: true
                )
        }
    }

    func updateLabel() {
        if let userClientLabel = userClient?.label, showLabel {
            labelLabel.text = userClientLabel
        }
        else {
            labelLabel.text = ""
        }
    }
}
