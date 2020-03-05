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

final class PollMessageCellTests: ConversationCellSnapshotTestCase {

    typealias CellConfiguration = (MockMessage) -> Void

    func testThatItRendersButton() {
        verify(message: makeMessage())
    }

    // MARK: - Helpers

    private func makeMessage(_ config: CellConfiguration? = nil) -> MockMessage {
        let mockCompositeMessage: MockMessage = MockMessageFactory.compositeMessage

        let mockCompositeMessageData = MockCompositeMessageData()
        let message = MockMessageFactory.textMessage(withText: "Who is your most favourite musician?")!
        let textItem: CompositeMessageItem = .text(message.backingTextMessageData)
        
        let items: [CompositeMessageItem] = ["Johann Sebastian Bach",
                                             "Johannes Chrysostomus Wolfgangus Theophilus Mozart",
                                             "Ludwig van Beethoven"].map {
            let mockButtonMessageData: MockButtonMessageData = MockButtonMessageData()
            mockButtonMessageData.title = $0
            let buttonItem: CompositeMessageItem = .button(mockButtonMessageData)
            
            return buttonItem
        }
        
        
        mockCompositeMessageData.items = [textItem] + items

        mockCompositeMessage.compositeMessageData = mockCompositeMessageData

        config?(mockCompositeMessage)
        return mockCompositeMessage
    }
}

final class MockButtonMessageData: ButtonMessageData {
    var title: String?
    
    var state: ButtonMessageState = .unselected
    
    func touchAction() {
        //no-op
    }
}
