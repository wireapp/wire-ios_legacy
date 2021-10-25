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

import Foundation
import Cartography

class FingerprintTableViewCell: UITableViewCell {
    let titleLabel = UILabel()
    let fingerprintLabel = CopyableLabel()
    let spinner = UIActivityIndicatorView(style: .gray)

    var variant: ColorSchemeVariant? {
        didSet {
            var color = UIColor.white

            switch variant {
            case .dark?, .none:
                color = .white
            case .light?:
                color = UIColor.from(scheme: .textForeground, variant: .light)
            }

            fingerprintLabel.textColor = color
            titleLabel.textColor = color
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

    var fingerprint: Data? {
        didSet {
            updateFingerprint()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        titleLabel.text = "self.settings.account_details.key_fingerprint.title".localized
        titleLabel.accessibilityIdentifier = "fingerprint title"
        fingerprintLabel.numberOfLines = 0
        fingerprintLabel.accessibilityIdentifier = "fingerprint"
        spinner.hidesWhenStopped = true

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        contentView.addSubview(fingerprintLabel)
        contentView.addSubview(spinner)

        constrain(contentView, titleLabel, fingerprintLabel, spinner) { contentView, titleLabel, fingerprintLabel, spinner in
            titleLabel.top == contentView.top + 16
            titleLabel.left == contentView.left + 16
            titleLabel.right <= contentView.right - 16

            fingerprintLabel.top == titleLabel.bottom + 4
            fingerprintLabel.left == contentView.left + 16
            fingerprintLabel.right == contentView.right - 16
            fingerprintLabel.bottom == contentView.bottom - 16

            spinner.centerX == contentView.centerX
            spinner.top >= titleLabel.bottom + 4
            spinner.bottom <= contentView.bottom - 16
        }

        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        backgroundColor = UIColor.clear
        backgroundView = UIView()
        selectedBackgroundView = UIView()

        setupStyle()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupStyle() {
        fingerprintLabelFont = .normalLightFont
        fingerprintLabelBoldFont = .normalSemiboldFont

        titleLabel.font = .smallSemiboldFont
    }

    func updateFingerprint() {

        if let fingerprintLabelBoldMonoFont = fingerprintLabelBoldFont?.monospaced(),
            let fingerprintLabelMonoFont = fingerprintLabelFont?.monospaced(),
            let attributedFingerprint = fingerprint?.attributedFingerprint(
                attributes: [.font: fingerprintLabelMonoFont, .foregroundColor: fingerprintLabel.textColor],
                boldAttributes: [.font: fingerprintLabelBoldMonoFont, .foregroundColor: fingerprintLabel.textColor],
                uppercase: false) {

                    fingerprintLabel.attributedText = attributedFingerprint
                    spinner.stopAnimating()
        }
        else {
            fingerprintLabel.attributedText = .none
            spinner.startAnimating()
        }
        layoutIfNeeded()
    }
}
