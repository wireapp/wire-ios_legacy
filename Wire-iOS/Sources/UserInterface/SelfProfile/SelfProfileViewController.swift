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

extension Notification.Name {
    static let DismissSettings = Notification.Name("DismissSettings")
}

extension SelfProfileViewController: SettingsPropertyFactoryDelegate {
    func asyncMethodDidStart(_ settingsPropertyFactory: SettingsPropertyFactory) {
        self.navigationController?.topViewController?.showLoadingView = true
    }

    func asyncMethodDidComplete(_ settingsPropertyFactory: SettingsPropertyFactory) {
        self.navigationController?.topViewController?.showLoadingView = false
    }


}

final internal class SelfProfileViewController: UIViewController {
    
     static let dismissNotificationName = "SettingsNavigationControllerDismissNotificationName"
    
    private let settingsController: SettingsTableViewController
    private let accountSelectorController = AccountSelectorController()
    private let profileContainerView = UIView()
    private let profileView: ProfileView
    
    internal var settingsCellDescriptorFactory: SettingsCellDescriptorFactory? = nil
    internal var rootGroup: (SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType)? = nil

    convenience init() {
        let settingsPropertyFactory = SettingsPropertyFactory(userSession: SessionManager.shared?.activeUserSession, selfUser: ZMUser.selfUser())

        let settingsCellDescriptorFactory = SettingsCellDescriptorFactory(settingsPropertyFactory: settingsPropertyFactory)
        let rootGroup = settingsCellDescriptorFactory.rootGroup()
        
        self.init(rootGroup: settingsCellDescriptorFactory.rootGroup())
        self.settingsCellDescriptorFactory = settingsCellDescriptorFactory
        self.rootGroup = rootGroup

        settingsPropertyFactory.delegate = self
    }
    
    init(rootGroup: SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType) {
        settingsController = rootGroup.generateViewController()! as! SettingsTableViewController
        profileView = ProfileView(user: ZMUser.selfUser())
        
        super.init(nibName: .none, bundle: .none)
                
        profileView.source = self
        profileView.imageView.addTarget(self, action: #selector(userDidTapProfileImage), for: .touchUpInside)
        
        settingsController.tableView.isScrollEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(SelfProfileViewController.dismissNotification(_:)), name: NSNotification.Name.DismissSettings, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileContainerView.shouldGroupAccessibilityChildren = false
        profileContainerView.isAccessibilityElement = false
        profileContainerView.addSubview(profileView)
        view.addSubview(profileContainerView)
        
        settingsController.willMove(toParent: self)
        view.addSubview(settingsController.view)
        addChild(settingsController)
        
        settingsController.view.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        settingsController.view.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        settingsController.tableView.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        settingsController.tableView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        
        createCloseButton()
        configureAccountTitle()
        createConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !presentNewLoginAlertControllerIfNeeded() {
            presentUserSettingChangeControllerIfNeeded()
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        dismiss()
        return true
    }
    
    private func dismiss() {
        dismiss(animated: true)
    }
    
    @objc func dismissNotification(_ notification: NSNotification) {
        dismiss()
    }
    
    private func createCloseButton() {
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
    }
    
    private func configureAccountTitle() {
        if SessionManager.shared?.accountManager.accounts.count > 1 {
            navigationItem.titleView = accountSelectorController.view
        } else {
            title = "self.account".localized.uppercased()
        }
    }
    
    private func createConstraints() {
        var selfViewTopMargin: CGFloat = 12

        if #available(iOS 11, *) {
        } else {
            if let navBarFrame = self.navigationController?.navigationBar.frame {
                selfViewTopMargin = 32 + navBarFrame.size.height
            }
        }

        constrain(view, profileContainerView) { selfView, profileContainerView in
            profileContainerView.top == selfView.topMargin + selfViewTopMargin
        }

        constrain(accountSelectorController.view) { accountSelectorControllerView in
            accountSelectorControllerView.height == 44
        }

        // Sometimes (i.e. after coming from background) the cells are not loaded yet. Reloading to calculate correct height.
        settingsController.tableView.reloadData()
        let height = CGFloat(56 * settingsController.tableView.numberOfRows(inSection: 0))
        
        constrain(view, settingsController.view, profileView, profileContainerView, settingsController.tableView) { view, settingsControllerView, profileView, profileContainerView, tableView in
            profileContainerView.leading == view.leading
            profileContainerView.trailing == view.trailing
            profileContainerView.bottom == settingsControllerView.top
            
            profileView.top >= profileContainerView.top
            profileView.centerY == profileContainerView.centerY
            profileView.leading == profileContainerView.leading
            profileView.trailing == profileContainerView.trailing
            profileView.bottom <= profileContainerView.bottom
            
            settingsControllerView.height == height
            settingsControllerView.leading == view.leading
            settingsControllerView.trailing == view.trailing
            settingsControllerView.bottom == view.bottom - UIScreen.safeArea.bottom
            
            tableView.edges == settingsControllerView.edges
        }
    }
    
    @objc func userDidTapProfileImage(sender: UserImageView) {
        let profileImageController = ProfileSelfPictureViewController()
        self.present(profileImageController, animated: true, completion: .none)
    }
}

