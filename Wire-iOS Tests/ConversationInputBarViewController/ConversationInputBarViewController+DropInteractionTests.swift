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

    func testThatItHandlesDroppingFiles() {

        // Drop text and the clipboard is enabled.
        assert(
            input: (isText: true, isClipboardEnabled: true, canFilesBeShared: false),
            output: .copy
        )

        // Drop text and the clipboard is disabled.
        assert(
            input: (isText: true, isClipboardEnabled: false, canFilesBeShared: false),
            output: .forbidden
        )

        // Drop file, the clipboard is disabled and the file sharing feature is disabled.
        assert(
            input: (isText: false, isClipboardEnabled: false, canFilesBeShared: false),
            output: .forbidden
        )

        // Drop file, the clipboard is disabled and the file sharing feature is enabled.
        assert(
            input: (isText: false, isClipboardEnabled: false, canFilesBeShared: true),
            output: .forbidden
        )

        // Drop file, the clipboard is enabled and the file sharing feature is disabled.
        assert(
            input: (isText: false, isClipboardEnabled: true, canFilesBeShared: false),
            output: .forbidden
        )

        // Drop file when the clipboard is enabled and the file sharing feature is enabled.
        assert(
            input: (isText: false, isClipboardEnabled: true, canFilesBeShared: true),
            output: .copy
        )

    }
}

// MARK: - Helpers

extension ConversationInputBarViewControllerDropInteractionTests {

    typealias Input = (isText: Bool, isClipboardEnabled: Bool, canFilesBeShared: Bool)
    typealias Output = UIDropOperation

    private func assert(input: Input, output: Output, file: StaticString = #file, line: UInt = #line) {
        let mockConversation = MockInputBarConversationType()
        let sut = ConversationInputBarViewController(conversation: mockConversation)
        let dropProposal = sut.dropProposal(isText: input.isText,
                                            isClipboardEnabled: input.isClipboardEnabled,
                                            canFilesBeShared: input.canFilesBeShared)

        XCTAssertEqual(dropProposal.operation, output, file: file, line: line)
    }

}
