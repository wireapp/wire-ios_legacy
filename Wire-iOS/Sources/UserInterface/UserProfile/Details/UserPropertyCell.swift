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
 * A cell that displays a user property as part of the extended profile metadata.
 */

class UserPropertyCell: UITableViewCell, Themeable {
    
    private let contentStack = UIStackView()

    private let propertyNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .smallMediumFont
        return label
    }()
    
    private let propertyValueLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .normalLightFont
        return label
    }()
    
    // MARK: - Contents
    
    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }
    
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
        configureConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSubviews() {
        contentStack.addArrangedSubview(propertyNameLabel)
        contentStack.addArrangedSubview(propertyValueLabel)
        contentStack.spacing = 2
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        contentStack.axis = .vertical
        contentView.addSubview(contentStack)
        
        applyColorScheme(colorSchemeVariant)
        shouldGroupAccessibilityChildren = true
    }
    
    private func configureConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            contentStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    // MARK: - Configuration
    
    func applyColorScheme(_ variant: ColorSchemeVariant) {
        propertyNameLabel.textColor = UIColor.from(scheme: .textDimmed, variant: variant)
        propertyValueLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        backgroundColor = UIColor.from(scheme: .background, variant: variant)
    }
    
}
