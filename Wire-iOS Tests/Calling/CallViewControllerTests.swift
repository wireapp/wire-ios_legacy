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

extension XCTestCase {
    public func verifyDeallocation<T: AnyObject>(of instanceGenerator: () -> (T)) {
        weak var weakInstance: T?
        var instance: T?

        autoreleasepool {
            instance = instanceGenerator()
            // then
            weakInstance = instance
            XCTAssertNotNil(weakInstance)
            // when
            instance = nil
        }

        XCTAssertNil(instance)
        XCTAssertNil(weakInstance)
    }
}

final class CallViewControllerTests: XCTestCase {

    var mockVoiceChannel: MockVoiceChannel!
    var conversation: ZMConversation!
    var sut: CallViewController!

    override func setUp() {
        super.setUp()

        conversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        mockVoiceChannel = MockVoiceChannel(conversation: conversation)
        mockVoiceChannel.mockVideoState = VideoState.started
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockCallState = CallState.established

        let userClient = MockUserClient()
        userClient.remoteIdentifier = UUID().transportString()

        let mockSelfUser = MockUser.mockUsers()[0]
        MockUser.setMockSelf(mockSelfUser)
        MockUser.mockSelf()?.remoteIdentifier = UUID()
        MockUser.mockSelf()?.clients = [userClient]
        MockUser.mockSelf()?.isSelfUser = true

        sut = createCallViewController(selfUser: MockUser.mockSelf(), mediaManager: ZMMockAVSMediaManager())
    }

    override func tearDown() {
        sut = nil
        conversation = nil
        mockVoiceChannel = nil
        super.tearDown()
    }

    private func createCallViewController(selfUser: UserType,
                                          mediaManager: ZMMockAVSMediaManager) -> CallViewController {

        let proximityManager = ProximityMonitorManager()
        let callController = CallViewController(voiceChannel: mockVoiceChannel, selfUser: selfUser, proximityMonitorManager: proximityManager, mediaManager: mediaManager)

        return callController
    }

    private func participants(amount: Int) -> [CallParticipant] {
        var participants = [CallParticipant]()

        for _ in 0..<amount {
            participants.append(
                CallParticipant(user: MockUserType(), userId: UUID(), clientId: UUID().transportString(), state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
            )
        }

        return participants
    }

    func testThatVideoGridPresentationMode_IsUpdatedToAllVideoStreams_WhenUnderThreeParticipants() {
        // Given
        mockVoiceChannel.videoGridPresentationMode = .activeSpeakers

        // When
        sut.callParticipantsDidChange(conversation: conversation, participants: participants(amount: 2))

        // Then
        XCTAssertEqual(mockVoiceChannel.videoGridPresentationMode, VideoGridPresentationMode.allVideoStreams)
    }

    func testThatVideoGridPresentationMode_IsNotUpdated_WhenOverTwoParticipants() {
        // Given
        mockVoiceChannel.videoGridPresentationMode = .activeSpeakers

        // When
        sut.callParticipantsDidChange(conversation: conversation, participants: participants(amount: 3))

        // Then
        XCTAssertEqual(mockVoiceChannel.videoGridPresentationMode, VideoGridPresentationMode.activeSpeakers)
    }

    func testThatCallGridViewControllerDelegate_ForwardsVideoStreamsRequestToVoiceChannel() {
        // Given
        let configuration = MockCallGridViewControllerInput()
        let viewController = CallGridViewController(configuration: configuration)
        let clients = [
            AVSClient(userId: UUID(), clientId: UUID().transportString()),
            AVSClient(userId: UUID(), clientId: UUID().transportString())
        ]

        // When
        sut.callGridViewController(viewController, perform: .requestVideoStreamsForClients(clients))

        // Then
        XCTAssertEqual(mockVoiceChannel.requestedVideoStreams, clients)
    }

    func testThatItDeallocates() {
        // when & then
        verifyDeallocation { () -> CallViewController in
            // given
            let callController = createCallViewController(selfUser: MockUserType.createSelfUser(name: "Alice"), mediaManager: ZMMockAVSMediaManager())
            // Simulate user click
            callController.startOverlayTimer()
            return callController
        }
    }
}
