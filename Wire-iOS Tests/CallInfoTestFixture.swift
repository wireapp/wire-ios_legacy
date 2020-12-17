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

import Foundation
@testable import Wire

private extension CallStateMock {
    static var connecting: CallStateMock { return .outgoing }
}

struct CallInfoTestFixture {

    enum GroupSize: Int {
        case large = 10
        case small = 4
    }

    let otherUser: UserType
    let groupSize: GroupSize

    init(otherUser: UserType, groupSize: GroupSize = .small) {
        self.otherUser = otherUser
        self.groupSize = groupSize
    }

    // MARK: - OneToOne Audio
    
    private var hashBoxOtherUser: HashBoxUser {
        return HashBox(value: otherUser)
    }

    var oneToOneOutgoingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.outgoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneIncomingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }
    
    var oneToOneOutgoingAudioDegraded: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .outgoing(degradedUser: hashBoxOtherUser),
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.outgoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneIncomingAudioDegraded: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .incoming(degradedUser: hashBoxOtherUser),
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneAudioConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.connecting,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneAudioEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneAudioEstablishedCBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true
        )
    }

    var oneToOneAudioEstablishedVBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true
        )
    }

    var oneToOneAudioEstablishedPoorNetwork: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .poor,
            userEnabledCBR: false
        )
    }

    // MARK: - OneToOne Video

    var oneToOneOutgoingVideoRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.outgoing,
            mediaState: .sendingVideo,
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneIncomingVideoRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .sendingVideo,
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneIncomingVideoRingingWithPermissionsDeniedForever: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoDeniedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneIncomingVideoRingingWithUndeterminedVideoPermissions: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoPendingApproval,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneIncomingVideoRingingVideoTurnedOff: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: CallVideoPlaceholderState.statusTextHidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneVideoConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.connecting,
            mediaState: .sendingVideo,
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var oneToOneVideoEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .sendingVideo,
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    // MARK: - Group Audio

    var groupOutgoingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.outgoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupIncomingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: otherUser.name ?? ""),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupAudioConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.connecting,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupAudioEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, videoState: .stopped, microphoneState: .unmuted)),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupAudioEstablishedRemoteTurnedVideoOn: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, videoState: .started, microphoneState: .unmuted)),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupAudioEstablishedVideoUnavailable: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, videoState: .stopped, microphoneState: .unmuted)),
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupAudioEstablishedCBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue)),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.name ?? "",
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true
        )
    }

    // MARK: - Group Video

    var groupOutgoingVideoRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.outgoing,
            mediaState: .sendingVideo,
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupIncomingVideoRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .sendingVideo,
            state: .ringingIncoming(name: otherUser.name ?? ""),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupVideoConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.connecting,
            mediaState: .sendingVideo,
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupVideoEstablishedScreenSharing: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, videoState: .screenSharing)),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .sendingVideo,
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupVideoEstablishedPoorConnection: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, videoState: .started)),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .sendingVideo,
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .poor,
            userEnabledCBR: false
        )
    }

    var groupVideoEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, videoState: .started, microphoneState: .unmuted)),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .sendingVideo,
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false
        )
    }

    var groupVideoEstablishedCBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, videoState: .started)),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true
        )
    }

    var groupVideoEstablishedVBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, videoState: .started)),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true
        )
    }

    var groupVideoIncomingUndeterminedPermissions: CallInfoViewControllerInput {
        let permissions = MockCallPermissions.videoPendingApproval
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: permissions.preferredVideoPlaceholderState,
            permissions: permissions,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: otherUser.name ?? ""),
            isConstantBitRate: true,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true
        )
    }

    var groupVideoIncomingDeniedPermissions: CallInfoViewControllerInput {
        let permissions = MockCallPermissions.videoDeniedForever
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: permissions.preferredVideoPlaceholderState,
            permissions: permissions,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: otherUser.name ?? ""),
            isConstantBitRate: true,
            title: otherUser.name ?? "",
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true
        )
    }

}
