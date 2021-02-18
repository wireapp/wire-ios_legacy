//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class SettingsTableViewControllerSnapshotTests: XCTestCase {
    var coreDataFixture: CoreDataFixture!

    var sut: SettingsTableViewController!
	var settingsCellDescriptorFactory: SettingsCellDescriptorFactory!
    var settingsPropertyFactory: SettingsPropertyFactory!
    var userSessionMock: MockZMUserSession!
    var selfUser: MockZMEditableUser!

	override func setUp() {
		super.setUp()

        coreDataFixture = CoreDataFixture()
        userSessionMock = MockZMUserSession()
        selfUser = MockZMEditableUser()

		settingsPropertyFactory = SettingsPropertyFactory(userSession: userSessionMock, selfUser: nil)
		settingsCellDescriptorFactory = SettingsCellDescriptorFactory(settingsPropertyFactory: settingsPropertyFactory, userRightInterfaceType: MockUserRight.self)

		MockUserRight.isPermitted = true
	}

    override func tearDown() {
        sut = nil
		settingsCellDescriptorFactory = nil
		settingsPropertyFactory = nil

        coreDataFixture = nil
        userSessionMock = nil
        selfUser = nil

        super.tearDown()
	}

    func testForSettingGroup() {
        // prevent app crash when checking Analytics.shared.isOptout
        Analytics.shared = Analytics(optedOut: true)
        let group = settingsCellDescriptorFactory.settingsGroup(isTeamMember: coreDataFixture.selfUser.isTeamMember)
        verify(group: group)
    }

    func testForAccountGroup() {
        let group = settingsCellDescriptorFactory.accountGroup(isTeamMember: coreDataFixture.selfUser.isTeamMember)
        verify(group: group)
    }

    func testForAccountGroupWithDisabledEditing() {
		MockUserRight.isPermitted = false

        let group = settingsCellDescriptorFactory.accountGroup(isTeamMember: coreDataFixture.selfUser.isTeamMember)
        verify(group: group)
    }

    // MARK: - options
    func testForOptionsGroup() {
        Settings.shared[.chatHeadsDisabled] = false
        let group = settingsCellDescriptorFactory.optionsGroup
        verify(group: group)
    }

    func testForOptionsGroupFullTableView() {
        setToLightTheme()
        
        let group = settingsCellDescriptorFactory.optionsGroup
        sut = SettingsTableViewController(group: group as! SettingsInternalGroupCellDescriptorType)

        sut.view.backgroundColor = .black
        
        // set the width of the VC, to calculate the height on content size
        sut.view.frame = CGRect(origin: .zero, size: CGSize.iPhoneSize.iPhone4_7)
        sut.view.layoutIfNeeded()

        verify(matching: sut, customSize: CGSize(width: CGSize.iPhoneSize.iPhone4_7.width, height: sut.tableView.contentSize.height))
    }
    
    func testThatApplockIsAvailableInOptionsGroup_WhenIsAvailable() {
        // given
        let appLock = AppLockModule.MockAppLockController()
        appLock.isAvailable = true
        userSessionMock.appLockController = appLock

        settingsPropertyFactory = .init(userSession: userSessionMock, selfUser: selfUser)
        settingsCellDescriptorFactory = .init(settingsPropertyFactory: settingsPropertyFactory,
                                              userRightInterfaceType: MockUserRight.self)
        
        // then
        XCTAssertTrue(settingsCellDescriptorFactory.isAppLockAvailable)
    }
    
    func testThatApplockIsNotAvailableInOptionsGroup_WhenIsNotAvailable() {
        // given
        let appLock = AppLockModule.MockAppLockController()
        appLock.isAvailable = false
        userSessionMock.appLockController = appLock

        settingsPropertyFactory = .init(userSession: userSessionMock, selfUser: selfUser)
        settingsCellDescriptorFactory = .init(settingsPropertyFactory: settingsPropertyFactory,
                                              userRightInterfaceType: MockUserRight.self)
        
        // then
        XCTAssertFalse(settingsCellDescriptorFactory.isAppLockAvailable)
    }

    // MARK: - dark theme
    func testForDarkThemeOptionsGroup() {
        setToLightTheme()

        let group = SettingsCellDescriptorFactory.darkThemeGroup(for: settingsPropertyFactory.property(.darkMode))
        verify(group: group)
    }
    
    private func verify(group: Any,
                        file: StaticString = #file,
                        testName: String = #function,
                        line: UInt = #line) {
        sut = SettingsTableViewController(group: group as! SettingsInternalGroupCellDescriptorType)
        
        sut.view.backgroundColor = .black
        
        verify(matching: sut, file: file, testName: testName, line: line)
    }
    
    // MARK: - advanced
    func testForAdvancedGroup() {
        let group = settingsCellDescriptorFactory.advancedGroup
        verify(group: group)
    }

    // MARK: - data usage permissions
    func testForDataUsagePermissionsForTeamMember() {
        let group = settingsCellDescriptorFactory.dataUsagePermissionsGroup(isTeamMember: true)
        verify(group: group)
    }
}
