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

@objc internal class ProfileView: UIView {
    public let imageView = UserImageView(size: .big)
    public let nameLabel = UILabel()
    public let handleLabel = UILabel()
    public let teamNameLabel = UILabel()
    public var teamView: TeamImageView?
    
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
            teamNameLabel.text = "profile_view.team_name.in".localized(args: teamName)
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
        
        if user.team != nil, let account = SessionManager.shared?.accountManager.selectedAccount {
            let teamView = TeamImageView(account: account)
            teamView.style = .big
            addSubview(teamView)
            self.teamView = teamView
        }
        
        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(self, imageView, nameLabel, handleLabel, teamNameLabel) { selfView, imageView, nameLabel, handleLabel, teamNameLabel in
            
            nameLabel.top == selfView.top
            nameLabel.centerX == selfView.centerX
            nameLabel.leading >= selfView.leading
            nameLabel.trailing <= selfView.trailing
            
            handleLabel.top == nameLabel.bottom + 24 ~ LayoutPriority(750.0)
            handleLabel.top >= nameLabel.bottom
            handleLabel.centerX == selfView.centerX
            handleLabel.leading >= selfView.leading
            handleLabel.trailing <= selfView.trailing
            
            imageView.top == handleLabel.bottom + 32 ~ LayoutPriority(750.0)
            imageView.top >= handleLabel.bottom
            imageView.width == imageView.height
            imageView.width <= 200
            imageView.centerX == selfView.centerX
            imageView.leading >= selfView.leading
            imageView.trailing <= selfView.trailing
            
            imageView.bottom == teamNameLabel.top - 32 ~ LayoutPriority(750.0)
            imageView.bottom <= teamNameLabel.top
            
            teamNameLabel.bottom == selfView.bottom
            teamNameLabel.centerX == selfView.centerX
            teamNameLabel.leading >= selfView.leading
            teamNameLabel.trailing <= selfView.trailing
        }
        
        if let teamView = self.teamView {
            constrain(imageView, teamView) { imageView, teamView in
                teamView.width == teamView.height
                teamView.width == 64
                
                teamView.trailing == imageView.trailing
                teamView.bottom == imageView.bottom
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension IconButton {
    public static func closeButton() -> IconButton {
        let closeButton = IconButton.iconButtonDefaultLight()
        closeButton.setIcon(.X, with: .tiny, for: .normal)
        closeButton.frame = CGRect(x: 0, y: 0, width: 32, height: 20)
        closeButton.accessibilityIdentifier = "close"
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -16)
        return closeButton
    }
}

final internal class SelfProfileViewController: UIViewController {
    private let settingsController: SettingsTableViewController
    private let profileContainerView = UIView()
    private let profileView: ProfileView
    @objc var dismissAction: (() -> ())? = .none

    
    init(rootGroup: SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType) {
        settingsController = rootGroup.generateViewController()! as! SettingsTableViewController
        
        profileView = ProfileView(user: ZMUser.selfUser())
        super.init(nibName: .none, bundle: .none)
        
        settingsController.tableView.isScrollEnabled = false
        
        profileView.imageView.delegate = self

        title = "self.profile".localized
        
        let closeButton = IconButton.closeButton()
        closeButton.addTarget(self, action: #selector(onCloseTouchUpInside(_:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileContainerView.addSubview(profileView)
        view.addSubview(profileContainerView)
        
        settingsController.willMove(toParentViewController: self)
        view.addSubview(settingsController.view)
        addChildViewController(settingsController)
        
        settingsController.view.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        settingsController.view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        settingsController.tableView.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        settingsController.tableView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(view, settingsController.view, profileView, profileContainerView) { view, settingsControllerView, profileView, profileContainerView in
            profileContainerView.top == self.topLayoutGuideCartography
            profileContainerView.leading == view.leading
            profileContainerView.trailing == view.trailing
            profileContainerView.bottom == settingsControllerView.top
            
            profileView.top >= profileContainerView.top
            profileView.centerY == profileContainerView.centerY
            profileView.leading == profileContainerView.leading
            profileView.trailing == profileContainerView.trailing
            profileView.bottom <= profileContainerView.bottom

            settingsControllerView.leading == view.leading
            settingsControllerView.trailing == view.trailing
            settingsControllerView.bottom == view.bottom
        }
    }
    
    @objc func onCloseTouchUpInside(_ sender: AnyObject!) {
        self.dismissAction?()
    }
}

extension SelfProfileViewController: UserImageViewDelegate {
    func userImageViewTouchUp(inside userImageView: UserImageView) {
        let profileImageController = ProfileSelfPictureViewController()
        self.present(profileImageController, animated: true, completion: .none)
    }
}
