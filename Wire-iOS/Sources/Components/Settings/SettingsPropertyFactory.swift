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
    func playMediaByName(_ name: String!)
}

extension AVSMediaManager: AVSMediaManagerInterface {
}

protocol ZMUserSessionInterface {
    func performChanges(_ block: @escaping () -> Swift.Void)
    func enqueueChanges(_ block: @escaping () -> Swift.Void)
    
    var isNotificationContentHidden : Bool { get set }
}


extension ZMUserSession: ZMUserSessionInterface {
}

protocol ValidatorType {
    static func validateName(_ ioName: AutoreleasingUnsafeMutablePointer<NSString?>!) throws
}

extension ZMUser: ValidatorType {
}

typealias SettingsSelfUser = ValidatorType & ZMEditableUser

enum SettingsPropertyError: Error {
    case WrongValue(String)
}

class SettingsPropertyFactory {
    let userDefaults: UserDefaults
    var analytics: AnalyticsInterface?
    var mediaManager: AVSMediaManagerInterface?
    var userSession: ZMUserSessionInterface
    let selfUser: SettingsSelfUser
    
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
        SettingsPropertyName.DisableSendButton          : UserDefaultSendButtonDisabled
    ]
    
    init(userDefaults: UserDefaults, analytics: AnalyticsInterface?, mediaManager: AVSMediaManagerInterface?, userSession: ZMUserSessionInterface, selfUser: SettingsSelfUser) {
        self.userDefaults = userDefaults
        self.analytics = analytics
        self.mediaManager = mediaManager
        self.userSession = userSession
        self.selfUser = selfUser
    }
    
    func property(_ propertyName: SettingsPropertyName) -> SettingsProperty {
        
        switch(propertyName) {
            // Profile
        case .ProfileName:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.string(value: self.selfUser.name)
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .string(let stringValue):
                    var inOutString: NSString? = stringValue as NSString
                    try type(of: self.selfUser).validateName(&inOutString)
                    
                    self.userSession.enqueueChanges({
                        self.selfUser.name = stringValue
                    })
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction , setAction: setAction)

        case .AccentColor:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.number(value: Int(self.selfUser.accentColorValue.rawValue))
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .number(let intValue):
                    self.userSession.enqueueChanges({
                        self.selfUser.accentColorValue = ZMAccentColor(rawValue: Int16(intValue))!
                    })
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction , setAction: setAction)
        case .DarkMode:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.bool(value: self.userDefaults.string(forKey: UserDefaultColorScheme) == "dark")
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .bool(let boolValue):
                    self.userDefaults.set(boolValue ? "dark" : "light", forKey: UserDefaultColorScheme)
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
                
                NotificationCenter.default.post(name: NSNotification.Name.SettingsColorSchemeChanged, object: self)
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction , setAction: setAction)
        case .SoundAlerts:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                if let mediaManager = self.mediaManager {
                    return SettingsPropertyValue.number(value: Int(mediaManager.intensityLevel.rawValue))
                }
                else {
                    return SettingsPropertyValue.number(value: 0)
                }
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .number(let intValue):
                    if let intensivityLevel = AVSIntensityLevel(rawValue: UInt(intValue)),
                        var mediaManager = self.mediaManager {
                        mediaManager.intensityLevel = intensivityLevel
                    }
                    else {
                        throw SettingsPropertyError.WrongValue("Cannot use value \(intValue) for AVSIntensivityLevel at \(propertyName)")
                    }
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
            
        case .AnalyticsOptOut:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                if let analytics = self.analytics {
                    return SettingsPropertyValue.number(value: Int(analytics.isOptedOut ? 1 : 0))
                }
                else {
                    return .bool(value: false)
                }
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                if var analytics = self.analytics {
                    switch(value) {
                    case .number(let intValue):
                        analytics.isOptedOut = Bool(intValue)
                    case .bool(let boolValue):
                        analytics.isOptedOut = boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
                }
            }
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
            
        case .NotificationContentVisible:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return .bool(value: self.userSession.isNotificationContentHidden)
            }
            
            let setAction : SetAction = { (porperty: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch value {
                    case .bool(let boolValue):
                        self.userSession.performChanges {
                            self.userSession.isNotificationContentHidden = boolValue
                        }
                    
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type: \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
            
        default:
            if let userDefaultsKey = type(of: self).userDefaultsPropertiesToKeys[propertyName] {
                return SettingsUserDefaultsProperty(propertyName: propertyName, userDefaultsKey: userDefaultsKey, userDefaults: self.userDefaults)
            }
        }
        
        fatalError("Cannot create SettingsProperty for \(propertyName)")
    }
}
