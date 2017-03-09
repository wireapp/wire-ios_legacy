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


import HockeySDK.BITHockeyManager


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
    func performChanges(_ block: @escaping () -> ())
    func enqueueChanges(_ block: @escaping () -> ())
    
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

protocol CrashlogManager {
   var isCrashManagerDisabled: Bool { get set }
}

extension BITHockeyManager: CrashlogManager {}

class SettingsPropertyFactory {
    let userDefaults: UserDefaults
    var analytics: AnalyticsInterface?
    var mediaManager: AVSMediaManagerInterface?
    var userSession: ZMUserSessionInterface
    let selfUser: SettingsSelfUser
    var crashlogManager: CrashlogManager?
    
    static let userDefaultsPropertiesToKeys: [SettingsPropertyName: String] = [
        SettingsPropertyName.markdown                   : UserDefaultMarkdown,
        SettingsPropertyName.chatHeadsDisabled          : UserDefaultChatHeadsDisabled,
        SettingsPropertyName.preferredFlashMode         : UserDefaultPreferredCameraFlashMode,
        SettingsPropertyName.messageSoundName           : UserDefaultMessageSoundName,
        SettingsPropertyName.callSoundName              : UserDefaultCallSoundName,
        SettingsPropertyName.pingSoundName              : UserDefaultPingSoundName,
        SettingsPropertyName.disableUI                  : UserDefaultDisableUI,
        SettingsPropertyName.disableAVS                 : UserDefaultDisableAVS,
        SettingsPropertyName.disableHockey              : UserDefaultDisableHockey,
        SettingsPropertyName.disableAnalytics           : UserDefaultDisableAnalytics,
        SettingsPropertyName.disableSendButton          : UserDefaultSendButtonDisabled,
        SettingsPropertyName.disableCallKit             : UserDefaultDisableCallKit,
        SettingsPropertyName.mapsOpeningOption          : UserDefaultMapsOpeningRawValue,
        SettingsPropertyName.browserOpeningOption       : UserDefaultBrowserOpeningRawValue,
        SettingsPropertyName.tweetOpeningOption         : UserDefaultTwitterOpeningRawValue,
        SettingsPropertyName.callingProtocolStrategy    : UserDefaultCallingProtocolStrategy,
        SettingsPropertyName.enableBatchCollections     : UserDefaultEnableBatchCollections,
    ]
    
    init(userDefaults: UserDefaults, analytics: AnalyticsInterface?, mediaManager: AVSMediaManagerInterface?, userSession: ZMUserSessionInterface, selfUser: SettingsSelfUser, crashlogManager: CrashlogManager? = .none) {
        self.userDefaults = userDefaults
        self.analytics = analytics
        self.mediaManager = mediaManager
        self.userSession = userSession
        self.selfUser = selfUser
        self.crashlogManager = crashlogManager
    }
    
