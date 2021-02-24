//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

class AvailabilityLabelTests: ZMSnapshotTestCase {

    // MARK: - List labels

    func testThatItRendersCorrectly_List_NoneAvailability() {
        verify(view: createLabelForList(.none))
    }

    func testThatItRendersCorrectly_List_AvailableAvailability() {
        verify(view: createLabelForList(.available))
    }

    func testThatItRendersCorrectly_List_AwayAvailability() {
        verify(view: createLabelForList(.away))
    }

    func testThatItRendersCorrectly_List_BusyAvailability() {
        verify(view: createLabelForList(.busy))
    }

    func createLabelForList(_ availability: Availability) -> UILabel {
        guard let user = ZMUser.selfUser() else { return UILabel() }
        user.availability = availability
        let attributedString = AvailabilityStringBuilder.string(for: user, with: .list)
        let label = UILabel()
        label.attributedText = attributedString
        label.font = FontSpec(.normal, .regular).font
        label.sizeToFit()
        return label
    }

    // MARK: - Participants labels

    func testThatItRendersCorrectly_Participants_NoneAvailability() {
        verify(view: createLabelForParticipants(.none))
    }

    func testThatItRendersCorrectly_Participants_AvailableAvailability() {
        verify(view: createLabelForParticipants(.available))
    }

    func testThatItRendersCorrectly_Participants_AwayAvailability() {
        verify(view: createLabelForParticipants(.away))
    }

    func testThatItRendersCorrectly_Participants_BusyAvailability() {
        verify(view: createLabelForParticipants(.busy))
    }

    func createLabelForParticipants(_ availability: Availability) -> UILabel {
        guard let user = ZMUser.selfUser() else { return UILabel() }
        user.availability = availability
        let attributedString = AvailabilityStringBuilder.string(for: user, with: .participants)
        let label = UILabel()
        label.attributedText = attributedString
        label.font = FontSpec(.small, .regular).font
        label.sizeToFit()
        return label
    }

    // MARK: - Placeholder labels

    func testThatItRendersCorrectly_Placeholder_NoneAvailability() {
        XCTAssertTrue(createLabelForPlaceholder(.none).frame.size.width == 0.0)
    }

    func testThatItRendersCorrectly_Placeholder_AvailableAvailability() {
        verify(view: createLabelForPlaceholder(.available))
    }

    func testThatItRendersCorrectly_Placeholder_AwayAvailability() {
        verify(view: createLabelForPlaceholder(.away))
    }

    func testThatItRendersCorrectly_Placeholder_BusyAvailability() {
        verify(view: createLabelForPlaceholder(.busy))
	}

    func createLabelForPlaceholder(_ availability: Availability) -> UILabel {
        guard let user = ZMUser.selfUser() else { return UILabel() }
        user.availability = availability
        let attributedString = AvailabilityStringBuilder.string(for: user, with: .placeholder, color: .lightGray)
        let label = UILabel()
        label.attributedText = attributedString
        label.font = FontSpec(.small, .semibold).font
        label.sizeToFit()
        return label
    }
}
