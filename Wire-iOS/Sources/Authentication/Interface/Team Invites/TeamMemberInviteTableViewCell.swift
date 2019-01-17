//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Cartography

fileprivate extension InviteResult {
    var iconType: ZetaIconType {
        switch self {
        case .success: return .checkmark
        case .failure: return .exclamationMarkCircle
        }
    }
}

final class TeamMemberInviteTableViewCell: UITableViewCell {
    
    private let emailLabel = UILabel()
    private let errorLabel = UILabel()
    private let stackView = UIStackView()
    private let iconImageView = UIImageView()
    
    var content: InviteResult? {
        didSet {
            switch content {
            case let .success(email)?:
                errorLabel.isHidden = true
                emailLabel.text = email
            case let .failure(email, error)?:
                errorLabel.isHidden = false
                emailLabel.text = email
                errorLabel.text = error.errorDescription
            default: break
            }
            
            content.apply {
                iconImageView.image = UIImage(
                    for: $0.iconType,
                    iconSize: .tiny,
                    color: UIColor.Team.inactiveButton
                )
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        stackView.axis = .vertical
        emailLabel.font = FontSpec(.normal, .regular).font!
        emailLabel.textColor = UIColor.Team.subtitleColor
        errorLabel.font = FontSpec(.small, .regular).font!
        errorLabel.textColor = UIColor.Team.errorMessageColor
        backgroundColor = .clear
        contentView.addSubview(stackView)
        [emailLabel, errorLabel].forEach(stackView.addArrangedSubview)
        stackView.spacing = 2
        contentView.addSubview(iconImageView)
    }
    
    private func createConstraints() {
        constrain(contentView, stackView, iconImageView) { contentView, stackView, iconImageView in
            stackView.leading == contentView.leading + 24
            stackView.centerY == contentView.centerY
            stackView.trailing <= iconImageView.leading - 8
            iconImageView.centerY == contentView.centerY
            iconImageView.trailing == contentView.trailing - 24
        }
    }
}
