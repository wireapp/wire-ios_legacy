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


import XCTest
@testable import Wire

@objc class MockZMEditableUser: NSObject, ZMEditableUser {
    var name: String! = ""
    var accentColorValue: ZMAccentColor = .undefined
    var emailAddress: String! = ""
    var phoneNumber: String! = ""
    
    var originalProfileImageData: Data!
    
    func deleteProfileImage() {
        // no-op
    }
}

class MockZMUserSession: ZMUserSessionInterface {
    func performChanges(_ block: @escaping () -> Swift.Void) {
        block()
    }
    
    func enqueueChanges(_ block: @escaping () -> Swift.Void) {
        block()
    }
    
    var isNotificationContentHidden: Bool = false
}

class ZMMockAVSMediaManager: AVSMediaManagerInterface {
    var intensityLevel : AVSIntensityLevel = .none
    
    func playMediaByName(_ name: String!) { }
}

class ZMMockAnalytics: AnalyticsInterface {
    var isOptedOut: Bool = false
}


class SettingsPropertyTests: XCTestCase {
    let userDefaults: UserDefaults = UserDefaults.standard
    
    func saveAndCheck<T: Any>( _ property: SettingsProperty, value: T) -> Bool where T: Equatable {
        var property = property
        property << value
        if let readValue : T = property.propertyValue.value() as? T {
            return value == readValue
        }
        else {
            return false
        }
    }
    
    // User defaults
    
    func testThatIntegerUserDefaultsSettingSave() {
        // given
        let property = SettingsUserDefaultsProperty(propertyName: SettingsPropertyName.DarkMode, userDefaultsKey: UserDefaultColorScheme, userDefaults: self.userDefaults)
        // when & then
        XCTAssertTrue(self.saveAndCheck(property, value: "dark"))
    }
    
    func testThatBoolUserDefaultsSettingSave() {
        // given
        let property = SettingsUserDefaultsProperty(propertyName: SettingsPropertyName.ChatHeadsDisabled, userDefaultsKey: UserDefaultChatHeadsDisabled, userDefaults: self.userDefaults)
        // when & then
        XCTAssertTrue(self.saveAndCheck(property, value: true))
    }
    
    
    
    func testThatNamePropertySetsValue() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let analytics = ZMMockAnalytics()
        
        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, analytics: analytics, mediaManager: mediaManager, userSession : userSession, selfUser: selfUser)
        
        let property = factory.property(SettingsPropertyName.ProfileName)
        // when & then
        XCTAssertTrue(self.saveAndCheck(property, value: "Test"))
    }
    
    func testThatSoundLevelPropertySetsValue() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let analytics = ZMMockAnalytics()

        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, analytics: analytics, mediaManager: mediaManager, userSession : userSession, selfUser: selfUser)
        
        let property = factory.property(SettingsPropertyName.SoundAlerts)
        // when & then
        XCTAssertTrue(self.saveAndCheck(property, value: 1))
    }
    
    func testThatAnalyticsPropertySetsValue() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let analytics = ZMMockAnalytics()

        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, analytics: analytics, mediaManager: mediaManager, userSession : userSession, selfUser: selfUser)
        
        let property = factory.property(SettingsPropertyName.AnalyticsOptOut)
        // when & then
        XCTAssertTrue(self.saveAndCheck(property, value: true))
    }
    
    func testThatIntegerBlockSettingSave() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let analytics = ZMMockAnalytics()

        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, analytics: analytics, mediaManager: mediaManager, userSession : userSession, selfUser: selfUser)

        let property = factory.property(SettingsPropertyName.SoundAlerts)
        // when & then
        XCTAssertTrue(self.saveAndCheck(property, value: 1))
    }
    
}
