//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import HockeySDK.BITHockeyManager


@objc class SettingsNavigationController: UINavigationController {

    let rootGroup: SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType
    static let dismissNotificationName = "SettingsNavigationControllerDismissNotificationName"
    
    let settingsPropertyFactory: SettingsPropertyFactory
    @objc var dismissAction: ((SettingsNavigationController) -> ())? = .none
    
    fileprivate let pushTransition = PushTransition()
    fileprivate let popTransition = PopTransition()
    fileprivate var dismissGestureRecognizer: UIScreenEdgePanGestureRecognizer!
    
    static func settingsNavigationController() -> SettingsNavigationController {
        let settingsPropertyFactory = SettingsPropertyFactory(userDefaults: UserDefaults.standard,
            analytics: Analytics.shared(),
            mediaManager: AVSProvider.shared.mediaManager,
            userSession: ZMUserSession.shared()!,
            selfUser: ZMUser.selfUser(),
            crashlogManager: BITHockeyManager.shared())
        
        let settingsCellDescriptorFactory = SettingsCellDescriptorFactory(settingsPropertyFactory: settingsPropertyFactory)
        
        let settingsNavigationController = SettingsNavigationController(rootGroup: settingsCellDescriptorFactory.rootSettingsGroup(), settingsPropertyFactory: settingsPropertyFactory)
        return settingsNavigationController
    }
    
    required init(rootGroup: SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType, settingsPropertyFactory: SettingsPropertyFactory) {
        self.rootGroup = rootGroup
        self.settingsPropertyFactory = settingsPropertyFactory
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
        
        self.transitioningDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsNavigationController.soundIntensityChanged(_:)), name: NSNotification.Name(rawValue: SettingsPropertyName.soundAlerts.changeNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsNavigationController.dismissNotification(_:)), name: NSNotification.Name(rawValue: type(of: self).dismissNotificationName), object: nil)
    }
    
    @discardableResult func openControllerForCellWithIdentifier(_ identifier: String) -> UIViewController? {
        var resultViewController: UIViewController? = .none
        // Let's assume for the moment that menu is only 2 levels deep
        self.rootGroup.allCellDescriptors().forEach({ (topCellDescriptor: SettingsCellDescriptorType) -> () in
            
            if let cellIdentifier = topCellDescriptor.identifier,
                let cellGroupDescriptor = topCellDescriptor as? SettingsControllerGeneratorType,
                let viewController = cellGroupDescriptor.generateViewController(),
                cellIdentifier == identifier
            {
                self.pushViewController(viewController, animated: false)
                resultViewController = viewController
            }
            
            if let topCellGroupDescriptor = topCellDescriptor as? SettingsInternalGroupCellDescriptorType & SettingsControllerGeneratorType {
                topCellGroupDescriptor.allCellDescriptors().forEach({ (cellDescriptor: SettingsCellDescriptorType) -> () in
                    if let cellIdentifier = cellDescriptor.identifier,
                        let cellGroupDescriptor = cellDescriptor as? SettingsControllerGeneratorType,
                        let topViewController = topCellGroupDescriptor.generateViewController(),
                        let viewController = cellGroupDescriptor.generateViewController(),
                        cellIdentifier == identifier
                    {
                        self.pushViewController(topViewController, animated: false)
                        self.pushViewController(viewController, animated: false)
                        resultViewController = viewController
                    }
                })
            }
            
        })
        return resultViewController
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func soundIntensityChanged(_ notification: Notification) {
        let soundProperty = self.settingsPropertyFactory.property(.soundAlerts)
        
        if let intensivityLevel = soundProperty.rawValue() as? AVSIntensityLevel {
            switch(intensivityLevel) {
            case .full:
                Analytics.shared()?.tagSoundIntensityPreference(SoundIntensityTypeAlways)
            case .some:
                Analytics.shared()?.tagSoundIntensityPreference(SoundIntensityTypeFirstOnly)
            case .none:
                Analytics.shared()?.tagSoundIntensityPreference(SoundIntensityTypeNever)
            }
        }
    }
    
    func dismissNotification(_ notification: NSNotification) {
        self.dismissAction?(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.interactivePopGestureRecognizer?.isEnabled = false
        
        if let rootViewController = self.rootGroup.generateViewController() {
            Analytics.shared()?.tagScreen("SETTINGS")
            self.pushViewController(rootViewController, animated: false)
            if let settingsTableController = rootViewController as? SettingsTableViewController {
                let inviteView = InviteButtonView(frame: .zero)
                inviteView.onTap = { [weak self] in
                    self?.wr_presentInviteActivityViewController(withSourceView: $0, logicalContext: .settings)
                }
                settingsTableController.footer = inviteView
                settingsTableController.dismissAction = { [unowned self] _ in
                    self.dismissAction?(self)
                }
            }
        }
        
        self.navigationBar.setBackgroundImage(UIImage(), for:.default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont(magicIdentifier: "style.text.normal.font_spec").allCaps()]
        
        let navButtonAppearance = UIBarButtonItem.wr_appearanceWhenContained(in: UINavigationBar.self)
                
        navButtonAppearance?.setTitleTextAttributes([NSFontAttributeName : UIFont(magicIdentifier: "style.text.normal.font_spec").allCaps()], for: UIControlState.normal)
        
        self.dismissGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(SettingsNavigationController.onEdgeSwipe(gestureRecognizer:)))
        self.dismissGestureRecognizer.edges = [.left]
        self.dismissGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(self.dismissGestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presentNewLoginAlertControllerIfNeeded()
    }
    
    func onEdgeSwipe(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        if gestureRecognizer.state == .recognized {
            self.popViewController(animated: true)
        }
    }
    
    fileprivate func presentNewLoginAlertControllerIfNeeded() {
        let clientsRequiringUserAttention = ZMUser.selfUser().clientsRequiringUserAttention
        
        if (clientsRequiringUserAttention?.count)! > 0 {
            self.presentNewLoginAlertController(clientsRequiringUserAttention!)
        }
    }
    
    fileprivate func presentNewLoginAlertController(_ clients: Set<UserClient>) {
        let newLoginAlertController = UIAlertController(forNewSelfClients: clients)
        
        let actionManageDevices = UIAlertAction(title: "self.new_device_alert.manage_devices".localized, style:.default) { _ in
            self.openControllerForCellWithIdentifier(SettingsCellDescriptorFactory.settingsDevicesCellIdentifier)
        }
        
        newLoginAlertController?.addAction(actionManageDevices)
        
        let actionTrustDevices = UIAlertAction(title:"self.new_device_alert.trust_devices".localized, style:.default, handler:.none)
        
        newLoginAlertController?.addAction(actionTrustDevices)
        
        self.present(newLoginAlertController!, animated:true, completion:.none)
        
        ZMUserSession.shared()?.enqueueChanges {
            clients.forEach {
                $0.needsToNotifyUser = false
            }
        }
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait]
    }

}

extension SettingsNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
         animationControllerFor operation: UINavigationControllerOperation,
                         from fromVC: UIViewController,
                             to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            return self.pushTransition
        case .pop:
            return self.popTransition
        default:
            fatalError()
        }
    }
}

extension SettingsNavigationController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = SwizzleTransition()
        transition.direction = .vertical
        return transition
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = SwizzleTransition()
        transition.direction = .vertical
        return transition
    }
}

extension SettingsNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
