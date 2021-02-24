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

extension SelfUser {

    /// setup self user as a team member if providing teamID with the name Tarja Turunen
    /// - Parameter teamID: when providing a team ID, self user is a team member
    static func setupMockSelfUser(inTeam teamID: UUID? = nil) {
        provider = SelfProvider(selfUser: MockUserType.createSelfUser(name: "Tarja Turunen", inTeam: teamID))
    }
}

final class ConversationImagesViewControllerTests: CoreDataSnapshotTestCase {

    var sut: ConversationImagesViewController! = nil
    var navigatorController: UINavigationController! = nil

    override var needsCaches: Bool {
        return true
    }

    override func setUp() {
        super.setUp()
        SelfUser.setupMockSelfUser()

        snapshotBackgroundColor = UIColor.white

        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let initialMessage = try! otherUserConversation.appendImage(from: image.imageData!)
        let imagesCategoryMatch = CategoryMatch(including: .image, excluding: .none)
        let collection = MockCollection(messages: [ imagesCategoryMatch: [initialMessage] ])
        let delegate = AssetCollectionMulticastDelegate()

        let assetWrapper = AssetCollectionWrapper(conversation: otherUserConversation, assetCollection: collection, assetCollectionDelegate: delegate, matchingCategories: [imagesCategoryMatch])
        sut = ConversationImagesViewController(collection: assetWrapper, initialMessage: initialMessage, inverse: true)

        navigatorController = sut.wrapInNavigationController(navigationBarClass: UINavigationBar.self)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }


    func testForWrappedInNavigationController() {
        verify(view: navigatorController.view)
    }

    func testThatItDisplaysCorrectToolbarForImage_Normal() {
        sut.setBoundsSizeAsIPhone4_7Inch()

        verify(view: navigatorController.view)
    }

    func testThatItDisplaysCorrectToolbarForImage_Ephemeral() {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)
        message.isEphemeral = true
        sut.currentMessage = message

        sut.setBoundsSizeAsIPhone4_7Inch()

        ///calls viewWillAppear
        sut.beginAppearanceTransition(true, animated: false)

        verify(view: navigatorController.view)
    }

    // MARK: - Update toolbar buttons for switching between ephemeral/normal messages
    func testThatToolBarIsUpdateAfterScollToAnEphemeralImage() {
        // GIVEN
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)
        message.isEphemeral = false
        sut.currentMessage = message

        // WHEN
        sut.viewDidLoad()

        // THEN
        XCTAssertEqual(sut.buttonsBar.buttons.count, 8)

        // WHEN
        message.isEphemeral = true
        sut.pageViewController(UIPageViewController(), didFinishAnimating: true, previousViewControllers: [], transitionCompleted: true)

        // THEN
        XCTAssertEqual(sut.buttonsBar.buttons.count, 1)

    }
}
