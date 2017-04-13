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
    
    init(user: ZMUser) {
        super.init(frame: .zero)
        self.imageView.user = user
        self.nameLabel.text = user.displayName
        self.handleLabel.text = "@" + user.handle
        
        [imageView, nameLabel, handleLabel].forEach(self.addSubview)
        
        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(self, imageView, nameLabel, handleLabel) { selfView, imageView, nameLabel, handleLabel in
            
            nameLabel.top >= selfView.top
            nameLabel.centerX == selfView.centerX
            nameLabel.leading >= selfView.leading
            nameLabel.trailing <= selfView.trailing
            
            imageView.top == nameLabel.bottom + 24
            
            imageView.width == imageView.height
            imageView.width <= 200
            imageView.center == selfView.center
            imageView.leading >= selfView.leading
            imageView.trailing <= selfView.trailing
            
            imageView.bottom == handleLabel.top - 24
            
            handleLabel.bottom <= selfView.bottom
            handleLabel.centerX == selfView.centerX
            handleLabel.leading >= selfView.leading
            handleLabel.trailing <= selfView.trailing
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
    private var inviteButtonView: InviteButtonView!
    @objc var dismissAction: (() -> ())? = .none

    
    init(rootGroup: SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType) {
        self.settingsController = rootGroup.generateViewController()!
        
        self.profileView = ProfileView(user: ZMUser.selfUser())
        
        super.init(nibName: .none, bundle: .none)
        
        if let settingsTableController = self.settingsController as? SettingsTableViewController {
            settingsTableController.tableView.isScrollEnabled = false
        }
        
        self.inviteButtonView = InviteButtonView(onTap: { [weak self] in
            self?.wr_presentInviteActivityViewController(withSourceView: $0, logicalContext: .settings)
        })
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
        
        [profileView, inviteButtonView].forEach(self.view.addSubview)
        
        settingsController.willMove(toParentViewController: self)
        view.addSubview(settingsController.view)
        addChildViewController(settingsController)
        
        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(view, settingsController.view, profileView, inviteButtonView) { view, settingsControllerView, profileView, inviteButtonView in
            profileView.top == view.top
            profileView.leading == view.leading
            profileView.trailing == view.trailing

            settingsControllerView.top == profileView.bottom
            settingsControllerView.leading == view.leading
            settingsControllerView.trailing == view.trailing
            settingsControllerView.bottom == inviteButtonView.top
            
            inviteButtonView.leading == view.leading
            inviteButtonView.trailing == view.trailing
            inviteButtonView.bottom == view.bottom
        }
    }
    
    @objc func onCloseTouchUpInside(_ sender: AnyObject!) {
        self.dismissAction?()
    }
}

