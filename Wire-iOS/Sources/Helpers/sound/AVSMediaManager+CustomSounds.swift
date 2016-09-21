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

extension AVSMediaManager {
    fileprivate func settingsPropertyFactory() -> SettingsPropertyFactory {
        let settingsPropertyFactory = SettingsPropertyFactory(userDefaults: UserDefaults.standard,
                                                              analytics: Analytics.shared(),
                                                              mediaManager: AVSProvider.shared.mediaManager,
                                                              userSession: ZMUserSession.shared(),
                                                              selfUser: ZMUser.selfUser())
        return settingsPropertyFactory
    }
    
    func observeSoundConfigurationChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: NSNotification.Name(rawValue: SettingsPropertyName.MessageSoundName.changeNotificationName), object: .none)
        NotificationCenter.default.addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: NSNotification.Name(rawValue: SettingsPropertyName.CallSoundName.changeNotificationName), object: .none)
        NotificationCenter.default.addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: NSNotification.Name(rawValue: SettingsPropertyName.PingSoundName.changeNotificationName), object: .none)
    }
    
    func configureCustomSounds() {
        let settingsPropertyFactory = self.settingsPropertyFactory()
        
        let messageSoundProperty = settingsPropertyFactory.property(.MessageSoundName)
        self.updateCustomSoundForProperty(messageSoundProperty)
        
        let callSoundProperty = settingsPropertyFactory.property(.CallSoundName)
        self.updateCustomSoundForProperty(callSoundProperty)
        
        let pingSoundProperty = settingsPropertyFactory.property(.PingSoundName)
        self.updateCustomSoundForProperty(pingSoundProperty)
    }
    
    func updateCustomSoundForProperty(_ property: SettingsProperty) {
        let name = property.propertyName.rawValue
        let value = property.propertyValue.value()
        if let stringValue = value as? String {
            self.updateCustomSoundForName(name, propertyValue: stringValue)
        }
    }
    
    @objc func updateCustomSoundForName(_ propertyName: String, propertyValue: String?) {
        let value = propertyValue
        
        let soundValue = value == .none ? .none : ZMSound(rawValue: value!)
        
        switch propertyName {
        case SettingsPropertyName.MessageSoundName.rawValue:
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundFirstMessageReceivedSound)
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundMessageReceivedSound)
            
        case SettingsPropertyName.CallSoundName.rawValue:
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundRingingFromThemInCallSound)
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundRingingFromThemSound)
            
        case SettingsPropertyName.PingSoundName.rawValue:
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundOutgoingKnockSound)
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundIncomingKnockSound)
            
        default:
            fatalError("\(propertyName) is not a sound property")
        }
    }
    
    // MARK: - Notifications
    func didUpdateSound(_ notification: NSNotification?) {
        self.configureSounds()
    }
}
