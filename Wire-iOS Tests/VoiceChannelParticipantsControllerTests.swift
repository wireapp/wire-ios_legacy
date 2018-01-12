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
    
    var sut: VoiceChannelParticipantsController!
    var originalVoiceChannelClass : VoiceChannel.Type!
    var conversation:MockConversation!

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
        super.tearDown()
    }

    func testExample(){
        // GIVEN
        let mockCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())

        let callingConversation = (conversation as Any) as! ZMConversation

        (callingConversation.voiceChannel as? MockVoiceChannel)?.participants = NSOrderedSet(array: [MockUser.mockUsers().last!])

        let participants = (callingConversation.voiceChannel as? MockVoiceChannel)?.participants

        let count = participants?.count

        XCTAssertEqual(1, count)

        sut = VoiceChannelParticipantsController(conversation: (conversation as Any) as! ZMConversation, collectionView: mockCollectionView)

        // WHEN

        // THEN
//        checkerExample()
    }
}
