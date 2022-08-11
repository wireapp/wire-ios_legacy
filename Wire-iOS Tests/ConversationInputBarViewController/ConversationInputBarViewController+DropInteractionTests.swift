//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

final class ConversationInputBarViewControllerDropInteractionTests: XCTestCase {

    func testThatItHandlesDroppingFiles_FlagEnabled() {
        // GIVEN
        let mockConversation = MockInputBarConversationType()
        let sut = ConversationInputBarViewController(conversation: mockConversation)
        let shareRestrictionManager = MediaShareRestrictionManagerMock(canFilesBeShared: true)

        // WHEN
        let dropProposal = sut.dropProposal(mediaShareRestrictionManager: shareRestrictionManager)

        // THEN
        XCTAssertEqual(dropProposal.operation, UIDropOperation.copy, file: #file, line: #line)
    }

    func testThatItPreventsDroppingFiles_FlagDisabled() {
        // GIVEN
        let mockConversation = MockInputBarConversationType()
        let sut = ConversationInputBarViewController(conversation: mockConversation)
        let shareRestrictionManager = MediaShareRestrictionManagerMock(canFilesBeShared: false)

        // WHEN
        let dropProposal = sut.dropProposal(mediaShareRestrictionManager: shareRestrictionManager)

        // THEN
        XCTAssertEqual(dropProposal.operation, UIDropOperation.forbidden, file: #file, line: #line)
    }

}

// MARK: - Helpers

private class MediaShareRestrictionManagerMock: MediaShareRestrictionManager {

    let canFilesBeShared: Bool

    init(canFilesBeShared: Bool) {
        self.canFilesBeShared = canFilesBeShared

        super.init(sessionRestriction: nil)
    }

    override var isFileSharingFlagEnabled: Bool {
        return canFilesBeShared
    }

}
