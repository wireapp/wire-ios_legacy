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
    
    // MARK: - OneToOne Audio
    
    var oneToOneOutgoingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(otherUser),
            canToggleMediaType: false,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
        )
    }
    
    var oneToOneIncomingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(otherUser),
            canToggleMediaType: false,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
        )
    }
    
    var oneToOneOutgoingAudioDegraded: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .outgoing(degradedUser: otherUser),
            accessoryType: .avatar(otherUser),
            canToggleMediaType: false,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
        )
    }
    
    var oneToOneIncomingAudioDegraded: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .incoming(degradedUser: otherUser),
            accessoryType: .avatar(otherUser),
            canToggleMediaType: false,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
        )
    }
    
    var oneToOneAudioConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
        )
    }
    
    var oneToOneAudioEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
        )
    }
        
    var oneToOneAudioEstablishedCBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
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
            isTerminating: false,
            canAccept: false,
            mediaState: .sendingVideo,
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: true,
            mediaState: .sendingVideo,
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: false,
            mediaState: .sendingVideo,
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: false,
            mediaState: .sendingVideo,
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
        )
    }
    
    var groupIncomingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(otherUser),
            canToggleMediaType: false,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
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
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
        )
    }
    
    var groupAudioEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue)),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
        )
    }
    
    var groupAudioEstablishedRemoteTurnedVideoOn: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, sendsVideo: true)),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
        )
    }
    
    var groupAudioEstablishedVideoUnavailable: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue)),
            canToggleMediaType: false,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
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
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light,
            disableIdleTimer: false,
            cameraType: .front
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
            isTerminating: false,
            canAccept: false,
            mediaState: .sendingVideo,
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: true,
            mediaState: .sendingVideo,
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: false,
            mediaState: .sendingVideo,
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
        )
    }
    
    var groupVideoEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, sendsVideo: true)),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .sendingVideo,
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
        )
    }
    
    var groupVideoEstablishedCBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue, sendsVideo: true)),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: true,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
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
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: true,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light,
            disableIdleTimer: true,
            cameraType: .front
        )
    }
    
}

