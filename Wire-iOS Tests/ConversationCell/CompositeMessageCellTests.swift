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

final class CompositeMessageCellTests: XCTestCase {

    typealias CellConfiguration = (MockMessage) -> Void

    var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()

        mockSelfUser = MockUserType.createDefaultSelfUser()

        // make sure the button's color is alarm red, not accent color
        UIColor.setAccentOverride(.strongBlue)
    }

    override func tearDown() {
        mockSelfUser = nil

        super.tearDown()
    }

    func testThatItRendersErrorMessage() {
        // given
        let items: [CompositeMessageItem] = [createItem(title: "Johann Sebastian Bach", state: .selected),
                                             createItem(title: "Stone age", state: .unselected, isExpired: true),
                                             createItem(title: "Ludwig van Beethoven", state: .confirmed),
                                             createItem(title: "Giacomo Antonio Domenico Michele Secondo Maria Puccini & Giuseppe Fortunino Francesco Verdi", state: .unselected)]

        // when & then
        let message = makeMessage(sender: mockSelfUser, items: items)

        verify(message: message,
               allWidths: false,
               snapshotBackgroundColor: UIColor.from(scheme: .contentBackground))
    }

    func testThatItRendersButton() {
        verify(message: makeMessage(sender: mockSelfUser),
               snapshotBackgroundColor: UIColor.from(scheme: .contentBackground))
    }

    func testThatButtonStyleIsUpdatedAfterStateChange() {
        // given
        let message = makeMessage(sender: mockSelfUser) { config in
            // when
            let item = self.createItem(title: "J.S. Bach", state: .unselected)
            (config.compositeMessageData as? MockCompositeMessageData)?.items[1] = item
        }

        // then
        verify(message: message, allWidths: false)
    }

    // MARK: - Helpers

    private func createItem(title: String, state: ButtonMessageState, isExpired: Bool = false) -> CompositeMessageItem {
        let mockButtonMessageData: MockButtonMessageData = MockButtonMessageData()
        mockButtonMessageData.state = state
        mockButtonMessageData.title = title
        mockButtonMessageData.isExpired = isExpired
        let buttonItem: CompositeMessageItem = .button(mockButtonMessageData)

        return buttonItem
    }

    fileprivate lazy var mockTextMessage = MockMessageFactory.textMessage(withText: "# Question:\nWho is/are your most favourite musician(s)  ?")!

    private func makeMessage(sender: UserType? = nil,
                             items: [CompositeMessageItem]) -> MockMessage {
        let mockCompositeMessage: MockMessage = MockMessageFactory.compositeMessage(sender: sender)

        let mockCompositeMessageData = MockCompositeMessageData()
        let textItem: CompositeMessageItem = .text(mockTextMessage.backingTextMessageData)

        mockCompositeMessageData.items = [textItem] + items

        mockCompositeMessage.compositeMessageData = mockCompositeMessageData
        return mockCompositeMessage
    }

    private func makeMessage(sender: UserType? = nil,
                             _ config: CellConfiguration? = nil) -> MockMessage {
        let mockCompositeMessage: MockMessage = MockMessageFactory.compositeMessage(sender: sender)

        let mockCompositeMessageData = MockCompositeMessageData()
        let textItem: CompositeMessageItem = .text(mockTextMessage.backingTextMessageData)

        let items: [CompositeMessageItem] = [createItem(title: "Johann Sebastian Bach", state: .selected),
                                             createItem(title: "Johannes Chrysostomus Wolfgangus Theophilus Mozart", state: .unselected),
                                             createItem(title: "Ludwig van Beethoven", state: .confirmed),
                                             createItem(title: "Giacomo Antonio Domenico Michele Secondo Maria Puccini & Giuseppe Fortunino Francesco Verdi", state: .unselected)]

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
        // no-op
    }

    var isExpired: Bool = false
}
