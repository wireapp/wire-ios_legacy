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

struct MockCallInfoViewControllerInput: CallInfoViewControllerInput {
    var accessoryType: CallInfoViewControllerAccessoryType
    var canToggleMediaType: Bool
    var isMuted: Bool
    var isTerminating: Bool
    var canAccept: Bool
    var mediaState: MediaState
    var state: CallStatusViewState
    var isConstantBitRate: Bool
    var title: String
    var isVideoCall: Bool
    var variant: ColorSchemeVariant
}

struct CallInfoTestFixture {
    
    enum GroupSize: Int {
        case large = 10
        case small = 4
    }
    
    let otherUser: ZMUser
    let groupSize: GroupSize
    
    init(otherUser: ZMUser, groupSize: GroupSize = .small) {
        self.otherUser = otherUser
        self.groupSize = groupSize
    }
    
    // MARK: - Outgoing OneToOne Audio
    
    var oneToOneOutgoingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    var oneToOneOutgoingAudioConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    var oneToOneOutgoingAudioEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    // MARK: - Incoming OneToOne Audio
    
    var oneToOneIncomingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    var oneToOneIncomingAudioConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    var oneToOneIncomingAudioEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    var oneToOneIncomingAudioEstablishedCBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    // MARK: - Outgoing OneToOne Video
    
    var oneToOneOutgoingVideoRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .none,
            canToggleMediaType: false,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light
        )
    }
    
    var oneToOneOutgoingVideoConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .none,
            canToggleMediaType: false,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light
        )
    }
    
    var oneToOneOutgoingVideoEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .none,
            canToggleMediaType: false,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light
        )
    }
    
    // MARK: - Incoming OneToOne Video
    
    var oneToOneIncomingVideoRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light
        )
    }
    
    var oneToOneIncomingVideoConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light
        )
    }
    
    var oneToOneIncomingVideoEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light
        )
    }
    
    // MARK: - Outgoing Group Audio
    
    var groupOutgoingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .none,
            canToggleMediaType: false,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    var groupOutgoingAudioConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    var groupOutgoingAudioEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue)),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
}

final class CallInfoViewControllerTests: CoreDataSnapshotTestCase {

    var sut: CallInfoViewController!
    var input: CallInfoViewControllerInput!
    
    override func setUp() {
        super.setUp()
        input = MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: "Delaney Winston",
            isVideoCall: false,
            variant: .light
        )
        
        snapshotBackgroundColor = input.overlayBackgroundColor
        sut = CallInfoViewController(configuration: input)
    }
    
    override func tearDown() {
        input = nil
        sut = nil
        super.tearDown()
    }
    
    func testCallInfoViewController_Audio_NoCBR() {
        // Given
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        snapshotBackgroundColor = input.overlayBackgroundColor
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    @available(iOS 11.0, *)
    func testCallInfoViewController_Audio_NoCBR_iPhoneX() {
        // Given
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        snapshotBackgroundColor = input.overlayBackgroundColor
        
        // Then
        verifySafeAreas(viewController: sut)
    }
    
    func testCallInfoViewController_Audio_CBR() {
        // Given
        sut.configuration = MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: true,
            title: "Delaney Winston",
            isVideoCall: false,
            variant: .light
        )
        snapshotBackgroundColor = input.overlayBackgroundColor
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testCallInfoViewController_Audio_NoCBR_SomeParticipants() {
        // Given
        let participants = CallParticipantsViewTests.participants(count: 2)
        
        sut.configuration = MockCallInfoViewControllerInput(
            accessoryType: .participantsList(participants),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: "Delaney Winston",
            isVideoCall: false,
            variant: .light
        )
        
        snapshotBackgroundColor = input.overlayBackgroundColor
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testCallInfoViewController_Audio_NoCBR_ManyParticipants() {
        // Given
        let participants = CallParticipantsViewTests.participants(count: 4)
        
        sut.configuration = MockCallInfoViewControllerInput(
            accessoryType: .participantsList(participants),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: "Delaney Winston",
            isVideoCall: false,
            variant: .light
        )
        
        snapshotBackgroundColor = input.overlayBackgroundColor
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testCallInfoViewController_Audio_NoCBR_ALotOfParticipants() {
        // Given
        let participants = CallParticipantsViewTests.participants(count: 10)
        
        sut.configuration = MockCallInfoViewControllerInput(
            accessoryType: .participantsList(participants),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: "Delaney Winston",
            isVideoCall: false,
            variant: .light
        )
        
        snapshotBackgroundColor = input.overlayBackgroundColor
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }

    func testCallInfoViewController_Video_NoCBR() {
        // Given
        sut.configuration = MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: "Delaney Winston",
            isVideoCall: true,
            variant: .light
        )
        
        snapshotBackgroundColor = sut.configuration.overlayBackgroundColor
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }

    func testCallInfoViewController_Video_CBR() {
        // Given
        sut.configuration = MockCallInfoViewControllerInput(
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: true,
            title: "Delaney Winston",
            isVideoCall: true,
            variant: .light
        )
        
        snapshotBackgroundColor = sut.configuration.overlayBackgroundColor
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testCallInfoViewController_Video_NoCBR_SomeParticipants() {
        // Given
        let participants = CallParticipantsViewTests.participants(count: 2)
        
        sut.configuration = MockCallInfoViewControllerInput(
            accessoryType: .participantsList(participants),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: "Delaney Winston",
            isVideoCall: true,
            variant: .light
        )
        
        snapshotBackgroundColor = sut.configuration.overlayBackgroundColor
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testCallInfoViewController_Video_NoCBR_ManyParticipants() {
        // Given
        let participants = CallParticipantsViewTests.participants(count: 4)
        
        sut.configuration = MockCallInfoViewControllerInput(
            accessoryType: .participantsList(participants),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: "Delaney Winston",
            isVideoCall: true,
            variant: .light
        )
        
        snapshotBackgroundColor = sut.configuration.overlayBackgroundColor
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testCallInfoViewController_Video_NoCBR_ALotOfParticipants() {
        // Given
        let participants = CallParticipantsViewTests.participants(count: 10)
        
        sut.configuration = MockCallInfoViewControllerInput(
            accessoryType: .participantsList(participants),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .connecting,
            isConstantBitRate: false,
            title: "Delaney Winston",
            isVideoCall: true,
            variant: .light
        )
        
        snapshotBackgroundColor = sut.configuration.overlayBackgroundColor
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testCallInfoViewController_Audio_NoCBR_NoAccessoryView_SpeakerEnabled() {
        // Given
        sut.configuration = MockCallInfoViewControllerInput(
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: true),
            state: .established(duration: 102),
            isConstantBitRate: false,
            title: "Delaney Winston",
            isVideoCall: false,
            variant: .light
        )
        
        snapshotBackgroundColor = input.overlayBackgroundColor
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        
        // Then
        verifyInAllIPhoneSizes(view: sut.view)
    }

}
