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

final class VideoMessageRestrictionView: UIView {

    // MARK: - Properties
    
    let topLabel = UILabel()
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .textForeground)
        return imageView
    }()

    let labelTextBlendedColor: UIColor = .from(scheme: .textDimmed)
    let labelFont: UIFont = .smallLightFont

    // MARK: - Life cycle

    required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .from(scheme: .placeholderBackground)

        topLabel.numberOfLines = 3
        topLabel.lineBreakMode = .byTruncatingMiddle
        topLabel.accessibilityIdentifier = "VideoMessageRestrictionTopLabel"

        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 16
        iconView.backgroundColor = .white
        iconView.accessibilityIdentifier = "VideoMessageRestrictionIcon"

        [topLabel, iconView].forEach(self.addSubview)

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
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // icon view
            iconView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -12),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            // top label
            topLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            topLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
        ])
    }

    // MARK: - Public

    func configure() {
        iconView.contentMode = .center
        iconView.setTemplateIcon(.play, size: .tiny)

        let firstLine = L10n.Localizable.Feature.Flag.Restriction.video.localizedUppercase && labelFont && labelTextBlendedColor
        topLabel.attributedText = firstLine
    }
}
