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

@objc class MockZMEditableUser: MockUser, ZMEditableUser, ValidatorType {
    var originalProfileImageData: Data!
    
    func deleteProfileImage() {
        // no-op
    }
    
    static func validateName(_ ioName: AutoreleasingUnsafeMutablePointer<NSString?>!) throws {
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

class ZMMockCrashlogManager: CrashlogManager {
    var isCrashManagerDisabled: Bool = false
}

class SettingsPropertyTests: XCTestCase {
    let userDefaults: UserDefaults = UserDefaults.standard
    
    func saveAndCheck<T>(_ property: SettingsProperty, value: T, file: String = #file, line: UInt = #line) throws where T: Equatable {
        var property = property
        try property << value
        if let readValue : T = property.rawValue() as? T {
            if value != readValue {
                recordFailure(
                    withDescription: "Wrong property value, read \(readValue) but expected \(value)",
                    inFile: file,
                    atLine: line,
                    expected: true
                )
            }
        }
        else {
            recordFailure(
                withDescription: "Unable to read property value",
                inFile: file,
                atLine: line,
                expected: true
            )
        }
    }
    
    // User defaults
    
    func testThatIntegerUserDefaultsSettingSave() {
        // given
        let property = SettingsUserDefaultsProperty(propertyName: SettingsPropertyName.darkMode, userDefaultsKey: UserDefaultColorScheme, userDefaults: self.userDefaults)
        // when & then
        try! self.saveAndCheck(property, value: "light")
    }
    
    func testThatBoolUserDefaultsSettingSave() {
        // given
        let property = SettingsUserDefaultsProperty(propertyName: SettingsPropertyName.chatHeadsDisabled, userDefaultsKey: UserDefaultChatHeadsDisabled, userDefaults: self.userDefaults)
        // when & then
        try! self.saveAndCheck(property, value: NSNumber(value: true))
    }
    
    func testThatNamePropertySetsValue() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let analytics = ZMMockAnalytics()
        
        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, analytics: analytics, mediaManager: mediaManager, userSession: userSession, selfUser: selfUser)
        
        let property = factory.property(SettingsPropertyName.profileName)
        // when & then
        try! self.saveAndCheck(property, value: "Test")
    }
    
    func testThatSoundLevelPropertySetsValue() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let analytics = ZMMockAnalytics()

        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, analytics: analytics, mediaManager: mediaManager, userSession: userSession, selfUser: selfUser)
        
        let property = factory.property(SettingsPropertyName.soundAlerts)
        // when & then
        try! self.saveAndCheck(property, value: 1)
    }
    
    func testThatAnalyticsPropertySetsValue() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let analytics = ZMMockAnalytics()
        let crashlogManager = ZMMockCrashlogManager()
        
        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, analytics: analytics, mediaManager: mediaManager, userSession: userSession, selfUser: selfUser, crashlogManager: crashlogManager)
        
        let property = factory.property(SettingsPropertyName.analyticsOptOut)
        // when & then
        try! self.saveAndCheck(property, value: true)
    }
    
    func testThatIntegerBlockSettingSave() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let analytics = ZMMockAnalytics()

        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, analytics: analytics, mediaManager: mediaManager, userSession : userSession, selfUser: selfUser)

        let property = factory.property(SettingsPropertyName.soundAlerts)
        // when & then
        try! self.saveAndCheck(property, value: 1)
    }

    func testThatItCanSetAIntegerUserDefaultsSettingsPropertyLargerThanOne() {
        // given
        let factory = SettingsPropertyFactory(
            userDefaults: userDefaults,
            analytics: ZMMockAnalytics(),
            mediaManager: ZMMockAVSMediaManager(),
            userSession : MockZMUserSession(),
            selfUser: MockZMEditableUser()
        )

        let property = factory.property(.tweetOpeningOption)
        // when & then
        try? saveAndCheck(property, value: 2)
    }
    
}
