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

final class CompositeMessageCellTests: ConversationCellSnapshotTestCase {

    typealias CellConfiguration = (MockMessage) -> Void

    func testThatItRendersErrorMessage() {
        verify(message: makeMessage(), allWidths: false)
    }

    func testThatItRendersButton() {
        verify(message: makeMessage())
    }
    
    func testThatButtonStyleIsUpdatedAfterStateChange() {
        // given
        let message = makeMessage() { config in
            // when
            let item = self.createItem(title: "J.S. Bach", state:.unselected)
            (config.compositeMessageData as? MockCompositeMessageData)?.items[1] = item
        }
                
        // then
        verify(message: message, allWidths: false)
    }

    // MARK: - Helpers
    
    private func createItem(title: String, state: ButtonMessageState) -> CompositeMessageItem {
        let mockButtonMessageData: MockButtonMessageData = MockButtonMessageData()
        mockButtonMessageData.state = state
        mockButtonMessageData.title = title
        let buttonItem: CompositeMessageItem = .button(mockButtonMessageData)
        
        return buttonItem
    }

    private func makeMessage(_ config: CellConfiguration? = nil) -> MockMessage {
        let mockCompositeMessage: MockMessage = MockMessageFactory.compositeMessage

        let mockCompositeMessageData = MockCompositeMessageData()
        let message = MockMessageFactory.textMessage(withText: "Who is/are your most favourite musician(s)  ?")!
        let textItem: CompositeMessageItem = .text(message.backingTextMessageData)
        
        let items: [CompositeMessageItem] = [createItem(title: "Johann Sebastian Bach", state:.selected),
                                             createItem(title: "Johannes Chrysostomus Wolfgangus Theophilus Mozart", state:.unselected),
                                             createItem(title: "Ludwig van Beethoven", state:.confirmed),
                                             createItem(title: "Giacomo Antonio Domenico Michele Secondo Maria Puccini & Giuseppe Fortunino Francesco Verdi", state:.unselected)]
        
        
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

    var isExpired: Bool { return false }
}
