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
import WireCommonComponents
@testable import Wire

final class MockZMEditableUser: MockUser, ZMEditableUser, ValidatorType {
    var needsRichProfileUpdate: Bool = false

    var enableReadReceipts: Bool = false
    var originalProfileImageData: Data!

    func deleteProfileImage() {
        // no-op
    }

    static func validate(name: inout String?) throws -> Bool {
        return false
    }

}

final class ZMMockAVSMediaManager: AVSMediaManagerInterface {
    var isMicrophoneMuted: Bool = false

    var intensityLevel: AVSIntensityLevel = .none

    func playMediaByName(_ name: String!) { }
}

final class ZMMockTracking: TrackingInterface {
    var disableCrashSharing: Bool = false
    var disableAnalyticsSharing: Bool = false
    var disableCrashAndAnalyticsSharing: Bool = false
}

final class SettingsPropertyTests: XCTestCase {
    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = .standard
    }

    override func tearDown() {
        userDefaults = nil
        super.tearDown()
    }


    func saveAndCheck<T>(_ property: SettingsProperty,
                         value: T,
                         file: String = #file,
                         line: UInt = #line) throws where T: Equatable {
        var property = property
        try property << value
        if let readValue: T = property.rawValue() as? T {
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
        let property = SettingsUserDefaultsProperty(propertyName: SettingsPropertyName.darkMode, userDefaultsKey: SettingKey.colorScheme.rawValue, userDefaults: self.userDefaults)
        // when & then
        try! self.saveAndCheck(property, value: "light")
    }

    func testThatBoolUserDefaultsSettingSave() {
        // given
        let property = SettingsUserDefaultsProperty(propertyName: SettingsPropertyName.chatHeadsDisabled, userDefaultsKey: SettingKey.chatHeadsDisabled.rawValue, userDefaults: self.userDefaults)
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

    private var settingsPropertyFactory: SettingsPropertyFactory {
        let selfUser = MockZMEditableUser()
        let userSession = MockZMUserSession()
        let mediaManager = ZMMockAVSMediaManager()
        let tracking = ZMMockTracking()

        return SettingsPropertyFactory(userDefaults: userDefaults, tracking: tracking, mediaManager: mediaManager, userSession: userSession, selfUser: selfUser)
    }

    func testThatDarkThemePropertySetsValue() {
        // given
        let factory = settingsPropertyFactory

        let property = factory.property(SettingsPropertyName.darkMode)
        // when & then
        try! saveAndCheck(property, value: 2)
    }


    func testThatSoundLevelPropertySetsValue() {
        // given
        let factory = settingsPropertyFactory

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

        let property = factory.property(SettingsPropertyName.disableCrashSharing)
        // when & then
        try! self.saveAndCheck(property, value: true)
    }

    func testThatIntegerBlockSettingSave() {
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

    func testThatItCanSetAIntegerUserDefaultsSettingsPropertyLargerThanOne() {
        // given
        let factory = SettingsPropertyFactory(
            userDefaults: userDefaults,
            tracking: ZMMockTracking(),
            mediaManager: ZMMockAVSMediaManager(),
            userSession: MockZMUserSession(),
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
        let key = SettingKey.blackListDownloadInterval
        XCTAssertNil(settings.value(for: key, in: account) as Int?)

        // when
        settings.setValue(42, settingKey: key, in: account)

        // then
        let result: Int? = settings.value(for: key, in: account)
        XCTAssertEqual(result, 42)
    }

    func testThatBoolUserDefaultsSettingForAccountSave() {
        // given
        let settings = Settings()
        let account = Account(userName: "bob", userIdentifier: UUID())
        let key = SettingKey.disableMarkdown
        XCTAssertNil(settings.value(for: key, in: account) as Bool?)

        // when
        settings.setValue(true, settingKey: key, in: account)

        // then
        let result: Bool? = settings.value(for: key, in: account)
        XCTAssertEqual(result, true)
    }

    func testThatSharedSettingIsMigratedToAccount() {
        // given
        let settings = Settings()
        let account = Account(userName: "bob", userIdentifier: UUID())
        let key = SettingKey.blackListDownloadInterval
        let value: Int = 42
        settings[key] = value

        // when & then
        let result: Int? = settings.value(for: key, in: account)
        let settingVal: Int? = settings[key]
        XCTAssertNil(settingVal)
        XCTAssertEqual(result, value)
    }
}
