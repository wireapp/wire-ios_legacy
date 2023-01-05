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
import WireCommonComponents
@testable import Wire

final class CallingBottomSheetViewControllerSnapshotTests: ZMSnapshotTestCase {

    var mockVoiceChannel: MockVoiceChannel!
    var conversation: ZMConversation!
    var sut: CallingBottomSheetViewController!
    var mockSelfUser = MockUser.mockUsers()[0]
    var mockOtherUser: MockUserType!

    override func setUp() {
        super.setUp()

        let userClient = MockUserClient()
        userClient.remoteIdentifier = UUID().transportString()

        mockSelfUser.name = "test name"
        MockUser.setMockSelf(mockSelfUser)
        MockUser.mockSelf()?.remoteIdentifier = UUID()
        MockUser.mockSelf()?.clients = [userClient]
        MockUser.mockSelf()?.isSelfUser = true

        mockOtherUser = MockUserType.createUser(name: "Participant 2", inTeam: nil)
        conversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        mockVoiceChannel = MockVoiceChannel(conversation: conversation)
        mockVoiceChannel.mockVideoState = .stopped
        mockVoiceChannel.mockIsVideoCall = false
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockParticipants = participants()

        sut = createCallingBottomSheetViewController(selfUser: MockUser.mockSelf())

        UserDefaults.applicationGroup.set(false, forKey: DeveloperFlag.deprecatedCallingUI.rawValue)
    }

    override func tearDown() {
        sut = nil
        conversation = nil
        mockVoiceChannel = nil
        super.tearDown()
    }

    private func createCallingBottomSheetViewController(selfUser: UserType) -> CallingBottomSheetViewController {
        let callingBottomSheetController = CallingBottomSheetViewController(voiceChannel: mockVoiceChannel, selfUser: selfUser)
        callingBottomSheetController.visibleVoiceChannelViewController.callCenterDidChangeActiveSpeakers()
        callingBottomSheetController.callParticipantsDidChange(conversation: conversation, participants: mockVoiceChannel.participants)

        return callingBottomSheetController
    }

    private func participants() -> [CallParticipant] {
        var participants = [CallParticipant]()

        participants.append(
            CallParticipant(user: mockSelfUser, userId: AVSIdentifier.stub, clientId: UUID().transportString(), state: .connected(videoState: .stopped, microphoneState: .unmuted), activeSpeakerState: .active(audioLevelNow: 1))
        )
        participants.append(
            CallParticipant(user: mockOtherUser, userId: AVSIdentifier.stub, clientId: UUID().transportString(), state: .connected(videoState: .stopped, microphoneState: .unmuted), activeSpeakerState: .inactive)
        )

        return participants
    }


    func testCallHideBottomSheet() {
        // when
        sut.hideBottomSheet()

        // then
        verify(matching: sut)
    }

    func testCallShowBottomSheet() {
        // when
        sut.showBottomSheet()

        // then
        verify(matching: sut)
    }

    func testCallShowBottomSheet_dark() {
        let createSut: () -> UIViewController = {
            self.sut.showBottomSheet()
            return self.sut
        }
        // then
        verifyInDarkScheme(createSut: createSut, name: "DarkTheme")
    }

    func testCallHideBottomSheet_dark() {
        let createSut: () -> UIViewController = {
            // when
            self.sut.hideBottomSheet()
            return self.sut
        }
        // then
        verifyInDarkScheme(createSut: createSut, name: "DarkTheme")
    }

    func testLandscapeCallHideBottomSheet() {
        // when
        sut.hideBottomSheet()
        // then
        verifyInLandscape(matching: sut)
    }

    func testLandscapeCallShowBottomSheet() {
        // when
        sut.hideBottomSheet()
        // then
        verifyInLandscape(matching: sut)
    }

}
