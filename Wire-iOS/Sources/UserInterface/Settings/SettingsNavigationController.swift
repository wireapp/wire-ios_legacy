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

@objc class SettingsNavigationController: UINavigationController {
    let rootGroup: protocol<SettingsControllerGeneratorType, SettingsInternalGroupCellDescriptorType>
    let settingsPropertyFactory: SettingsPropertyFactory
    
    private let pushTransition = PushTransition()
    private let popTransition = PopTransition()
    
    static func settingsNavigationController() -> SettingsNavigationController {
        let settingsPropertyFactory = SettingsPropertyFactory(userDefaults: NSUserDefaults.standardUserDefaults(),
            analytics: Analytics.shared(),
            mediaManager: AVSProvider.shared.mediaManager,
            userSession: ZMUserSession.sharedSession(),
            selfUser: ZMUser.selfUser())
        
        let settingsCellDescriptorFactory = SettingsCellDescriptorFactory(settingsPropertyFactory: settingsPropertyFactory)
        
        let settingsNavigationController = SettingsNavigationController(rootGroup: settingsCellDescriptorFactory.rootSettingsGroup(), settingsPropertyFactory: settingsPropertyFactory)
        return settingsNavigationController
    }
    
    required init(rootGroup: protocol<SettingsControllerGeneratorType, SettingsInternalGroupCellDescriptorType>, settingsPropertyFactory: SettingsPropertyFactory) {
        self.rootGroup = rootGroup
        self.settingsPropertyFactory = settingsPropertyFactory
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsNavigationController.soundIntensityChanged(_:)), name: SettingsPropertyName.SoundAlerts.changeNotificationName, object: nil)
    }
    
    func openControllerForCellWithIdentifier(identifier: String) -> UIViewController? {
        var resultViewController: UIViewController? = .None
        // Let's assume for the moment that menu is only 2 levels deep
        self.rootGroup.allCellDescriptors().forEach({ (topCellDescriptor: SettingsCellDescriptorType) -> () in
            if let topCellGroupDescriptor = topCellDescriptor as? protocol<SettingsInternalGroupCellDescriptorType, SettingsControllerGeneratorType> {
                topCellGroupDescriptor.allCellDescriptors().forEach({ (cellDescriptor: SettingsCellDescriptorType) -> () in
                    if let cellIdentifier = cellDescriptor.identifier,
                        let cellGroupDescriptor = cellDescriptor as? SettingsControllerGeneratorType,
                        let topViewController = topCellGroupDescriptor.generateViewController(),
                        let viewController = cellGroupDescriptor.generateViewController()
                        where cellIdentifier == identifier
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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        fatalError()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func soundIntensityChanged(notification: NSNotification) {
        let soundProperty = self.settingsPropertyFactory.property(.SoundAlerts)
        
        if let intensivityLevel = soundProperty.propertyValue.value() as? AVSIntensityLevel {
            switch(intensivityLevel) {
            case .Full:
                Analytics.shared()?.tagSoundIntensityPreference(SoundIntensityTypeAlways)
            case .Some:
                Analytics.shared()?.tagSoundIntensityPreference(SoundIntensityTypeFirstOnly)
            case .None:
                Analytics.shared()?.tagSoundIntensityPreference(SoundIntensityTypeNever)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let rootViewController = self.rootGroup.generateViewController() {
            Analytics.shared()?.tagScreen("SETTINGS")
            
            self.pushViewController(rootViewController, animated: false)
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }

}

extension SettingsNavigationController: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController,
         animationControllerForOperation operation: UINavigationControllerOperation,
                         fromViewController fromVC: UIViewController,
                             toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .Push:
            return self.pushTransition
        case .Pop:
            return self.popTransition
        default:
            fatalError()
        }
    }
}
