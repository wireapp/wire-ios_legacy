//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

final class AudioMessageRestrictionView: UIView {

    // MARK: - Properties

    let topLabel = UILabel()
    let bottomLabel = UILabel()
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .textForeground)
        return imageView
    }()

    let labelTextColor: UIColor = .from(scheme: .textForeground)
    let labelTextBlendedColor: UIColor = .from(scheme: .textDimmed)
    let labelFont: UIFont = .smallLightFont
    let labelBoldFont: UIFont = .smallSemiboldFont

    // MARK: - Life cycle

    required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .from(scheme: .placeholderBackground)

        topLabel.numberOfLines = 1
        topLabel.lineBreakMode = .byTruncatingMiddle
        topLabel.accessibilityIdentifier = "AudioMessageRestrictionTopLabel"

        bottomLabel.numberOfLines = 1
        bottomLabel.accessibilityIdentifier = "AudioMessageRestrictionBottomLabel"

        iconView.accessibilityIdentifier = "AudioMessageRestrictionIcon"

        [topLabel, bottomLabel, iconView].forEach(self.addSubview)

        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    // MARK: - Helpers

    private func createConstraints() {
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // top label
            topLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 12),
            topLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            topLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),

            // bottom label
            bottomLabel.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 2),
            bottomLabel.leadingAnchor.constraint(equalTo: topLabel.leadingAnchor),
            bottomLabel.trailingAnchor.constraint(equalTo: topLabel.trailingAnchor),

            // icon view
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    // MARK: - Public

    func configure() {
        iconView.contentMode = .center
        iconView.setTemplateIcon(.microphone, size: .small)

        let firstLine = L10n.Localizable.Conversation.InputBar.MessagePreview.audio.localizedUppercase && labelBoldFont && labelTextColor
        let secondLine = L10n.Localizable.Feature.Flag.Restriction.audio.localizedUppercase && labelFont && labelTextBlendedColor

        topLabel.attributedText = firstLine
        bottomLabel.attributedText = secondLine
    }
}
