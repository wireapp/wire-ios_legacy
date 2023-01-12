//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class CallHeaderBar: UIView {
    private let verticalStackView = UIStackView(axis: .vertical)
    private let titleLabel = DynamicFontLabel(fontSpec: .normalSemiboldFont, color: SemanticColors.Label.textDefault)
    private let timeLabel = DynamicFontLabel(fontSpec: .smallRegularFont, color: SemanticColors.Label.textDefault)
    private let bitrateLabel = BitRateLabel(fontSpec: .smallRegularFont, color: SemanticColors.Label.textCollectionSecondary)
    let minimalizeButton = UIButton()

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = SemanticColors.View.backgroundDefault
        minimalizeButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        minimalizeButton.tintColor = SemanticColors.View.backgroundDefaultBlack
        minimalizeButton.accessibilityLabel = L10n.Accessibility.Calling.HeaderBar.description
        [minimalizeButton, titleLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(minimalizeButton)
        addSubview(verticalStackView)
        titleLabel.accessibilityTraits = .header
        verticalStackView.alignment = .center
        verticalStackView.spacing = 0.0
        verticalStackView.addArrangedSubview(titleLabel)
        verticalStackView.addArrangedSubview(timeLabel)
        verticalStackView.addArrangedSubview(bitrateLabel)

        bitrateLabel.accessibilityIdentifier = "bitrate-indicator"
        timeLabel.accessibilityIdentifier = "time label"
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            verticalStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            verticalStackView.topAnchor.constraint(equalTo: safeTopAnchor, constant: 10.0),
            verticalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6.0),
            minimalizeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            minimalizeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            minimalizeButton.widthAnchor.constraint(equalToConstant: 32.0),
            minimalizeButton.heightAnchor.constraint(equalToConstant: 32.0),
            verticalStackView.leadingAnchor.constraint(greaterThanOrEqualTo: minimalizeButton.trailingAnchor, constant: 6.0)
        ])
    }

    func updateConfiguration(configuration: CallStatusViewInputType) {
        titleLabel.text = configuration.title
        timeLabel.text = configuration.displayString
        bitrateLabel.isHidden = !configuration.shouldShowBitrateLabel
        bitrateLabel.bitRateStatus = BitRateStatus(configuration.isConstantBitRate)
    }
}
