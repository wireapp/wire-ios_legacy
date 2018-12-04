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

@objcMembers class MockZMEditableUser: MockUser, ZMEditableUser, ValidatorType {
    var enableReadReceipts: Bool = false
    var originalProfileImageData: Data!
    
    func deleteProfileImage() {
        // no-op
    }
    
    static func validateName(_ ioName: AutoreleasingUnsafeMutablePointer<NSString?>?) throws {
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
    var isMicrophoneMuted: Bool = false

    var intensityLevel : AVSIntensityLevel = .none
    
    func playMediaByName(_ name: String!) { }
}

class ZMMockTracking: TrackingInterface {
    var disableCrashAndAnalyticsSharing: Bool = false
}

class SettingsPropertyTests: XCTestCase {
    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = .standard
    }

    override func tearDown() {
        userDefaults = nil
        super.tearDown()
    }

    
    func saveAndCheck<T>(_ property: SettingsProperty, value: T, file: String = #file, line: UInt = #line) throws where T: Equatable {
        var property = property
        try property << value
        if let readValue : T = property.rawValue() as? T {
            if value != readValue {
                recordFailure(
                    withDescription: "Wrong property value, read \(readValue) but expected \(value)",
                    inFile: file,
                    atLine: Int(line),
                    expected: true
                )
            }
        }
        else {
            recordFailure(
                withDescription: "Unable to read property value",
                inFile: file,
                atLine: Int(line),
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
        let tracking = ZMMockTracking()
        
        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, tracking: tracking, mediaManager: mediaManager, userSession: userSession, selfUser: selfUser)
        
        let property = factory.property(SettingsPropertyName.profileName)
        // when & then
        try! self.saveAndCheck(property, value: "Test")
    }
    
    func testThatSoundLevelPropertySetsValue() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let tracking = ZMMockTracking()

        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, tracking: tracking, mediaManager: mediaManager, userSession: userSession, selfUser: selfUser)
        
        let property = factory.property(SettingsPropertyName.soundAlerts)
        // when & then
        try! self.saveAndCheck(property, value: 1)
    }
    
    func testThatAnalyticsPropertySetsValue() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let tracking = ZMMockTracking()
        
        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, tracking: tracking, mediaManager: mediaManager, userSession: userSession, selfUser: selfUser)
        
        let property = factory.property(SettingsPropertyName.disableCrashAndAnalyticsSharing)
        // when & then
        try! self.saveAndCheck(property, value: true)
    }
    
    func testThatIntegerBlockSettingSave() {
        // given
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let tracking = ZMMockTracking()

        let factory = SettingsPropertyFactory(userDefaults: self.userDefaults, tracking: tracking, mediaManager: mediaManager, userSession : userSession, selfUser: selfUser)

        let property = factory.property(SettingsPropertyName.soundAlerts)
        // when & then
        try! self.saveAndCheck(property, value: 1)
    }

    func testThatItCanSetAIntegerUserDefaultsSettingsPropertyLargerThanOne() {
        // given
        let factory = SettingsPropertyFactory(
            userDefaults: userDefaults,
            tracking: ZMMockTracking(),
            mediaManager: ZMMockAVSMediaManager(),
            userSession : MockZMUserSession(),
            selfUser: MockZMEditableUser()
        )

        let property = factory.property(.tweetOpeningOption)
        // when & then
        try? saveAndCheck(property, value: 2)
    }
    
    // MARK: - Accounts
    
    func testThatIntegerUserDefaultsSettingForAccountSave() {
        // given
        let settings = Settings()
        let account = Account(userName: "bob", userIdentifier: UUID())
        let key = "IntegerKey"
        XCTAssertNil(settings.value(for: key, in: account) as Int?)
        
        // when
        settings.setValue(42, for: key, in: account)
        
        // then
        let result: Int? = settings.value(for: key, in: account)
        XCTAssertEqual(result, 42)
    }
    
    func testThatBoolUserDefaultsSettingForAccountSave() {
        // given
        let settings = Settings()
        let account = Account(userName: "bob", userIdentifier: UUID())
        let key = "BooleanKey"
        XCTAssertNil(settings.value(for: key, in: account) as Bool?)
        
        // when
        settings.setValue(true, for: key, in: account)
        
        // then
        let result: Bool? = settings.value(for: key, in: account)
        XCTAssertEqual(result, true)
    }
    
    func testThatSharedSettingIsMigratedToAccount() {
        // given
        let settings = Settings()
        let account = Account(userName: "bob", userIdentifier: UUID())
        let key = "IntegerKey"
        settings.defaults().setValue(42, forKey: key)
        
        // when & then
        let result: Int? = settings.value(for: key, in: account)
        XCTAssertNil(settings.defaults().object(forKey: key))
        XCTAssertEqual(result, 42)
    }
}
