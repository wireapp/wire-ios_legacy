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


protocol AnalyticsInterface {
    var isOptedOut : Bool {get set}
}

extension Analytics: AnalyticsInterface {
}

protocol AVSMediaManagerInterface {
    var intensityLevel : AVSIntensityLevel {get set}
    func playMediaByName(name: String!)
}

extension AVSMediaManager: AVSMediaManagerInterface {
}

protocol ZMUserSessionInterface {
    func performChanges(_: dispatch_block_t)
    func enqueueChanges(_: dispatch_block_t)
    
    var isNotificationContentHidden : Bool { get set }
}

extension ZMUserSession: ZMUserSessionInterface {
}

class SettingsPropertyFactory {
    let userDefaults: NSUserDefaults
    var analytics: AnalyticsInterface?
    var mediaManager: AVSMediaManagerInterface?
    var userSession: ZMUserSessionInterface
    let selfUser: ZMEditableUser
    
    static let userDefaultsPropertiesToKeys: [SettingsPropertyName: String] = [
        SettingsPropertyName.Markdown                   : UserDefaultMarkdown,
        SettingsPropertyName.ChatHeadsDisabled          : UserDefaultChatHeadsDisabled,
        SettingsPropertyName.PreferredFlashMode         : UserDefaultPreferredCameraFlashMode,
        SettingsPropertyName.MessageSoundName           : UserDefaultMessageSoundName,
        SettingsPropertyName.CallSoundName              : UserDefaultCallSoundName,
        SettingsPropertyName.PingSoundName              : UserDefaultPingSoundName,
        SettingsPropertyName.DisableUI                  : UserDefaultDisableUI,
        SettingsPropertyName.DisableAVS                 : UserDefaultDisableAVS,
        SettingsPropertyName.DisableHockey              : UserDefaultDisableHockey,
        SettingsPropertyName.DisableAnalytics           : UserDefaultDisableAnalytics,
    ]
    
    init(userDefaults: NSUserDefaults, analytics: AnalyticsInterface?, mediaManager: AVSMediaManagerInterface?, userSession: ZMUserSessionInterface, selfUser: ZMEditableUser) {
        self.userDefaults = userDefaults
        self.analytics = analytics
        self.mediaManager = mediaManager
        self.userSession = userSession
        self.selfUser = selfUser
    }
    
    func property(propertyName: SettingsPropertyName) -> SettingsProperty {
        
        switch(propertyName) {
            // Profile
        case .ProfileName:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.String(value: self.selfUser.name)
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) -> () in
                switch(value) {
                case .String(let stringValue):
                    self.userSession.enqueueChanges({
                        self.selfUser.name = stringValue
                    })
                default:
                    fatalError("Incorrect type \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction , setAction: setAction)
        case .ProfileEmail:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.String(value: self.selfUser.emailAddress)
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) in
                switch(value) {
                case .String:
                    let block : dispatch_block_t = {
                        //self.selfUser.emailAddress = stringValue
                    }
                    self.userSession.enqueueChanges(block)
                    
                default:
                    fatalError("Incorrect type \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
        case .ProfilePhone:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.String(value: self.selfUser.phoneNumber)
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) in
                switch(value) {
                case .String:
                    let block : dispatch_block_t = {
//                        self.selfUser.phoneNumber = stringValue
                    }
                    self.userSession.enqueueChanges(block)
                    
                default:
                    fatalError("Incorrect type \(value) for key \(propertyName)")
                }
            }
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
            // AVS

        case .AccentColor:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.Number(value: Int(self.selfUser.accentColorValue.rawValue))
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) -> () in
                switch(value) {
                case .Number(let intValue):
                    self.userSession.enqueueChanges({
                        self.selfUser.accentColorValue = ZMAccentColor(rawValue: Int16(intValue))!
                    })
                default:
                    fatalError("Incorrect type \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction , setAction: setAction)
        case .DarkMode:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.Bool(value: self.userDefaults.stringForKey(UserDefaultColorScheme) == "dark")
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) -> () in
                switch(value) {
                case .Bool(let boolValue):
                    self.userDefaults.setObject(boolValue ? "dark" : "light", forKey: UserDefaultColorScheme)
                default:
                    fatalError("Incorrect type \(value) for key \(propertyName)")
                }
                
                NSNotificationCenter.defaultCenter().postNotificationName(SettingsColorSchemeChangedNotification, object: self)
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction , setAction: setAction)
        case .SoundAlerts:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                if let mediaManager = self.mediaManager {
                    return SettingsPropertyValue.Number(value: Int(mediaManager.intensityLevel.rawValue))
                }
                else {
                    return SettingsPropertyValue.Number(value: 0)
                }
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) in
                switch(value) {
                case .Number(let intValue):
                    if let intensivityLevel = AVSIntensityLevel(rawValue: UInt(intValue)),
                        var mediaManager = self.mediaManager {
                        mediaManager.intensityLevel = intensivityLevel
                    }
                    else {
                        fatalError("Cannot use value \(intValue) for AVSIntensivityLevel at \(propertyName)")
                    }
                default:
                    fatalError("Incorrect type \(value) for key \(propertyName)")
                }
            }
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
            
        case .AnalyticsOptOut:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                if let analytics = self.analytics {
                    return SettingsPropertyValue.Number(value: Int(analytics.isOptedOut))
                }
                else {
                    return .Bool(value: false)
                }
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) in
                if var analytics = self.analytics {
                    switch(value) {
                    case .Number(let intValue):
                        analytics.isOptedOut = Bool(intValue)
                    case .Bool(let boolValue):
                        analytics.isOptedOut = boolValue
                    default:
                        fatalError("Incorrect type \(value) for key \(propertyName)")
                    }
                }
            }
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
            
        case .NotificationContentVisible:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return .Bool(value: self.userSession.isNotificationContentHidden)
            }
            
            let setAction : SetAction = { (porperty: SettingsBlockProperty, value: SettingsPropertyValue) in
                switch value {
                    case .Bool(let boolValue):
                        self.userSession.performChanges {
                            self.userSession.isNotificationContentHidden = boolValue
                        }
                    
                    default:
                        fatalError("Incorrect type: \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
            
        default:
            if let userDefaultsKey = self.dynamicType.userDefaultsPropertiesToKeys[propertyName] {
                return SettingsUserDefaultsProperty(propertyName: propertyName, userDefaultsKey: userDefaultsKey, userDefaults: self.userDefaults)
            }
        }
        
        fatalError("Cannot create SettingsProperty for \(propertyName)")
    }
}
