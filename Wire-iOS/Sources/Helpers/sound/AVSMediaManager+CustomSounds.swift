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
import avs


extension AVSMediaManager {
    func observeSoundConfigurationChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: NSNotification.Name(rawValue: SettingsPropertyName.messageSoundName.changeNotificationName), object: .none)
        NotificationCenter.default.addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: NSNotification.Name(rawValue: SettingsPropertyName.callSoundName.changeNotificationName), object: .none)
        NotificationCenter.default.addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: NSNotification.Name(rawValue: SettingsPropertyName.pingSoundName.changeNotificationName), object: .none)
    }
    
    @objc func configureCustomSounds() {
        let settingsPropertyFactory = SettingsPropertyFactory(userSession: nil, selfUser: nil)
        
        let messageSoundProperty = settingsPropertyFactory.property(.messageSoundName)
        self.updateCustomSoundForProperty(messageSoundProperty)
        
        let callSoundProperty = settingsPropertyFactory.property(.callSoundName)
        self.updateCustomSoundForProperty(callSoundProperty)
        
        let pingSoundProperty = settingsPropertyFactory.property(.pingSoundName)
        self.updateCustomSoundForProperty(pingSoundProperty)
    }
    
    func updateCustomSoundForProperty(_ property: SettingsProperty) {
        let name = property.propertyName.rawValue
        let value = property.rawValue()
        if let stringValue = value as? String {
            self.updateCustomSoundForName(name, propertyValue: stringValue)
        }
    }
    
    @objc func updateCustomSoundForName(_ propertyName: String, propertyValue: String?) {
        let value = propertyValue
        
        let soundValue = value == .none ? .none : ZMSound(rawValue: value!)
        
        switch propertyName {
        case SettingsPropertyName.messageSoundName.rawValue:
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundFirstMessageReceivedSound)
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundMessageReceivedSound)
            
        case SettingsPropertyName.callSoundName.rawValue:
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundRingingFromThemInCallSound)
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundRingingFromThemSound)
            
        case SettingsPropertyName.pingSoundName.rawValue:
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundOutgoingKnockSound)
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSoundIncomingKnockSound)
            
        default:
            fatalError("\(propertyName) is not a sound property")
        }
    }
    
    // MARK: - Notifications
    @objc func didUpdateSound(_ notification: NSNotification?) {
        self.configureSounds()
    }
}
