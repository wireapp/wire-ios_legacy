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

final class ShareViewControllerTests: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!

    var groupConversation: ZMConversation!
    var sut: ShareViewController<ZMConversation, ZMMessage>!

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()

        groupConversation = createGroupConversation()
    }

    override func tearDown() {
        groupConversation = nil
        sut = nil
        disableDarkColorScheme()

        coreDataFixture = nil

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
        try! groupConversation.appendText(content: "This is a text message.")

        createSut(allowsMultipleSelection: false)

        //THEN
        verify(matching: sut)
    }

    func testThatItRendersCorrectlyShareViewController_OneLineTextMessage() {
        try! groupConversation.appendText(content: "This is a text message.")
        makeTestForShareViewController()
    }

    func testThatItRendersCorrectlyShareViewController_MultiLineTextMessage() {
        try! groupConversation.appendText(content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce tempor nulla nec justo tincidunt iaculis. Suspendisse et viverra lacus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aliquam pretium suscipit purus, sed eleifend erat ullamcorper non. Sed non enim diam. Fusce pulvinar turpis sit amet pretium finibus. Donec ipsum massa, aliquam eget sollicitudin vel, fringilla eget arcu. Donec faucibus porttitor nisi ut fermentum. Donec sit amet massa sodales, facilisis neque et, condimentum leo. Maecenas quis vulputate libero, id suscipit magna.")
        makeTestForShareViewController()
    }

    func testThatItRendersCorrectlyShareViewController_LocationMessage() throws {
        let location = LocationData.locationData(withLatitude: 43.94, longitude: 12.46, name: "Stranger Place", zoomLevel: 0)
        try groupConversation.appendLocation(with: location)
        makeTestForShareViewController()
    }

    func testThatItRendersCorrectlyShareViewController_FileMessage() {
        let file = ZMFileMetadata(fileURL: urlForResource(inTestBundleNamed: "huge.pdf"))
        try! groupConversation.appendFile(with: file)
        makeTestForShareViewController()
    }

    func testThatItRendersCorrectlyShareViewController_Photos() {
        let img = image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        try! self.groupConversation.appendImage(from: img.imageData!)

        createSut()

        _ = sut.view // make sure view is loaded

        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verifyInAllDeviceSizes(matching: sut)
    }

    func testThatItRendersCorrectlyShareViewController_DarkMode() {
        activateDarkColorScheme()
        try! groupConversation.appendText(content: "This is a text message.")
        makeTestForShareViewController()
    }

    func testThatItRendersCorrectlyShareViewController_Image_DarkMode() {
        activateDarkColorScheme()
        let img = urlForResource(inTestBundleNamed: "unsplash_matterhorn.jpg")
        try! self.groupConversation.appendImage(at: img)

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
        try! self.groupConversation.appendFile(with: file)

        createSut()

        _ = sut.view // make sure view is loaded

        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))
        verifyInAllDeviceSizes(matching: sut)
    }

    func testThatItRendersCorrectlyShareViewController_File_DarkMode() {
        activateDarkColorScheme()
        let file = ZMFileMetadata(fileURL: urlForResource(inTestBundleNamed: "huge.pdf"))
        try! groupConversation.appendFile(with: file)
        makeTestForShareViewController()
    }

    func testThatItRendersCorrectlyShareViewController_Location_DarkMode() throws {
        activateDarkColorScheme()
        let location = LocationData.locationData(withLatitude: 43.94, longitude: 12.46, name: "Stranger Place", zoomLevel: 0)
        try groupConversation.appendLocation(with: location)
        makeTestForShareViewController()
    }

    private func createSut(allowsMultipleSelection: Bool = true) {
        groupConversation.add(participants: [createUser(name: "John Appleseed")])
        let oneToOneConversation = otherUserConversation!

        guard let message = groupConversation.lastMessage else {
            XCTFail("Cannot add test message to the group conversation")
            return
        }

        sut = ShareViewController<ZMConversation, ZMMessage>(
            shareable: message,
            destinations: [groupConversation, oneToOneConversation],
            showPreview: true, allowsMultipleSelection: allowsMultipleSelection
        )
    }

    /// create a SUT with a group conversation and a one-to-one conversation and verify snapshot
    private func makeTestForShareViewController(file: StaticString = #file,
                                                testName: String = #function,
                                        line: UInt = #line) {
        createSut()

        verifyInAllDeviceSizes(matching: sut, file: file, testName: testName, line: line)
    }

}
