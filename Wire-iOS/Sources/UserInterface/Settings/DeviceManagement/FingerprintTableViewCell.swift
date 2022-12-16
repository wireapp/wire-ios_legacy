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
import UIKit
import WireCommonComponents

final class FingerprintTableViewCell: UITableViewCell, DynamicTypeCapable {

    // MARK: - Properties
    let titleLabel = DynamicFontLabel(fontSpec: .smallSemiboldFont,
                                      color: SemanticColors.Label.textDefault)
    let fingerprintLabel = CopyableLabel()
    let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)

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

    var fingerprint: Data? {
        didSet {
            updateFingerprint()
        }
    }

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        titleLabel.text = L10n.Localizable.Self.Settings.AccountDetails.KeyFingerprint.title
        titleLabel.accessibilityIdentifier = "fingerprint title"
        titleLabel.textColor = SemanticColors.Label.textSectionHeader
        fingerprintLabel.numberOfLines = 0
        fingerprintLabel.accessibilityIdentifier = "fingerprint"
        fingerprintLabel.textColor = SemanticColors.Label.textDefault
        spinner.hidesWhenStopped = true

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        contentView.addSubview(fingerprintLabel)
        contentView.addSubview(spinner)

        [titleLabel, fingerprintLabel, spinner].prepareForLayout()
        NSLayoutConstraint.activate([
          titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
          titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
          titleLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

          fingerprintLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
          fingerprintLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
          fingerprintLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
          fingerprintLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

          spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
          spinner.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 4),
          spinner.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])

        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        backgroundColor = SemanticColors.View.backgroundUserCell
        backgroundView = UIView()
        selectedBackgroundView = UIView()
        addBorder(for: .bottom)

        setupStyle()
    }

    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    private func setupStyle() {
        fingerprintLabelFont = .normalLightFont
        fingerprintLabelBoldFont = .normalSemiboldFont
    }

    private func updateFingerprint() {
        if let fingerprintLabelBoldMonoFont = fingerprintLabelBoldFont?.font?.monospaced(),
           let fingerprintLabelMonoFont = fingerprintLabelFont?.font?.monospaced(),
            let attributedFingerprint = fingerprint?.attributedFingerprint(
                attributes: [.font: fingerprintLabelMonoFont, .foregroundColor: fingerprintLabel.textColor],
                boldAttributes: [.font: fingerprintLabelBoldMonoFont, .foregroundColor: fingerprintLabel.textColor],
                uppercase: false) {

                    fingerprintLabel.attributedText = attributedFingerprint
                    spinner.stopAnimating()
        } else {
            fingerprintLabel.attributedText = .none
            spinner.startAnimating()
        }
        setupAccessibility()
        layoutIfNeeded()
    }

    private func setupAccessibility() {
        guard let titleText = titleLabel.text,
              let fingerprintText = fingerprintLabel.text else {
                  isAccessibilityElement = false
                  return
              }

        accessibilityElements = [titleLabel, fingerprintLabel]
        isAccessibilityElement = true
        accessibilityLabel = "\(titleText), \(fingerprintText)"
    }

    func redrawFont() {
        updateFingerprint()
    }
}
