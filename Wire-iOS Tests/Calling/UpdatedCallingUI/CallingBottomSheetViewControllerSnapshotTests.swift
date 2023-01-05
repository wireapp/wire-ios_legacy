//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import SnapshotTesting
@testable import Wire

final class CallingBottomSheetViewControllerSnapshotTests: ZMSnapshotTestCase {

    var mockVoiceChannel: MockVoiceChannel!
    var conversation: ZMConversation!
    var sut: CallingBottomSheetViewController!

    override func setUp() {
        super.setUp()

        let userClient = MockUserClient()
        userClient.remoteIdentifier = UUID().transportString()

        let mockSelfUser = MockUser.mockUsers()[0]
        mockSelfUser.name = "test name"
        MockUser.setMockSelf(mockSelfUser)
        MockUser.mockSelf()?.remoteIdentifier = UUID()
        MockUser.mockSelf()?.clients = [userClient]
        MockUser.mockSelf()?.isSelfUser = true

        let mockOtherUser = MockUserType.createUser(name: "Guest", inTeam: nil)
        conversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        mockVoiceChannel = MockVoiceChannel(conversation: conversation)
        mockVoiceChannel.mockVideoState = .started
        mockVoiceChannel.mockIsVideoCall = false
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockParticipants = participants(amount: 2)

        sut = createCallingBottomSheetViewController(selfUser: MockUser.mockSelf())
        recordMode = true
    }

    override func tearDown() {
        sut = nil
        conversation = nil
        mockVoiceChannel = nil
        super.tearDown()
    }

    private func createCallingBottomSheetViewController(selfUser: UserType) -> CallingBottomSheetViewController {
        let callingBottomSheetController = CallingBottomSheetViewController(voiceChannel: mockVoiceChannel, selfUser: selfUser)

        return callingBottomSheetController
    }

    private func participants(amount: Int) -> [CallParticipant] {
        var participants = [CallParticipant]()

        for _ in 0..<amount {
            participants.append(
                CallParticipant(user: MockUserType(), userId: AVSIdentifier.stub, clientId: UUID().transportString(), state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
            )
        }

        return participants
    }


    func testHideBottomSheet() {
        // when
        sut.hideBottomSheet()
        sut.callParticipantsDidChange(conversation: conversation, participants: mockVoiceChannel.participants)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testShowBottomSheet() {
        // when
        sut.showBottomSheet()
        sut.callParticipantsDidChange(conversation: conversation, participants: mockVoiceChannel.participants)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }
}
