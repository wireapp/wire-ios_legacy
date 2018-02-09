//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import Cartography


class StartUIIconCell: UICollectionViewCell, Reusable {
    
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    
    fileprivate var icon: ZetaIconType? {
        didSet {
            iconView.image = icon.map { UIImage.init(for: $0, iconSize: .tiny, color: .white) }
        }
    }
    
    fileprivate var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupViews() {
        iconView.contentMode = .center
        titleLabel.font = FontSpec(.normal, .medium).font
        titleLabel.textColor = .white
        [iconView, titleLabel].forEach(contentView.addSubview)
    }
    
    fileprivate  func createConstraints() {
        let iconSize: CGFloat = 32.0
        
        constrain(contentView, iconView, titleLabel) { container, iconView, titleLabel in
            iconView.width == iconSize
            iconView.height == iconSize
            iconView.leading == container.leading + 16
            iconView.centerY == container.centerY
            
            titleLabel.leading == container.leading + 64
            titleLabel.trailing == container.trailing
            titleLabel.top == container.top
            titleLabel.bottom == container.bottom
        }
    }
    
}

final class InviteTeamMemberCell: StartUIIconCell  {

    override func setupViews() {
        super.setupViews()
        icon = .envelope
        title = "peoplepicker.invite_team_members".localized
    }
    
}

final class CreateGroupCell: StartUIIconCell  {
    
    override func setupViews() {
        super.setupViews()
        icon = .createConversation
        title = "peoplepicker.quick-action.create-conversation".localized
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityIdentifier = "button.searchui.creategroup"
    }
    
}
