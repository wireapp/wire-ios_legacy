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
    private let accountSelectorController = AccountSelectorController()
    private let profileContainerView = UIView()
    private let profileView: ProfileView
    private let accountLabel = UILabel()
    @objc var dismissAction: (() -> ())? = .none

    
    init(rootGroup: SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType) {
        settingsController = rootGroup.generateViewController()! as! SettingsTableViewController
        
        profileView = ProfileView(user: ZMUser.selfUser())
        super.init(nibName: .none, bundle: .none)
        
        settingsController.tableView.isScrollEnabled = false
        
        profileView.imageView.delegate = self
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
        
        accountSelectorController.willMove(toParentViewController: self)
        view.addSubview(accountSelectorController.view)
        addChildViewController(accountSelectorController)
        
        view.addSubview(accountLabel)
        
        settingsController.view.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        settingsController.view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        settingsController.tableView.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        settingsController.tableView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        
        createCloseButton()
        configureAccountLabel()
        createConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    private func createCloseButton() {
        let closeButton = IconButton.closeButton()
        closeButton.addTarget(self, action: #selector(onCloseTouchUpInside(_:)), for: .touchUpInside)
        self.view.addSubview(closeButton)
        constrain(closeButton, self.view) { closeButton, selfView in
            closeButton.top == selfView.top + 12
            closeButton.trailing == selfView.trailing - 24
        }
    }
    
    private func configureAccountLabel() {
        accountLabel.textAlignment = .center
        accountLabel.isHidden = SessionManager.shared?.accountManager.accounts.count > 1
        accountLabel.text = "self.account".localized.uppercased()
        accountLabel.accessibilityTraits = UIAccessibilityTraitHeader
        accountLabel.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: .dark)
        accountLabel.font = FontSpec(.medium, .semibold).font
    }
    
    private func createConstraints() {
        constrain(view, accountSelectorController.view, profileContainerView, accountLabel) { selfView, accountSelectorControllerView, profileContainerView, accountLabel in
            accountSelectorControllerView.leading >= selfView.leading
            accountSelectorControllerView.trailing <= selfView.trailing
            accountSelectorControllerView.top == selfView.top + 7
            accountSelectorControllerView.centerX == selfView.centerX
            accountSelectorControllerView.height == 46
            
            accountLabel.top == selfView.top + 7
            accountLabel.leading >= selfView.leading
            accountLabel.trailing >= selfView.trailing
            accountLabel.centerX == selfView.centerX
            accountLabel.height == 46
            
            profileContainerView.top == accountSelectorControllerView.bottom + 12   
        }
        
        constrain(view, settingsController.view, profileView, profileContainerView) { view, settingsControllerView, profileView, profileContainerView in
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
