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

@objcMembers internal class ProfileView: UIView {
    public let imageView =  UserImageView(size: .big)
    public let nameLabel = UILabel()
    public let handleLabel = UILabel()
    public let teamNameLabel = UILabel()
    public var availabilityView = AvailabilityTitleView(user: ZMUser.selfUser(), style: .selfProfile)
    var stackView : CustomSpacingStackView!
    var userObserverToken: NSObjectProtocol?
    weak var source: UIViewController?
    
    init(user: ZMUser) {
        super.init(frame: .zero)
        let session = SessionManager.shared?.activeUserSession
        imageView.accessibilityIdentifier = "user image"
        imageView.userSession = session
        imageView.user = user
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "self.profile.change_user_image.accessibility".localized
        imageView.accessibilityTraits = .button
        imageView.accessibilityElementsHidden = false
        
        availabilityView.tapHandler = { [weak self] button in
            guard let `self` = self else { return }
            let alert = self.availabilityView.actionSheet
            alert.popoverPresentationController?.sourceView = self
            alert.popoverPresentationController?.sourceRect = self.availabilityView.frame
            self.source?.present(alert, animated: true, completion: nil)
        }
        
        if let session = session {
            userObserverToken = UserChangeInfo.add(observer: self, for: user, userSession: session)
        }
        
        nameLabel.accessibilityLabel = "profile_view.accessibility.name".localized
        nameLabel.accessibilityIdentifier = "name"
        nameLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        nameLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        nameLabel.font = FontSpec(.large, .light).font!
        handleLabel.accessibilityLabel = "profile_view.accessibility.handle".localized
        handleLabel.accessibilityIdentifier = "username"
        handleLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        handleLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        handleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        handleLabel.font = FontSpec(.small, .regular).font!
        teamNameLabel.accessibilityLabel = "profile_view.accessibility.team_name".localized
        teamNameLabel.accessibilityIdentifier = "team name"
        teamNameLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        teamNameLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        teamNameLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        teamNameLabel.font = FontSpec(.small, .regular).font!
        
        nameLabel.text = user.name
        nameLabel.accessibilityValue = nameLabel.text
        
        if let team = user.team, let teamName = team.name {
            teamNameLabel.text = teamName.uppercased()
            teamNameLabel.accessibilityValue = teamNameLabel.text
        } else {
            teamNameLabel.isHidden = true
            availabilityView.isHidden = true
        }
        
        updateHandleLabel(user: user)
        
        stackView = CustomSpacingStackView(customSpacedArrangedSubviews: [nameLabel, handleLabel, teamNameLabel, imageView, availabilityView])
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.wr_addCustomSpacing(32, after: handleLabel)
        stackView.wr_addCustomSpacing(32, after: teamNameLabel)
        stackView.wr_addCustomSpacing(32, after: imageView)
        stackView.wr_addCustomSpacing(32, after: availabilityView)
        addSubview(stackView)
        
        self.createConstraints()
    }
    
    fileprivate func updateHandleLabel(user: UserType) {
        if let handle = user.handle, !handle.isEmpty {
            handleLabel.text = "@" + handle
            handleLabel.accessibilityValue = handleLabel.text
        }
        else {
            handleLabel.isHidden = true
        }
    }
    
    private func createConstraints() {
        constrain(self, stackView, imageView) { selfView, stackView, imageView in
            stackView.top == selfView.top
            stackView.bottom <= selfView.bottom
            stackView.leading == selfView.leading
            stackView.trailing == selfView.trailing
            imageView.leading >= selfView.leading + 40
            imageView.trailing <= selfView.trailing - 40
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileView: ZMUserObserver {
    func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.nameChanged {
            nameLabel.text = changeInfo.user.name
        }
        if changeInfo.handleChanged {
            updateHandleLabel(user: changeInfo.user)
        }
    }
}
