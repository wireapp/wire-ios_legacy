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

final class GroupRoleLabelIndicator: UIView {

    private let variant: ColorSchemeVariant
    private let groupRoleIcon = UIImageView()
    private let titleLabel = UILabel()
    private let containerView = UIView()
    
    init() {
        self.variant = ColorScheme.default.variant
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        titleLabel.accessibilityIdentifier =  "label.group_role"
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        titleLabel.font = FontSpec(.medium, .semibold, .inputText).font
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        titleLabel.text = "profile.details.group_admin".localized(uppercased: true)
        
        groupRoleIcon.accessibilityIdentifier =  "img.group_role"
        groupRoleIcon.setIcon(.groupAdmin, size: .nano, color: UIColor.from(scheme: .textForeground, variant: variant))
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(groupRoleIcon)
        addSubview(containerView)
    }
    
    private func createConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        groupRoleIcon.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: containerView.topAnchor),
            
            // containerView
            containerView.heightAnchor.constraint(equalToConstant: 56),
            containerView.leadingAnchor.constraint(equalTo: safeLeadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: safeTrailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: safeBottomAnchor),
            
            // groupRoleIcon
            groupRoleIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            groupRoleIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            // titleLabel
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: groupRoleIcon.trailingAnchor, constant: 6)
            ])
    }
}
