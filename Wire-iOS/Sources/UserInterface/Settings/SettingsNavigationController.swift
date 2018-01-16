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

@objc class SettingsNavigationController: ClearBackgroundNavigationController {

    let rootGroup: SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType
    static let dismissNotificationName = "SettingsNavigationControllerDismissNotificationName"
    
    let settingsPropertyFactory: SettingsPropertyFactory
    @objc var dismissAction: ((SettingsNavigationController) -> ())? = .none
    
    static func settingsNavigationController() -> SettingsNavigationController {
        let settingsPropertyFactory = SettingsPropertyFactory(userSession: SessionManager.shared?.activeUserSession, selfUser: ZMUser.selfUser())
        
        let settingsCellDescriptorFactory = SettingsCellDescriptorFactory(settingsPropertyFactory: settingsPropertyFactory)
        
        let settingsNavigationController = SettingsNavigationController(rootGroup: settingsCellDescriptorFactory.rootGroup(), settingsPropertyFactory: settingsPropertyFactory)
        return settingsNavigationController
    }
    
    required init(rootGroup: SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType, settingsPropertyFactory: SettingsPropertyFactory) {
        self.rootGroup = rootGroup
        self.settingsPropertyFactory = settingsPropertyFactory
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
        
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
    
    func soundIntensityChanged(_ notification: Notification) {
        let soundProperty = self.settingsPropertyFactory.property(.soundAlerts)
        
        if let intensivityLevel = soundProperty.rawValue() as? AVSIntensityLevel {
            switch(intensivityLevel) {
            case .full:
                Analytics.shared().tagSoundIntensityPreference(SoundIntensityTypeAlways)
            case .some:
                Analytics.shared().tagSoundIntensityPreference(SoundIntensityTypeFirstOnly)
            case .none:
                Analytics.shared().tagSoundIntensityPreference(SoundIntensityTypeNever)
            }
        }
    }
    
    func dismissNotification(_ notification: NSNotification) {
        self.dismissAction?(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rootViewController = SelfProfileViewController(rootGroup: rootGroup)

        self.pushViewController(rootViewController, animated: false)
        rootViewController.dismissAction = { [unowned self] _ in
            self.dismissAction?(self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presentNewLoginAlertControllerIfNeeded()
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

