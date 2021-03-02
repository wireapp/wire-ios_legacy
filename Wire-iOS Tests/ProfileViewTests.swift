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

final class ProfileViewTests: ZMSnapshotTestCase {

    func test_DefaultOptions() {
        verifyProfile(options: [])
    }

    func testDefaultOptions_NoAvailability() {
        verifyProfile(options: [], availability: .none)
    }

    func testDefaultOptions_NoAvailability_Edit() {
        verifyProfile(options: [.allowEditingAvailability], availability: .none)
    }

    func test_DefaultOptions_AllowEditing() {
        verifyProfile(options: [.allowEditingAvailability])
    }

    func test_HideName() {
        verifyProfile(options: [.hideUsername])
    }

    func test_HideTeamName() {
        verifyProfile(options: [.hideTeamName])
    }

    func test_HideHandle() {
        verifyProfile(options: [.hideHandle])
    }

    func test_HideNameAndHandle() {
        verifyProfile(options: [.hideUsername, .hideHandle])
    }

    func test_HideAvailability() {
        verifyProfile(options: [.hideAvailability])
    }

    // MARK: - Helpers

    func verifyProfile(options: ProfileHeaderViewController.Options, availability: Availability = .available, file: StaticString = #file, line: UInt = #line) {
        let selfUser = MockUserType.createSelfUser(name: "selfUser", inTeam: UUID())
        selfUser.teamName = "Stunning"
        selfUser.handle = "browncow"
        selfUser.availability = availability

        let sut = ProfileHeaderViewController(user: selfUser, viewer: selfUser, options: options)
        sut.colorSchemeVariant = .dark
        sut.view.frame.size = sut.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        sut.view.backgroundColor = .black

        verify(view: sut.view, file: file, line: line)
    }

}
