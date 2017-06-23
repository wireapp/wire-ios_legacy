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
    
    init(user: ZMUser) {
        super.init(frame: .zero)
        imageView.accessibilityIdentifier = "user image"
        imageView.user = user
        
        teamNameLabel.accessibilityLabel = "profile_view.accessibility.team_name".localized
        teamNameLabel.accessibilityIdentifier = "team name"
        nameLabel.accessibilityLabel = "profile_view.accessibility.name".localized
        nameLabel.accessibilityIdentifier = "name"
        handleLabel.accessibilityLabel = "profile_view.accessibility.handle".localized
        handleLabel.accessibilityIdentifier = "username"
        
        nameLabel.text = user.name
        nameLabel.accessibilityValue = nameLabel.text
        
        if let teamName = user.team?.name {
            teamNameLabel.text = String(format: "profile_view.team_name.in".localized, teamName)
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
            
            handleLabel.top == nameLabel.bottom + 12
            handleLabel.centerX == selfView.centerX
            handleLabel.leading >= selfView.leading
            handleLabel.trailing <= selfView.trailing
            
            imageView.top == handleLabel.bottom + 12
            
            imageView.width == imageView.height
            imageView.width <= 200
            imageView.center == selfView.center
            imageView.leading >= selfView.leading
            imageView.trailing <= selfView.trailing
            
            imageView.bottom == teamNameLabel.top - 24
            
            teamNameLabel.bottom <= selfView.bottom
            teamNameLabel.centerX == selfView.centerX
            teamNameLabel.leading >= selfView.leading
            teamNameLabel.trailing <= selfView.trailing
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
    private let settingsController: UIViewController
    private let profileView: ProfileView
    @objc var dismissAction: (() -> ())? = .none

    
    init(rootGroup: SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType) {
        self.settingsController = rootGroup.generateViewController()!
        
        self.profileView = ProfileView(user: ZMUser.selfUser())
        super.init(nibName: .none, bundle: .none)
        
        if let settingsTableController = self.settingsController as? SettingsTableViewController {
            settingsTableController.tableView.isScrollEnabled = false
        }
        
        self.profileView.imageView.delegate = self

        self.title = "self.profile".localized
        
        let closeButton = IconButton.closeButton()
        closeButton.addTarget(self, action: #selector(onCloseTouchUpInside(_:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(profileView)
        
        settingsController.willMove(toParentViewController: self)
        view.addSubview(settingsController.view)
        addChildViewController(settingsController)
        
        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(view, settingsController.view, profileView) { view, settingsControllerView, profileView in
            profileView.top == view.top
            profileView.leading == view.leading
            profileView.trailing == view.trailing

            settingsControllerView.top == profileView.bottom
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
