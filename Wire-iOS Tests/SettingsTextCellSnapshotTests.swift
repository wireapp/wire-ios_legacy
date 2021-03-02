//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class SettingsTextCellSnapshotTests: CoreDataSnapshotTestCase {

    var sut: SettingsTextCell!
    var settingsCellDescriptorFactory: SettingsCellDescriptorFactory!

    override func setUp() {
        super.setUp()

        sut = SettingsTextCell()

        let selfUser = MockUserType.createSelfUser(name: "Johannes Chrysostomus Wolfgangus Theophilus Mozart")
        let settingsPropertyFactory = SettingsPropertyFactory(userSession: SessionManager.shared?.activeUserSession, selfUser: selfUser)

        settingsCellDescriptorFactory = SettingsCellDescriptorFactory(settingsPropertyFactory: settingsPropertyFactory)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForNameElementWithALongName(){
        let cellDescriptor = settingsCellDescriptorFactory.nameElement()
        sut.descriptor = cellDescriptor
        cellDescriptor.featureCell(sut)
        sut.backgroundColor = .black

        let mockTableView = sut.wrapInTableView()
        mockTableView.backgroundColor = .black

        XCTAssert(sut.textInput.isUserInteractionEnabled)

        verify(view: mockTableView)
    }

    func testThatTextFieldIsDisabledWhenEnabledFlagIsFalse(){
        // GIVEN
        let cellDescriptor = settingsCellDescriptorFactory.nameElement(enabled: false)

        // WHEN
        cellDescriptor.featureCell(sut)

        // THEN
        XCTAssertFalse(sut.textInput.isUserInteractionEnabled)
    }
}
