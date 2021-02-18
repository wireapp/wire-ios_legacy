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
import WireLinkPreview
@testable import Wire


final class MockShareViewControllerConversation: SwiftMockConversation {}


extension MockShareViewControllerConversation: ShareDestination {
	var showsGuestIcon: Bool {
		return false
	}
}

extension MockShareViewControllerConversation: StableRandomParticipantsProvider {
	var stableRandomParticipants: [UserType] {
		return sortedOtherParticipants
	}
}


final class ShareViewControllerTests: XCTestCase {
    fileprivate var groupConversation: MockShareViewControllerConversation!
    fileprivate var oneToOneConversation: MockShareViewControllerConversation!
    fileprivate var sut: ShareViewController<MockShareViewControllerConversation, MockShareableMessage>!

    override func setUp() {
        super.setUp()

        let mockUser = MockUserType.createDefaultOtherUser()

        groupConversation = MockShareViewControllerConversation()
        groupConversation.sortedOtherParticipants = [mockUser, MockUserType.createUser(name: "John Appleseed")]
        groupConversation.displayName = "Bruno, John Appleseed"

        oneToOneConversation = MockShareViewControllerConversation()
        oneToOneConversation.conversationType = .oneOnOne
        oneToOneConversation.sortedOtherParticipants = [mockUser]
        oneToOneConversation.displayName = "Bruno"
    }

    override func tearDown() {
        groupConversation = nil
        oneToOneConversation = nil
        sut = nil
        disableDarkColorScheme()

        super.tearDown()
    }

    private func activateDarkColorScheme() {
        ColorScheme.default.variant = .dark
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }

    private func disableDarkColorScheme() {
        ColorScheme.default.variant = .light
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }

    func testForAllowMultipleSelectionDisabled() {
        // GIVEN & WHEN
        let message: MockShareableMessage = MockMessageFactory.textMessage(withText: "This is a text message.")
        createSut(message: message,
                  allowsMultipleSelection: false)

        // THEN
        verify(matching: sut)
    }

    func testThatItRendersCorrectlyShareViewController_OneLineTextMessage() {
        let message: MockShareableMessage = MockMessageFactory.textMessage(withText: "This is a text message.")
        makeTestForShareViewController(message: message)
    }

    func testThatItRendersCorrectlyShareViewController_MultiLineTextMessage() {
        let message: MockShareableMessage = MockMessageFactory.textMessage(withText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce tempor nulla nec justo tincidunt iaculis. Suspendisse et viverra lacus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aliquam pretium suscipit purus, sed eleifend erat ullamcorper non. Sed non enim diam. Fusce pulvinar turpis sit amet pretium finibus. Donec ipsum massa, aliquam eget sollicitudin vel, fringilla eget arcu. Donec faucibus porttitor nisi ut fermentum. Donec sit amet massa sodales, facilisis neque et, condimentum leo. Maecenas quis vulputate libero, id suscipit magna.")
        makeTestForShareViewController(message: message)
    }

    private func verifyLocation(file: StaticString = #file,
                                testName: String = #function,
                                line: UInt = #line) {
        let message: MockShareableMessage = MockMessageFactory.locationMessage()
        message.backingLocationMessageData.name = "Stranger Place"
        makeTestForShareViewController(message: message, file: file, testName: testName, line: line)
    }

    func testThatItRendersCorrectlyShareViewController_LocationMessage() {
        verifyLocation()
    }

    func testThatItRendersCorrectlyShareViewController_FileMessage() {
        let message: MockShareableMessage = MockMessageFactory.fileTransferMessage()
        makeTestForShareViewController(message: message)
    }

    private func verifyImage(file: StaticString = #file,
                             testName: String = #function,
                             line: UInt = #line) {
        let img = image(inTestBundleNamed: "unsplash_matterhorn.jpg")

        let message: MockShareableMessage = MockMessageFactory.imageMessage(with: img)
        createSut(message: message)

        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verifyInAllDeviceSizes(matching: sut, file: file, testName: testName, line: line)
    }

    func testThatItRendersCorrectlyShareViewController_Photos() {
        verifyImage()
    }

    func testThatItRendersCorrectlyShareViewController_Video_DarkMode() {
        activateDarkColorScheme()
        let thumbnail = image(inTestBundleNamed: "unsplash_matterhorn.jpg")

        let message: MockShareableMessage = MockMessageFactory.videoMessage(sender: nil, previewImage: thumbnail)
        createSut(message: message)

        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))
        verifyInAllDeviceSizes(matching: sut)
    }

    private func createSut(message: MockShareableMessage,
                           allowsMultipleSelection: Bool = true) {
        message.conversationLike = groupConversation

        sut = ShareViewController<MockShareViewControllerConversation, MockShareableMessage>(
            shareable: message,
            destinations: [groupConversation, oneToOneConversation],
            showPreview: true, allowsMultipleSelection: allowsMultipleSelection
        )
    }

    /// create a SUT with a group conversation and a one-to-one conversation and verify snapshot
    private func makeTestForShareViewController(message: MockShareableMessage,
                                                inAllColorSchemes: Bool = false,
                                                file: StaticString = #file,
                                                testName: String = #function,
                                                line: UInt = #line) {
        createSut(message: message)

        verifyInAllDeviceSizes(matching: sut, file: file, testName: testName, line: line)

        if inAllColorSchemes {
            activateDarkColorScheme()

            createSut(message: message)

            verifyInAllDeviceSizes(matching: sut, file: file, testName: testName + "dark", line: line)
        }

    }

}

final class MockShareableMessage: MockMessage, Shareable {
    typealias I = MockShareViewControllerConversation

    func share<SwiftMockConversation>(to: [SwiftMockConversation]) {
        // no-op
    }
}
