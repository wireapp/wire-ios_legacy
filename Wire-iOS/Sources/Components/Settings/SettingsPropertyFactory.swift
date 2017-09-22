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

protocol ZMUserSessionInterface: class {
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

typealias SettingsSelfUser = ValidatorType & ZMEditableUser & ZMBareUser

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
    weak var userSession: ZMUserSessionInterface?
    let selfUser: SettingsSelfUser
    var crashlogManager: CrashlogManager?
    
    static let userDefaultsPropertiesToKeys: [SettingsPropertyName: String] = [
        SettingsPropertyName.disableMarkdown            : UserDefaultDisableMarkdown,
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
        SettingsPropertyName.mapsOpeningOption          : UserDefaultMapsOpeningRawValue,
        SettingsPropertyName.browserOpeningOption       : UserDefaultBrowserOpeningRawValue,
        SettingsPropertyName.tweetOpeningOption         : UserDefaultTwitterOpeningRawValue,
        SettingsPropertyName.callingProtocolStrategy    : UserDefaultCallingProtocolStrategy,
        SettingsPropertyName.enableBatchCollections     : UserDefaultEnableBatchCollections,
        SettingsPropertyName.callingConstantBitRate     : UserDefaultCallingConstantBitRate,
        SettingsPropertyName.disableLinkPreviews        : UserDefaultDisableLinkPreviews,
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
            let getAction: GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.string(value: self.selfUser.name)
            }
            let setAction: SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .string(let stringValue):
                    var inOutString: NSString? = stringValue as NSString
                    try type(of: self.selfUser).validateName(&inOutString)
                    
                    self.userSession?.enqueueChanges({
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
            let setAction : SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .number(let number):
                    self.userSession?.enqueueChanges({
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
            let setAction : SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
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
            let setAction : SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
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
            let setAction : SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
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
                if let value = self.userSession?.isNotificationContentHidden {
                    return SettingsPropertyValue.number(value: NSNumber(value: value))
                } else {
                    return .none
                }
            }
            
            let setAction : SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch value {
                    case .number(let number):
                        self.userSession?.performChanges {
                            self.userSession?.isNotificationContentHidden = number.boolValue
                        }
                    
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type: \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .disableSendButton:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in return SettingsPropertyValue(Settings.shared().disableSendButton) },
                setAction: { _, value in
                    switch value {
                    case .number(value: let number):
                        Settings.shared().disableSendButton = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })
        case .lockApp:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    return SettingsPropertyValue(AppLock.isActive)
            },
                setAction: { _, value in
                    switch value {
                    case .number(value: let lockApp):
                        AppLock.isActive = lockApp.boolValue
                    default: throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })
        case .lockAppLastDate:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    return SettingsPropertyValue(AppLock.lastUnlockDateAsInt)
            },
                setAction: { _, value in
                    switch value {
                    case .number(value: let lockAppLastDate):
                        AppLock.lastUnlockDateAsInt = lockAppLastDate.uint32Value
                    default: throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })
        
        case .callingConstantBitRate:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in return SettingsPropertyValue(Settings.shared().callingConstantBitRate) },
                setAction: { _, value in
                    if case .number(let enabled) = value {
                        Settings.shared().callingConstantBitRate = enabled.boolValue
                    }
            })
            
        case .disableLinkPreviews:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in return SettingsPropertyValue(Settings.shared().disableLinkPreviews) },
                setAction: { _, value in
                    switch value {
                    case .number(value: let number):
                        Settings.shared().disableLinkPreviews = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })
        case .disableCallKit:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in return SettingsPropertyValue(Settings.shared().disableCallKit) },
                setAction: { _, value in
                    if case .number(let disabled) = value {
                        Settings.shared().disableCallKit = disabled.boolValue
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

extension SettingsPropertyFactory {
    static var shared: SettingsPropertyFactory? {
        guard let manager = SessionManager.shared, let session = manager.isUserSessionActive ? ZMUserSession.shared() : nil else {
            return .none
        }
        let settingsPropertyFactory = SettingsPropertyFactory(userDefaults: UserDefaults.standard,
                                                              analytics: Analytics.shared(),
                                                              mediaManager: AVSProvider.shared.mediaManager,
                                                              userSession: session,
                                                              selfUser: ZMUser.selfUser(),
                                                              crashlogManager: BITHockeyManager.shared())
        
        return settingsPropertyFactory
    }
}
