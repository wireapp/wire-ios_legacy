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
            degradationState: .none,
            accessoryType: .avatar(otherUser),
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
    
    var oneToOneIncomingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    var oneToOneOutgoingAudioDegraded: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .outgoing(degradedUser: otherUser),
            accessoryType: .avatar(otherUser),
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
    
    var oneToOneIncomingAudioDegraded: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .incoming(degradedUser: otherUser),
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    var oneToOneAudioConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    var oneToOneAudioEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    var oneToOneAudioEstablishedCBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    // MARK: - OneToOne Video
    
    var oneToOneOutgoingVideoRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    var oneToOneIncomingVideoRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light
        )
    }
    
    var oneToOneVideoConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    var oneToOneVideoEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    // MARK: - Group Audio
    
    var groupOutgoingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    var groupIncomingAudioRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
            accessoryType: .avatar(otherUser),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: false,
            variant: .light
        )
    }
    
    var groupAudioConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    var groupAudioEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    var groupAudioEstablishedCBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue)),
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
    
    // MARK: - Group Video
    
    var groupOutgoingVideoRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    var groupIncomingVideoRinging: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: true,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .ringingIncoming(name: otherUser.displayName),
            isConstantBitRate: false,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light
        )
    }
    
    var groupVideoConnecting: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
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
    
    var groupVideoEstablished: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue)),
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
    
    var groupVideoEstablishedCBR: CallInfoViewControllerInput {
        return MockCallInfoViewControllerInput(
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsViewTests.participants(count: groupSize.rawValue)),
            canToggleMediaType: true,
            isMuted: false,
            isTerminating: false,
            canAccept: false,
            mediaState: .notSendingVideo(speakerEnabled: false),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.displayName,
            isVideoCall: true,
            variant: .light
        )
    }
    
}

