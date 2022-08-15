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

import UIKit

/**
 * A cell that displays a user property as part of the rich profile data.
 */

final class UserPropertyCell: SeparatorTableViewCell {

    private let contentStack = UIStackView()

    private let propertyNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.font = .smallRegularFont
        label.textColor = SemanticColors.Label.textUserPropertyCellName
        return label
    }()

    private let propertyValueLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.font = .normalLightFont
        return label
    }()

    // MARK: - Contents

    /// The name of the user property.
    var propertyName: String? {
        get {
            return propertyNameLabel.text
        }
        set {
            propertyNameLabel.text = newValue
            accessibilityIdentifier = "InformationKey" + (newValue ?? "None")
            accessibilityLabel = newValue
        }
    }

    /// The value of the user property.
    var propertyValue: String? {
        get {
            return propertyValueLabel.text
        }
        set {
            propertyValueLabel.text = newValue
            accessibilityValue = newValue
        }
    }

    // MARK: - Initialization

    override func setUp() {
        super.setUp()
        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {
        backgroundColor = SemanticColors.View.backgroundUserCell

        addBorder(for: .top)
        addBorder(for: .bottom)

        separator.isHidden = true
        separator.backgroundColor = .clear
        showSeparator = false

        contentStack.addArrangedSubview(propertyNameLabel)
        contentStack.addArrangedSubview(propertyValueLabel)
        contentStack.spacing = 2
        contentStack.axis = .vertical
        contentStack.distribution = .equalSpacing
        contentStack.alignment = .leading
        contentView.addSubview(contentStack)

        applyColorScheme(colorSchemeVariant)
        shouldGroupAccessibilityChildren = true
        backgroundColor = SemanticColors.View.backgroundUserCell
        [.top, .bottom].forEach { addBorder(for: $0) }
        separator.isHidden = true
    }

    private func configureConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Configuration

    override func applyColorScheme(_ variant: ColorSchemeVariant) {
        super.applyColorScheme(variant)
        propertyNameLabel.textColor = SemanticColors.Label.textUserPropertyCellName
        propertyValueLabel.textColor = SemanticColors.Label.textDefault
    }

}
