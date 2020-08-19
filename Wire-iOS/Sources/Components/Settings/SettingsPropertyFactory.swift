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


import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterDistribute
import avs
import WireSyncEngine
import WireCommonComponents

protocol TrackingInterface {
    var disableCrashAndAnalyticsSharing : Bool { get set }
}

protocol AVSMediaManagerInterface {
    var intensityLevel : AVSIntensityLevel { get set }
    var isMicrophoneMuted: Bool { get set }
}

extension AVSMediaManager: AVSMediaManagerInterface {
}

protocol ValidatorType {
    static func validate(name: inout String?) throws -> Bool
}

extension ZMUser: ValidatorType {
}

typealias SettingsSelfUser = ValidatorType & ZMEditableUser & UserType

enum SettingsPropertyError: Error {
    case WrongValue(String)
}


protocol SettingsPropertyFactoryDelegate: class {
    func asyncMethodDidStart(_ settingsPropertyFactory: SettingsPropertyFactory)
    func asyncMethodDidComplete(_ settingsPropertyFactory: SettingsPropertyFactory)
}

final class SettingsPropertyFactory {
    let userDefaults: UserDefaults
    var tracking: TrackingInterface?
    var mediaManager: AVSMediaManagerInterface?
    weak var userSession: ZMUserSessionInterface?
    var selfUser: SettingsSelfUser?
    var marketingConsent: SettingsPropertyValue = .none
    weak var delegate: SettingsPropertyFactoryDelegate?
    
    static let userDefaultsPropertiesToKeys: [SettingsPropertyName: SettingKey] = [
        SettingsPropertyName.disableMarkdown                : .disableMarkdown,
        SettingsPropertyName.chatHeadsDisabled              : .chatHeadsDisabled,
        SettingsPropertyName.messageSoundName               : .messageSoundName,
        SettingsPropertyName.callSoundName                  : .callSoundName,
        SettingsPropertyName.pingSoundName                  : .pingSoundName,
        SettingsPropertyName.disableSendButton              : .sendButtonDisabled,
        SettingsPropertyName.mapsOpeningOption              : .mapsOpeningRawValue,
        SettingsPropertyName.browserOpeningOption           : .browserOpeningRawValue,
        SettingsPropertyName.tweetOpeningOption             : .twitterOpeningRawValue,
        SettingsPropertyName.callingProtocolStrategy        : .callingProtocolStrategy,
        SettingsPropertyName.enableBatchCollections         : .enableBatchCollections,
        SettingsPropertyName.callingConstantBitRate         : .callingConstantBitRate,
    ]
    
    convenience init(userSession: ZMUserSessionInterface?, selfUser: SettingsSelfUser?) {
        self.init(userDefaults: UserDefaults.standard, tracking: TrackingManager.shared, mediaManager: AVSMediaManager.sharedInstance(), userSession: userSession, selfUser: selfUser)
    }
    
    init(userDefaults: UserDefaults, tracking: TrackingInterface?, mediaManager: AVSMediaManagerInterface?, userSession: ZMUserSessionInterface?, selfUser: SettingsSelfUser?) {
        self.userDefaults = userDefaults
        self.tracking = tracking
        self.mediaManager = mediaManager
        self.userSession = userSession
        self.selfUser = selfUser

        if let user = self.selfUser as? ZMUser, let userSession = ZMUserSession.shared() {
            user.fetchMarketingConsent(in: userSession, completion: { [weak self] result in
                switch result {
                case .failure(_):
                    self?.marketingConsent = .none
                case .success(let result):
                    self?.marketingConsent = SettingsPropertyValue.bool(value: result)
                }
            })
        }
    }

    private func getOnlyProperty(propertyName: SettingsPropertyName, getAction: @escaping GetAction) -> SettingsBlockProperty {
        let setAction: SetAction = { (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in }

        return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
    }

    func property(_ propertyName: SettingsPropertyName) -> SettingsProperty {
        
        switch(propertyName) {
        // Profile
        case .profileName:
            let getAction: GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.string(value: self.selfUser?.name ?? "")
            }
            let setAction: SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .string(let stringValue):
                    guard let selfUser = self.selfUser else { requireInternal(false, "Attempt to modify a user property without a self user"); break }

                    var inOutString: String? = stringValue as String
                    _ = try type(of: selfUser).validate(name: &inOutString)
                    self.userSession?.enqueue {
                        selfUser.name = stringValue
                    }
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }

            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
        case .email:
            let getAction: GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.string(value: self.selfUser?.emailAddress ?? "")
            }

            return getOnlyProperty(propertyName: propertyName, getAction: getAction)