    func property(_ propertyName: SettingsPropertyName) -> SettingsProperty {
        
        switch(propertyName) {
            // Profile
        case .profileName:
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
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .accentColor:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue(self.selfUser.accentColorValue.rawValue)
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .number(let number):
                    self.userSession.enqueueChanges({
                        self.selfUser.accentColorValue = ZMAccentColor(rawValue: number.int16Value)!
                    })
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
        case .darkMode:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue(self.userDefaults.string(forKey: UserDefaultColorScheme) == "dark")
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .number(let number):
                    self.userDefaults.set(number.boolValue ? "dark" : "light", forKey: UserDefaultColorScheme)
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
                
                NotificationCenter.default.post(name: NSNotification.Name.SettingsColorSchemeChanged, object: self)
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
        case .soundAlerts:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                if let mediaManager = self.mediaManager {
                    return SettingsPropertyValue(mediaManager.intensityLevel.rawValue)
                }
                else {
                    return SettingsPropertyValue(0)
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
            
        case .analyticsOptOut:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                if let analytics = self.analytics {
                    return SettingsPropertyValue(analytics.isOptedOut)
                }
                else {
                    return SettingsPropertyValue(false)
                }
            }
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                if var analytics = self.analytics,
                    var crashlogManager = self.crashlogManager {
                    switch(value) {
                    case .number(let number):
                        analytics.isOptedOut = number.boolValue
                        crashlogManager.isCrashManagerDisabled = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
                }
            }
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
            
        case .notificationContentVisible:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return .number(value: NSNumber(value: self.userSession.isNotificationContentHidden))
            }
            
            let setAction : SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch value {
                    case .number(let number):
                        self.userSession.performChanges {
                            self.userSession.isNotificationContentHidden = number.boolValue
                        }
                    
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type: \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .disableSendButton:
            return SettingsBlockProperty(
                propertyName: .disableSendButton,
                getAction: { _ in return SettingsPropertyValue(Settings.shared().disableSendButton) },
                setAction: { _, value in
                    switch value {
                    case .number(value: let number):
                        Settings.shared().disableSendButton = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })
            
        case .callingProtocolStrategy:
            return SettingsBlockProperty(
                propertyName: .callingProtocolStrategy,
                getAction: { _ in return SettingsPropertyValue(Settings.shared().callingProtocolStrategy.rawValue) },
                setAction: { _, value in
                    if case .number(let intValue) = value, let callingProtocolStrategy = CallingProtocolStrategy(rawValue: UInt(intValue)) {
                        Settings.shared().callingProtocolStrategy = callingProtocolStrategy
                        ZMUserSession.callingProtocolStrategy = callingProtocolStrategy
                    }
            })
        case .lockApp:
            return SettingsBlockProperty(
                propertyName: .lockApp,
                getAction: { _ in
                    guard let data = ZMKeychain.data(forAccount: SettingsPropertyName.lockApp.rawValue),
                            data.count != 0 else {
                        return SettingsPropertyValue(false)
                    }
                    
                    return SettingsPropertyValue(String(data: data, encoding: .utf8) == "YES")
            },
                setAction: { _, value in
                    switch value {
                    case .number(value: let lockApp):
                        let data = (lockApp.boolValue ? "YES" : "NO").data(using: .utf8)!
                        ZMKeychain.setData(data, forAccount: SettingsPropertyName.lockApp.rawValue)
                    default: throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })
        case .lockAppLastDate:
            return SettingsBlockProperty(
                propertyName: .lockAppLastDate,
                getAction: { _ in
                    guard let data = ZMKeychain.data(forAccount: SettingsPropertyName.lockAppLastDate.rawValue),
                        data.count != 0 else {
                            return SettingsPropertyValue(0)
                    }
                    
                    let intBits = data.withUnsafeBytes({(bytePointer: UnsafePointer<UInt8>) -> UInt32 in
                        bytePointer.withMemoryRebound(to: UInt32.self, capacity: 4) { pointer in
                            return pointer.pointee
                        }
                    })
                    
                    return SettingsPropertyValue(UInt32(littleEndian: intBits))
            },
                setAction: { _, value in
                    switch value {
                    case .number(value: let lockAppLastDate):
                        var value: UInt32 = lockAppLastDate as UInt32
                        let data = withUnsafePointer(to: &value) {
                            Data(bytes: UnsafePointer($0), count: MemoryLayout.size(ofValue: lockAppLastDate))
                        }
                        
                        ZMKeychain.setData(data, forAccount: SettingsPropertyName.lockAppLastDate.rawValue)
                    default: throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })

        case .sendV3Assets:
            return SettingsBlockProperty(
                propertyName: .sendV3Assets,
                getAction: { _ in return SettingsPropertyValue(ExtensionSettings.shared.useAssetsV3) },
                setAction: { _, value in
                    if case .number(let v3) = value {
                        ExtensionSettings.shared.useAssetsV3 = v3.boolValue
                    }
            })
            
        default:
            if let userDefaultsKey = type(of: self).userDefaultsPropertiesToKeys[propertyName] {
                return SettingsUserDefaultsProperty(propertyName: propertyName, userDefaultsKey: userDefaultsKey, userDefaults: self.userDefaults)
            }
        }
        
        fatalError("Cannot create SettingsProperty for \(propertyName)")
    }
}
