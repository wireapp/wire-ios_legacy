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



/**
Available settings

- ChatHeadsDisabled:      Disable chat heads in conversation and self profile
- Markdown:               Enable markdown formatter for messages
- SkipFirstTimeUseChecks: Temporarily skip firts time checks
- PreferredFlashMode:     Flash mode for internal camera UI
- DarkMode:               Dark mode for conversation
- PriofileName:           User name
- SoundAlerts:            Sound alerts level
- AnalyticsOptOut:        Opt-Out analytics
- DisableSendButton:      Opt-Out of new send button
- Disable(.*):            Disable some app features (debug)
*/
enum SettingsPropertyName: String, CustomStringConvertible {
    
    // User defaults
    case chatHeadsDisabled = "ChatHeadsDisabled"
    case notificationContentVisible = "NotificationContentVisible"
    case markdown = "Markdown"
    
    case skipFirstTimeUseChecks = "SkipFirstTimeUseChecks"
    
    case preferredFlashMode = "PreferredFlashMode"
    
    case darkMode = "DarkMode"
    
    case disableSendButton = "DisableSendButton"
    
    // Profile
    case profileName = "ProfileName"
    case accentColor = "AccentColor"
    
    // AVS
    case soundAlerts = "SoundAlerts"
    
    // Analytics
    case analyticsOptOut = "AnalyticsOptOut"

    // Sounds
    case messageSoundName = "MessageSoundName"
    case callSoundName = "CallSoundName"
    case pingSoundName = "PingSoundName"

    // Open In
    case tweetOpeningOption = "TweetOpeningOption"
    case mapsOpeningOption = "MapsOpeningOption"
    case browserOpeningOption = "BrowserOpeningOption"
    
    // Debug
    
    case disableUI = "DisableUI"
    case disableAVS = "DisableAVS"
    case disableHockey = "DisableHockey"
    case disableAnalytics = "DisableAnalytics"
    case disableCallKit = "DisableCallKit"
    case sendV3Assets = "SendV3Assets"
    case callingProtocolStrategy = "CallingProtcolStrategy"
    case enableBatchCollections = "EnableBatchCollections"

    var changeNotificationName: String {
        return self.description + "ChangeNotification"
    }
    
    var description: String {
        return self.rawValue;
    }
}

enum SettingsPropertyValue: Equatable {
    case number(value: Int)
    case string(value: Swift.String)
    case bool(value: Swift.Bool)
    case none
    
    static func propertyValue(_ object: Any?) -> SettingsPropertyValue {
        switch(object) {
        case let intValue as Int:
            return SettingsPropertyValue.number(value: intValue)
            
        case let stringValue as Swift.String:
            return SettingsPropertyValue.string(value: stringValue)
            
        case let boolValue as Swift.Bool:
            return SettingsPropertyValue.bool(value: boolValue)
            
        default:
            return .none
        }
    }
    
    func value() -> Any? {
        switch (self) {
        case .number(let value):
            return value as AnyObject?
        case .string(let value):
            return value as AnyObject?
        case .bool(let value):
            return value as AnyObject?
        case .none:
            return .none
        }
    }
}

func ==(a: SettingsPropertyValue, b: SettingsPropertyValue) -> Bool {
    switch (a, b) {
    case (.string(let a), .string(let b)) where a == b: return true
    case (.number(let a), .number(let b)) where a == b: return true
    case (.bool(let a), .bool(let b)) where a == b: return true
    case (.none, .none): return true
    
    case (.number(let a), .bool(let b)) where ((a == 0) && (b == false)) || ((a > 0) && (b == true)): return true
    case (.bool(let a), .number(let b)) where ((a == false) && (b == 0)) || ((a == true) && (b > 0)): return true
        
    default: return false
    }
}

// To enable simple Bool creation
extension Bool {
    init<T : Integer>(_ integer: T){
        self.init(integer != 0)
    }
}

/**
 *  Generic settings property
 */
protocol SettingsProperty {
    var propertyName : SettingsPropertyName { get }
    func value() -> SettingsPropertyValue
    func set(newValue: SettingsPropertyValue) throws
}

extension SettingsProperty {
    internal func rawValue() -> Any? {
        return self.value().value()
    }
}

/**
 Set value to property

 - parameter property: Property to set the value on
 - parameter expr:     Property value (raw)
 */
func << (property: inout SettingsProperty, expr: @autoclosure () -> Any) throws {
    let value = expr()
    
    try property.set(newValue: SettingsPropertyValue.propertyValue(value))
}

/**
 Set value to property
 
 - parameter property: Property to set the value on
 - parameter expr:     Property value
 */
func << (property: inout SettingsProperty, expr: @autoclosure () -> SettingsPropertyValue) throws {
    let value = expr()
    
    try property.set(newValue: value)
}

/**
 Read value from property
 
 - parameter value:    Value to assign
 - parameter property: Property to read the value from
 */
func << (value: inout Any?, property: SettingsProperty) {
    value = property.rawValue()
}

/// Generic user defaults property
class SettingsUserDefaultsProperty : SettingsProperty {
    internal func set(newValue: SettingsPropertyValue) throws {
        self.userDefaults.set(newValue.value(), forKey: self.userDefaultsKey)
        NotificationCenter.default.post(name: Notification.Name(rawValue: self.propertyName.changeNotificationName), object: self)
    }
    
    internal func value() -> SettingsPropertyValue {
        switch self.userDefaults.object(forKey: self.userDefaultsKey) as AnyObject? {
        case let boolValue as Bool:
            return SettingsPropertyValue.propertyValue(boolValue as AnyObject?)
        case let numberValue as NSNumber:
            return SettingsPropertyValue.propertyValue(numberValue.intValue as AnyObject?)
        case let stringValue as String:
            return SettingsPropertyValue.propertyValue(stringValue as AnyObject?)
        default:
            return .none
        }
    }

    let propertyName : SettingsPropertyName
    let userDefaults : UserDefaults
    
    let userDefaultsKey: String
    
    init(propertyName: SettingsPropertyName, userDefaultsKey: String, userDefaults: UserDefaults) {
        self.propertyName = propertyName
        self.userDefaultsKey = userDefaultsKey
        self.userDefaults = userDefaults
    }
}

typealias GetAction = (SettingsBlockProperty) -> SettingsPropertyValue
typealias SetAction = (SettingsBlockProperty, SettingsPropertyValue) throws -> ()

/// Genetic block property
open class SettingsBlockProperty : SettingsProperty {
    let propertyName : SettingsPropertyName
    func value() -> SettingsPropertyValue {
        return self.getAction(self)
    }
    
    func set(newValue: SettingsPropertyValue) throws {
        try self.setAction(self, newValue)
        NotificationCenter.default.post(name: Notification.Name(rawValue: self.propertyName.changeNotificationName), object: self)
    }
    
    fileprivate let getAction : GetAction
    fileprivate let setAction : SetAction
    
    init(propertyName: SettingsPropertyName, getAction: @escaping GetAction, setAction: @escaping SetAction) {
        self.propertyName = propertyName
        self.getAction = getAction
        self.setAction = setAction
    }
}
