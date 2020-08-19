//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

	override func setUp() {
		super.setUp()

        coreDataFixture = CoreDataFixture()

		settingsPropertyFactory = SettingsPropertyFactory(userSession: nil, selfUser: nil)
		settingsCellDescriptorFactory = SettingsCellDescriptorFactory(settingsPropertyFactory: settingsPropertyFactory, userRightInterfaceType: MockUserRight.self)

		MockUserRight.isPermitted = true
	}

    override func tearDown() {
        sut = nil
		settingsCellDescriptorFactory = nil
		settingsPropertyFactory = nil

        coreDataFixture = nil

        super.tearDown()
	}

    func testForSettingGroup() {
        let group = settingsCellDescriptorFactory.settingsGroup()
        sut = SettingsTableViewController(group: group)

        sut.view.backgroundColor = .black

        verify(matching: sut)
    }

    func testForAccountGroup() {
        let group = settingsCellDescriptorFactory.accountGroup()
        sut = SettingsTableViewController(group: group as! SettingsInternalGroupCellDescriptorType)

        sut.view.backgroundColor = .black

        verify(matching: sut)
    }

    func testForAccountGroupWithDisabledEditing() {
		MockUserRight.isPermitted = false

		let group = settingsCellDescriptorFactory.accountGroup()
        sut = SettingsTableViewController(group: group as! SettingsInternalGroupCellDescriptorType)

        sut.view.backgroundColor = .black

        verify(matching: sut)
    }

    // MARK: - options
    func testForOptionsGroup() {
        Settings.shared[.chatHeadsDisabled] = false
        let group = settingsCellDescriptorFactory.optionsGroup
        sut = SettingsTableViewController(group: group as! SettingsInternalGroupCellDescriptorType)

        sut.view.backgroundColor = .black

        verify(matching: sut)
    }

    func testForOptionsGroupScrollToBottom() {
        setToLightTheme()
        
        let group = settingsCellDescriptorFactory.optionsGroup
        sut = SettingsTableViewController(group: group as! SettingsInternalGroupCellDescriptorType)

        sut.view.backgroundColor = .black

        sut.tableView.setContentOffset(CGPoint(x:0, y:CGFloat.greatestFiniteMagnitude), animated: false)

        verify(matching: sut)
    }

    // MARK: - dark theme
    func testForDarkThemeOptionsGroup() {
        setToLightTheme()

        let group = SettingsCellDescriptorFactory.darkThemeGroup(for: settingsPropertyFactory.property(.darkMode))
        sut = SettingsTableViewController(group: group as! SettingsInternalGroupCellDescriptorType)

        sut.view.backgroundColor = .black

        verify(matching: sut)
    }
    
    // MARK: - advanced
    func testForAdvancedGroup() {
        let group = settingsCellDescriptorFactory.advancedGroup
        sut = SettingsTableViewController(group: group as! SettingsInternalGroupCellDescriptorType)
        
        sut.view.backgroundColor = .black
        
        verify(matching: sut)
    }
}
