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

final class ShareViewControllerTests: XCTestCase {
    var groupConversation: MockGroupDetailsConversation! ///TODO: move property to DM
    var oneToOneConversation: MockGroupDetailsConversation! ///TODO: move property to DM
    var sut: ShareViewController<MockGroupDetailsConversation, MockShareableMessage>!

    override func setUp() {
        super.setUp()

        let mockUser = MockUserType.createDefaultOtherUser()

        groupConversation = MockGroupDetailsConversation()
        groupConversation.sortedOtherParticipants = [mockUser, MockUserType.createUser(name: "John Appleseed")]
        groupConversation.displayName = "Bruno, John Appleseed"

        oneToOneConversation = MockGroupDetailsConversation() ///TODO: create a simpler type?
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

    func activateDarkColorScheme() {
        ColorScheme.default.variant = .dark
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }

    func disableDarkColorScheme() {
        ColorScheme.default.variant = .light
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }

    func testForAllowMultipleSelectionDisabled() {
        // GIVEN & WHEN
        let message = MockMessageFactory.shareableTextMessage(withText: "This is a text message.")
        createSut(message: message,
                  allowsMultipleSelection: false)

        //THEN
        verify(matching: sut)
    }

    func testThatItRendersCorrectlyShareViewController_OneLineTextMessage() {
        let message = MockMessageFactory.shareableTextMessage(withText: "This is a text message.")
        makeTestForShareViewController(message: message)
    }

/*    func testThatItRendersCorrectlyShareViewController_MultiLineTextMessage() {
//        try! groupConversation.appendText(content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce tempor nulla nec justo tincidunt iaculis. Suspendisse et viverra lacus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aliquam pretium suscipit purus, sed eleifend erat ullamcorper non. Sed non enim diam. Fusce pulvinar turpis sit amet pretium finibus. Donec ipsum massa, aliquam eget sollicitudin vel, fringilla eget arcu. Donec faucibus porttitor nisi ut fermentum. Donec sit amet massa sodales, facilisis neque et, condimentum leo. Maecenas quis vulputate libero, id suscipit magna.")
        makeTestForShareViewController()
    }
    func testThatItRendersCorrectlyShareViewController_LocationMessage() throws {
        let location = LocationData.locationData(withLatitude: 43.94, longitude: 12.46, name: "Stranger Place", zoomLevel: 0)
//        try groupConversation.appendLocation(with: location)
        makeTestForShareViewController()
    }

    func testThatItRendersCorrectlyShareViewController_FileMessage() {
        let file = ZMFileMetadata(fileURL: urlForResource(inTestBundleNamed: "huge.pdf"))
//        try! groupConversation.appendFile(with: file)
        makeTestForShareViewController()
    }

    func testThatItRendersCorrectlyShareViewController_Photos() {
        let img = image(inTestBundleNamed: "unsplash_matterhorn.jpg")
//        try! self.groupConversation.appendImage(from: img.imageData!)

        createSut()

        _ = sut.view // make sure view is loaded

        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verifyInAllDeviceSizes(matching: sut)
    }

    func testThatItRendersCorrectlyShareViewController_DarkMode() {
        activateDarkColorScheme()
//        try! groupConversation.appendText(content: "This is a text message.")
        makeTestForShareViewController()
    }

    func testThatItRendersCorrectlyShareViewController_Image_DarkMode() {
        activateDarkColorScheme()
        let img = urlForResource(inTestBundleNamed: "unsplash_matterhorn.jpg")
//        try! self.groupConversation.appendImage(at: img)

        createSut()

        _ = sut.view // make sure view is loaded

        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))
        verifyInAllDeviceSizes(matching: sut)
    }

    func testThatItRendersCorrectlyShareViewController_Video_DarkMode() {
        activateDarkColorScheme()
        let videoURL = urlForResource(inTestBundleNamed: "video.mp4")
        let thumbnail = image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0)
        let file = ZMFileMetadata(fileURL: videoURL, thumbnail: thumbnail)
//        try! self.groupConversation.appendFile(with: file)

        createSut()

        _ = sut.view // make sure view is loaded

        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))
        verifyInAllDeviceSizes(matching: sut)
    }

    func testThatItRendersCorrectlyShareViewController_File_DarkMode() {
        activateDarkColorScheme()
        let file = ZMFileMetadata(fileURL: urlForResource(inTestBundleNamed: "huge.pdf"))
//        try! groupConversation.appendFile(with: file)
        makeTestForShareViewController()
    }

    func testThatItRendersCorrectlyShareViewController_Location_DarkMode() throws {
        activateDarkColorScheme()
        let location = LocationData.locationData(withLatitude: 43.94, longitude: 12.46, name: "Stranger Place", zoomLevel: 0)
//        try groupConversation.appendLocation(with: location)
        makeTestForShareViewController()
    }*/

    private func createSut(message: MockShareableMessage,
                           allowsMultipleSelection: Bool = true) {
        message.conversationLike = groupConversation

        sut = ShareViewController<MockGroupDetailsConversation, MockShareableMessage>(
            shareable: message,
            destinations: [groupConversation, oneToOneConversation],
            showPreview: true, allowsMultipleSelection: allowsMultipleSelection
        )
    }

    /// create a SUT with a group conversation and a one-to-one conversation and verify snapshot
    private func makeTestForShareViewController(message: MockShareableMessage,
        file: StaticString = #file,
                                                testName: String = #function,
                                        line: UInt = #line) {
        createSut(message: message)

        verifyInAllDeviceSizes(matching: sut, file: file, testName: testName, line: line)
    }

}

final class MockShareableMessage: MockMessage, Shareable {
    typealias I = MockGroupDetailsConversation

    func share<MockGroupDetailsConversation>(to: [MockGroupDetailsConversation]) {
        //no-op
    }
}

extension MockGroupDetailsConversation: ShareDestination {
    var showsGuestIcon: Bool {
        return false
    }
}

extension MockGroupDetailsConversation: StableRandomParticipantsProvider {
    var stableRandomParticipants: [UserType] {
        return sortedOtherParticipants
    }
}