        case .phone:
            let getAction: GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.string(value: self.selfUser?.phoneNumber ?? "")
            }

            return getOnlyProperty(propertyName: propertyName, getAction: getAction)

        case .handle:
            let getAction: GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue.string(value: self.selfUser?.handleDisplayString ?? "")
            }

            return getOnlyProperty(propertyName: propertyName, getAction: getAction)

        case .accentColor:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return SettingsPropertyValue(self.selfUser?.accentColorValue.rawValue ?? ZMAccentColor.undefined.rawValue)
            }
            let setAction : SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .number(let number):
                    self.userSession?.enqueue({
                        self.selfUser?.accentColorValue = ZMAccentColor(rawValue: number.int16Value)!
                    })
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }
            
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
        case .darkMode:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                
                let settingsColorScheme: SettingsColorScheme = SettingsColorScheme(from: self.userDefaults.string(forKey: SettingKey.colorScheme.rawValue))
                
                return SettingsPropertyValue(settingsColorScheme.rawValue)
            }
            let setAction : SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch(value) {
                case .number(let number):
                    if let settingsColorScheme = SettingsColorScheme(rawValue: Int(number.int64Value)) {
                        self.userDefaults.set(settingsColorScheme.keyValueString,
                                              forKey: SettingKey.colorScheme.rawValue)
                    } else {
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }

                NotificationCenter.default.post(name: .SettingsColorSchemeChanged, object: nil)
            }
            
            return SettingsBlockProperty(propertyName: propertyName,
                                         getAction: getAction,
                                         setAction: setAction)
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
                    if let intensivityLevel = AVSIntensityLevel(rawValue: UInt(truncating: intValue)),
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
            
        case .disableCrashAndAnalyticsSharing:
            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                if let tracking = self.tracking {
                    return SettingsPropertyValue(tracking.disableCrashAndAnalyticsSharing)
                }
                else {
                    return SettingsPropertyValue(false)
                }
            }
            let setAction : SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                if var tracking = self.tracking {
                    switch(value) {
                    case .number(let number):
                        tracking.disableCrashAndAnalyticsSharing = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
                }
            }
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .receiveNewsAndOffers:

            let getAction : GetAction = { [unowned self] (property: SettingsBlockProperty) -> SettingsPropertyValue in
                return self.marketingConsent
            }

            let setAction : SetAction = { [unowned self] (property: SettingsBlockProperty, value: SettingsPropertyValue) throws -> () in
                switch value {
                case .number(let number):
                    self.userSession?.perform {
                        if let userSession = self.userSession as? ZMUserSession {
                            self.delegate?.asyncMethodDidStart(self)
                            (self.selfUser as? ZMUser)?.setMarketingConsent(to: number.boolValue, in: userSession, completion: { [weak self] _ in
                                if let weakSelf = self {
                                    weakSelf.marketingConsent = SettingsPropertyValue.number(value: number)
                                    weakSelf.delegate?.asyncMethodDidComplete(weakSelf)
                                }
                            })
                        }
                    }

                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type: \(value) for key \(propertyName)")
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
                        self.userSession?.perform {
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
                getAction: { _ in
                    let disableSendButton: Bool? = Settings.shared[.sendButtonDisabled]
                    return SettingsPropertyValue(disableSendButton ?? false) },
                setAction: { _, value in
                    switch value {
                    case .number(value: let number):
                        Settings.shared[.sendButtonDisabled] = number.boolValue
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
        
        case .callingConstantBitRate:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let callingConstantBitRate: Bool = Settings.shared[.callingConstantBitRate] ?? false
                    return SettingsPropertyValue(callingConstantBitRate) },
                setAction: { _, value in
                    if case .number(let enabled) = value {
                        Settings.shared[.callingConstantBitRate] = enabled.boolValue
                    }
            })
            
        case .disableLinkPreviews:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in return SettingsPropertyValue(Settings.disableLinkPreviews) },
                setAction: { _, value in
                    switch value {
                    case .number(value: let number):
                        Settings.disableLinkPreviews = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })
        case .disableCallKit:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let disableCallKit: Bool = Settings.shared[.disableCallKit] ?? false
                    return SettingsPropertyValue(disableCallKit) },
                setAction: { _, value in
                    if case .number(let disabled) = value {
                        Settings.shared[.disableCallKit] = disabled.boolValue
                    }
            })
        case .readReceiptsEnabled:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let value = self.selfUser?.readReceiptsEnabled ?? false
                    return SettingsPropertyValue(value)
            },
                setAction: { _, value in
                    if case .number(let enabled) = value,
                        let userSession = self.userSession as? ZMUserSession {
                            userSession.perform {
                                self.selfUser?.readReceiptsEnabled = enabled.boolValue
                            }
                        }
            })
        case .enableConferenceCallingBeta:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let value: Bool = Settings.shared[.conferenceCalling] ?? false
                    return SettingsPropertyValue(value)
                },
                setAction: { _, value  in
                    if case .number(let enabled) = value {
                        Settings.shared[.conferenceCalling] = enabled.boolValue
                    }
                }
            )
        default:
            if let userDefaultsKey = type(of: self).userDefaultsPropertiesToKeys[propertyName] {
                return SettingsUserDefaultsProperty(propertyName: propertyName, userDefaultsKey: userDefaultsKey.rawValue, userDefaults: userDefaults)
            }
        }
        
        fatalError("Cannot create SettingsProperty for \(propertyName)")
    }
}

