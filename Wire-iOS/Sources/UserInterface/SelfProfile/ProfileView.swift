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


import Foundation
import Cartography

@objc internal class ProfileView: UIView {
    public let imageView = UserImageView(size: .big)
    public let nameLabel = UILabel()
    public let handleLabel = UILabel()
    public let teamNameLabel = UILabel()
    
    init(user: ZMUser) {
        super.init(frame: .zero)
        imageView.accessibilityIdentifier = "user image"
        imageView.user = user
        
        nameLabel.accessibilityLabel = "profile_view.accessibility.name".localized
        nameLabel.accessibilityIdentifier = "name"
        nameLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        handleLabel.accessibilityLabel = "profile_view.accessibility.handle".localized
        handleLabel.accessibilityIdentifier = "username"
        handleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        handleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        teamNameLabel.accessibilityLabel = "profile_view.accessibility.team_name".localized
        teamNameLabel.accessibilityIdentifier = "team name"
        teamNameLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        teamNameLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        
        nameLabel.text = user.name
        nameLabel.accessibilityValue = nameLabel.text
        
        if let team = user.team, let teamName = team.name {
            teamNameLabel.text = teamName.uppercased()
            teamNameLabel.accessibilityValue = teamNameLabel.text
        }
        else {
            teamNameLabel.isHidden = true
        }
        
        if let handle = user.handle, !handle.isEmpty {
            handleLabel.text = "@" + handle
            handleLabel.accessibilityValue = handleLabel.text
        }
        else {
            handleLabel.isHidden = true
        }
        
        [imageView, nameLabel, handleLabel, teamNameLabel].forEach(addSubview)
        
        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(self, imageView, nameLabel, handleLabel, teamNameLabel) { selfView, imageView, nameLabel, handleLabel, teamNameLabel in
            
            nameLabel.top >= selfView.top
            nameLabel.centerX == selfView.centerX
            nameLabel.leading >= selfView.leading
            nameLabel.trailing <= selfView.trailing
            
            handleLabel.top == nameLabel.bottom + 4
            handleLabel.centerX == selfView.centerX
            handleLabel.leading >= selfView.leading
            handleLabel.trailing <= selfView.trailing
            
            teamNameLabel.bottom == handleLabel.bottom + 24
            teamNameLabel.centerX == selfView.centerX
            teamNameLabel.leading >= selfView.leading
            teamNameLabel.trailing <= selfView.trailing
            
            imageView.top == teamNameLabel.bottom + 32 ~ LayoutPriority(750.0)
            imageView.top >= teamNameLabel.bottom + 16
            imageView.width == imageView.height
            imageView.width <= 240
            imageView.centerX == selfView.centerX
            imageView.leading >= selfView.leading
            imageView.trailing <= selfView.trailing
            
            imageView.bottom == selfView.bottom - 32 ~ LayoutPriority(750.0)
            imageView.bottom <= selfView.bottom - 24
            
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
