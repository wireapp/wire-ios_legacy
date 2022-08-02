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
import WireCommonComponents

final class ConversationInputBarViewControllerDropInteractionTests: XCTestCase {

    func testThatItHandlesDroppingFilesWithFlagEnabled() {
        let mockConversation = MockInputBarConversationType()
        let sut = ConversationInputBarViewController(conversation: mockConversation)
        let shareRestrictionManager = MediaShareRestrictionManagerMock(shareFlagEnabled: true)
        let dropProposal = sut.dropProposal(mediaShareRestrictionManager: shareRestrictionManager)

        XCTAssertEqual(dropProposal.operation, UIDropOperation.copy, file: #file, line: #line)
    }


    func testThatItPreventsDroppingFilesWithFlagEnabled() {
        let mockConversation = MockInputBarConversationType()
        let sut = ConversationInputBarViewController(conversation: mockConversation)
        let shareRestrictionManager = MediaShareRestrictionManagerMock(shareFlagEnabled: false)
        let dropProposal = sut.dropProposal(mediaShareRestrictionManager: shareRestrictionManager)

        XCTAssertEqual(dropProposal.operation, UIDropOperation.forbidden, file: #file, line: #line)
    }
}

// MARK: - Helpers

private class MediaShareRestrictionManagerMock: MediaShareRestrictionManager {
    let shareFlagEnabled: Bool
    init(shareFlagEnabled: Bool) {
        self.shareFlagEnabled = shareFlagEnabled
        super.init(sessionRestriction: nil)
    }

    override func isFileSharingFlagEnabled() -> Bool {
        return shareFlagEnabled
    }

}
