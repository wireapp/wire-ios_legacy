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
- Disable(.*):            Disable some app features (debug)
*/
enum SettingsPropertyName: String, CustomStringConvertible {
    
    // User defaults
    case ChatHeadsDisabled = "ChatHeadsDisabled"
    case NotificationContentVisible = "NotificationContentVisible"
    case Markdown = "Markdown"
    
    case SkipFirstTimeUseChecks = "SkipFirstTimeUseChecks"
    
    case PreferredFlashMode = "PreferredFlashMode"
    
    case DarkMode = "DarkMode"
    
    // Profile
    case ProfileName = "ProfileName"
    case AccentColor = "AccentColor"
    
    // AVS
    case SoundAlerts = "SoundAlerts"
    
    // Analytics
    case AnalyticsOptOut = "AnalyticsOptOut"

    // Sounds
    
    case MessageSoundName = "MessageSoundName"
    case CallSoundName = "CallSoundName"
    case PingSoundName = "PingSoundName"
    
    // Debug
    
    case DisableUI = "DisableUI"
    case DisableAVS = "DisableAVS"
    case DisableHockey = "DisableHockey"
    case DisableAnalytics = "DisableAnalytics"

    var changeNotificationName: String {
        return self.description + "ChangeNotification"
    }
    
    var description: String {
        return self.rawValue;
    }
}

enum SettingsPropertyValue: Equatable {
    case Number(value: Int)
    case String(value: Swift.String)
    case Bool(value: Swift.Bool)
    case None
    
    static func propertyValue(object: AnyObject?) -> SettingsPropertyValue {
        switch(object) {
        case let intValue as Int:
            return SettingsPropertyValue.Number(value: intValue)
            
        case let stringValue as Swift.String:
            return SettingsPropertyValue.String(value: stringValue)
            
        case let boolValue as Swift.Bool:
            return SettingsPropertyValue.Bool(value: boolValue)
            
        default:
            return .None
        }
    }
    
    func value() -> AnyObject? {
        switch (self) {
        case .Number(let value):
            return value
        case .String(let value):
            return value
        case .Bool(let value):
            return value
        case .None:
            return .None
        }
    }
}

func ==(a: SettingsPropertyValue, b: SettingsPropertyValue) -> Bool {
    switch (a, b) {
    case (.String(let a), .String(let b)) where a == b: return true
    case (.Number(let a), .Number(let b)) where a == b: return true
    case (.Bool(let a), .Bool(let b)) where a == b: return true
    case (.None, .None): return true
    
    case (.Number(let a), .Bool(let b)) where ((a == 0) && (b == false)) || ((a > 0) && (b == true)): return true
    case (.Bool(let a), .Number(let b)) where ((a == false) && (b == 0)) || ((a == true) && (b > 0)): return true
        
    default: return false
    }
}

// To enable simple Bool creation
extension Bool {
    init<T : IntegerType>(_ integer: T){
        self.init(integer != 0)
    }
}

/**
 *  Generic settings property
 */
protocol SettingsProperty {
    var propertyName : SettingsPropertyName { get }
    var propertyValue : SettingsPropertyValue { get set }
}

/**
 Set value to property

 - parameter property: Property to set the value on
 - parameter expr:     Property value (raw)
 */
func << (inout property: SettingsProperty, @autoclosure expr: () -> AnyObject) {
    let value = expr()
    
    property.propertyValue = SettingsPropertyValue.propertyValue(value)
}

/**
 Set value to property
 
 - parameter property: Property to set the value on
 - parameter expr:     Property value
 */
func << (inout property: SettingsProperty, @autoclosure expr: () -> SettingsPropertyValue) {
    let value = expr()
    
    property.propertyValue = value
}

/**
 Read value from property
 
 - parameter value:    Value to assign
 - parameter property: Property to read the value from
 */
func << (inout value: AnyObject?, let property: SettingsProperty) {
    value = property.propertyValue.value()
}

/// Generic user defaults property
class SettingsUserDefaultsProperty : SettingsProperty {
    let propertyName : SettingsPropertyName
    let userDefaults : NSUserDefaults
    var propertyValue : SettingsPropertyValue {
        set (newValue) {
            self.userDefaults.setObject(newValue.value(), forKey: self.userDefaultsKey)
            NSNotificationCenter.defaultCenter().postNotificationName(self.propertyName.changeNotificationName, object: self)
        }
        get {
            let value : AnyObject? = self.userDefaults.objectForKey(self.userDefaultsKey)
            if let numberValue : NSNumber = value as? NSNumber {
                return SettingsPropertyValue.propertyValue(numberValue.integerValue)
            }
            else if let stringValue : String = value as? String {
                return SettingsPropertyValue.propertyValue(stringValue)
            }
            else {
                return .None
            }
        }
    }
    let userDefaultsKey: String
    
    init(propertyName: SettingsPropertyName, userDefaultsKey: String, userDefaults: NSUserDefaults) {
        self.propertyName = propertyName
        self.userDefaultsKey = userDefaultsKey
        self.userDefaults = userDefaults
    }
}

typealias GetAction = (SettingsBlockProperty) -> SettingsPropertyValue
typealias SetAction = (SettingsBlockProperty, SettingsPropertyValue) -> ()

/// Genetic block property
public class SettingsBlockProperty : SettingsProperty {
    let propertyName : SettingsPropertyName
    var propertyValue : SettingsPropertyValue {
        set (newValue) {
            self.setAction(self, newValue)
            NSNotificationCenter.defaultCenter().postNotificationName(self.propertyName.changeNotificationName, object: self)
        }
        get {
            return self.getAction(self)
        }
    }
    private let getAction : GetAction
    private let setAction : SetAction
    
    init(propertyName: SettingsPropertyName, getAction: GetAction, setAction: SetAction) {
        self.propertyName = propertyName
        self.getAction = getAction
        self.setAction = setAction
    }
}
