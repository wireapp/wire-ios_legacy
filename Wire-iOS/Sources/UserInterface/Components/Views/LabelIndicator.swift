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

enum LabelIndicatorContext {
    case guest,
         groupRole,
         external
    
    var icon: StyleKitIcon {
        switch self {
        case .guest:
            return .guest
        case .groupRole:
            return .groupAdmin
        case .external:
            return .externalPartner
        }
    }
    
    var title: String {
        switch self {
        case .guest:
            return "profile.details.guest"
        case .groupRole:
            return "profile.details.group_admin"
        case .external:
            return "profile.details.partner"
        }

    }
}

final class LabelIndicator: UIView, Themeable {
    
    private let indicatorIcon = UIImageView()
    private let titleLabel = UILabel()
    private let containerView = UIView()
    private let context: LabelIndicatorContext

    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorSchemeOnSubviews(colorSchemeVariant)
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        
        indicatorIcon.setIcon(context.icon,
                              size: .nano,
                              color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant))
    }
    
    init(context: LabelIndicatorContext) {
        self.context = context
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        var accessibilityString: String
        
        switch context {
        case .guest:
            accessibilityString = "guest"
        case .groupRole:
            accessibilityString = "group_role"
        case .external:
            accessibilityString = "team_role"
        }
        titleLabel.accessibilityIdentifier = "label." + accessibilityString
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        titleLabel.font = FontSpec(.medium, .semibold, .inputText).font
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        titleLabel.text = context.title.localized(uppercased: true)
        
        indicatorIcon.accessibilityIdentifier =  "img." + accessibilityString
        indicatorIcon.setIcon(context.icon, size: .nano, color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant))
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(indicatorIcon)
        accessibilityIdentifier = accessibilityString + " indicator"
        
        addSubview(containerView)
    }
    
    private func createConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        indicatorIcon.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: containerView.topAnchor),
            
            // containerView
            containerView.heightAnchor.constraint(equalToConstant: 6),
            containerView.leadingAnchor.constraint(equalTo: safeLeadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: safeTrailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: safeBottomAnchor),
            
            // indicatorIcon
            indicatorIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            indicatorIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            // titleLabel
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: indicatorIcon.trailingAnchor, constant: 6)
            ])
    }
}
