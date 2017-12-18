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
    public let imageView =  UserImageView(size: .big)
    public let nameLabel = UILabel()
    public let handleLabel = UILabel()
    public let teamNameLabel = UILabel()
    public var availabilityView = AvailabilityTitleView(user: ZMUser.selfUser(), style: .selfProfile)
    var stackView : UICustomSpacingStackView!
    var userObserverToken: NSObjectProtocol?
    var source: UIViewController?
    
    init(user: ZMUser) {
        super.init(frame: .zero)
        let session = SessionManager.shared?.activeUserSession
        imageView.accessibilityIdentifier = "user image"
        imageView.userSession = session
        imageView.user = user
        
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
        } else {
            teamNameLabel.isHidden = true
            availabilityView.isHidden = true
        }
        
        updateHandleLabel(user: user)
        
        stackView = UICustomSpacingStackView(customSpacedArrangedSubviews: [nameLabel, handleLabel, teamNameLabel, imageView, availabilityView])
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
    
    fileprivate func updateHandleLabel(user: ZMBareUser) {
        if let handle = user.handle, !handle.isEmpty {
            handleLabel.text = "@" + handle
            handleLabel.accessibilityValue = handleLabel.text
        }
        else {
            handleLabel.isHidden = true
        }
    }
    
    private func createConstraints() {
        constrain(self, stackView) { selfView, stackView in
            stackView.top == selfView.top
            stackView.bottom <= selfView.bottom
            stackView.leading == selfView.leading
            stackView.trailing == selfView.trailing
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
