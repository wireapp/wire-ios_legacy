//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class VoiceChannelParticipantsControllerTests: XCTestCase {

    weak var sut: VoiceChannelParticipantsController!

    var originalVoiceChannelClass: VoiceChannel.Type!
    var conversation: MockConversation!

    override func setUp() {
        super.setUp()

        conversation = MockConversation()
        conversation.conversationType = .oneOnOne
        conversation.displayName = "John Doe"
        conversation.connectedUser = MockUser.mockUsers().last!
        originalVoiceChannelClass = WireCallCenterV3Factory.voiceChannelClass
        WireCallCenterV3Factory.voiceChannelClass = MockVoiceChannel.self
    }

    override func tearDown() {
        sut = nil
        WireCallCenterV3Factory.voiceChannelClass = originalVoiceChannelClass
        originalVoiceChannelClass = nil
        conversation = nil
        super.tearDown()
    }

    func testThatVoiceChannelParticipantsControllerAndUICollectionViewAreNotRetained() {
        var mockViewController: UIViewController! = UIViewController()
        weak var weakMockViewController: UIViewController! = nil

        weakMockViewController = mockViewController

        autoreleasepool {
            // GIVEN
            let mockCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
            mockViewController.view.addSubview(mockCollectionView)

            let mackConversation = (conversation as Any) as! ZMConversation

            // insert one mock participant
            (mackConversation.voiceChannel as? MockVoiceChannel)?.participants = NSOrderedSet(array: [MockUser.mockUsers().last!])

            var voiceChannelParticipantsController: VoiceChannelParticipantsController! = VoiceChannelParticipantsController(conversation: (conversation as Any) as! ZMConversation, collectionView: mockCollectionView)
            sut = voiceChannelParticipantsController

            // WHEN
            mockCollectionView.performBatchUpdates(nil)
            voiceChannelParticipantsController = nil
            mockViewController = nil
        }

        // THEN
        XCTAssertNil(sut)
        XCTAssertNil(weakMockViewController)
    }
}

