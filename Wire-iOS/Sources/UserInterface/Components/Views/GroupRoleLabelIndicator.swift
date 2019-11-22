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

public class GroupRoleLabelIndicator: UIStackView, Themeable {
    
    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorSchemeOnSubviews(colorSchemeVariant)
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        label.textColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        groupRoleIcon.setIcon(.groupRole, size: .nano, color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant))
    }
    
    private let groupRoleIcon = UIImageView()
    private let label = UILabel()
    
    init() {
        groupRoleIcon.contentMode = .scaleToFill
        groupRoleIcon.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        groupRoleIcon.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        groupRoleIcon.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        groupRoleIcon.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        groupRoleIcon.setIcon(.groupRole, size: .nano, color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant))
        groupRoleIcon.accessibilityIdentifier = "img.group_role"
        
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = FontSpec(.medium, .semibold, .inputText).font
        label.textColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        label.text = "profile.details.group_admin".localized(uppercased: true)
        
        super.init(frame: .zero)
        
        axis = .horizontal
        spacing = 8
        distribution = .fill
        alignment = .fill
        addArrangedSubview(groupRoleIcon)
        addArrangedSubview(label)
        
        accessibilityIdentifier = "group role indicator"
    }
    
    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
