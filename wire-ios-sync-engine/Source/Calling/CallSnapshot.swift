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

/**
 * The snapshot of the state of a call.
 */

struct CallSnapshot {
    let callParticipants: CallParticipantsSnapshot
    let callState: CallState
    let callStarter: AVSIdentifier
    let isVideo: Bool
    let isGroup: Bool
    let isConstantBitRate: Bool
    let videoState: VideoState
    let networkQuality: NetworkQuality
    let isConferenceCall: Bool
    let degradedUser: ZMUser?
    let activeSpeakers: [AVSActiveSpeakersChange.ActiveSpeaker]
    let videoGridPresentationMode: VideoGridPresentationMode
    var conversationObserverToken: NSObjectProtocol?

    var isDegradedCall: Bool {
        return degradedUser != nil
    }

    /**
     * Updates the snapshot with the new state of the call.
     * - parameter callState: The new state of the call computed from AVS.
     */

    func update(with callState: CallState) -> CallSnapshot {
        return CallSnapshot(callParticipants: callParticipants,
                            callState: callState,
                            callStarter: callStarter,
                            isVideo: isVideo,
                            isGroup: isGroup,
                            isConstantBitRate: isConstantBitRate,
                            videoState: videoState,
                            networkQuality: networkQuality,
                            isConferenceCall: isConferenceCall,
                            degradedUser: degradedUser,
                            activeSpeakers: activeSpeakers,
                            videoGridPresentationMode: videoGridPresentationMode,
                            conversationObserverToken: conversationObserverToken)
    }

    /**
     * Updates the snapshot with the CBR state.
     * - parameter enabled: Whether constant bitrate was enabled.
     */

    func updateConstantBitrate(_ enabled: Bool) -> CallSnapshot {
        return CallSnapshot(callParticipants: callParticipants,
                            callState: callState,
                            callStarter: callStarter,
                            isVideo: isVideo,
                            isGroup: isGroup,
                            isConstantBitRate: enabled,
                            videoState: videoState,
                            networkQuality: networkQuality,
                            isConferenceCall: isConferenceCall,
                            degradedUser: degradedUser,
                            activeSpeakers: activeSpeakers,
                            videoGridPresentationMode: videoGridPresentationMode,
                            conversationObserverToken: conversationObserverToken)
    }

    /**
     * Updates the snapshot with the new video state.
     * - parameter videoState: The new video state.
     */

    func updateVideoState(_ videoState: VideoState) -> CallSnapshot {
        return CallSnapshot(callParticipants: callParticipants,
                            callState: callState,
                            callStarter: callStarter,
                            isVideo: isVideo,
                            isGroup: isGroup,
                            isConstantBitRate: isConstantBitRate,
                            videoState: videoState,
                            networkQuality: networkQuality,
                            isConferenceCall: isConferenceCall,
                            degradedUser: degradedUser,
                            activeSpeakers: activeSpeakers,
                            videoGridPresentationMode: videoGridPresentationMode,
                            conversationObserverToken: conversationObserverToken)
    }

    /**
     * Updates the snapshot with the new network condition.
     * - parameter networkCondition: The new network condition.
     */

    func updateNetworkQuality(_ networkQuality: NetworkQuality) -> CallSnapshot {
        return CallSnapshot(callParticipants: callParticipants,
                            callState: callState,
                            callStarter: callStarter,
                            isVideo: isVideo,
                            isGroup: isGroup,
                            isConstantBitRate: isConstantBitRate,
                            videoState: videoState,
                            networkQuality: networkQuality,
                            isConferenceCall: isConferenceCall,
                            degradedUser: degradedUser,
                            activeSpeakers: activeSpeakers,
                            videoGridPresentationMode: videoGridPresentationMode,
                            conversationObserverToken: conversationObserverToken)
    }

    /**
     * Updates the snapshot with the new degraded user.
     *
     * A user degrades the call if they were previously trusted by the self
     * client and then joined the call with an unverified device.
     * 
     * - parameter degradedUser: The user who degraded the call.
     */

    func updateDegradedUser(_ degradedUser: ZMUser) -> CallSnapshot {
        return CallSnapshot(callParticipants: callParticipants,
                            callState: callState,
                            callStarter: callStarter,
                            isVideo: isVideo,
                            isGroup: isGroup,
                            isConstantBitRate: isConstantBitRate,
                            videoState: videoState,
                            networkQuality: networkQuality,
                            isConferenceCall: isConferenceCall,
                            degradedUser: degradedUser,
                            activeSpeakers: activeSpeakers,
                            videoGridPresentationMode: videoGridPresentationMode,
                            conversationObserverToken: conversationObserverToken)
    }

    /**
     * Updates the snapshot with the new audio levels of the call.
     * - parameter activeSpeakers: The new active speakers of the call computed from AVS.
     */

    func updateActiveSpeakers(_ activeSpeakers: [AVSActiveSpeakersChange.ActiveSpeaker]) -> CallSnapshot {
        return CallSnapshot(callParticipants: callParticipants,
                            callState: callState,
                            callStarter: callStarter,
                            isVideo: isVideo,
                            isGroup: isGroup,
                            isConstantBitRate: isConstantBitRate,
                            videoState: videoState,
                            networkQuality: networkQuality,
                            isConferenceCall: isConferenceCall,
                            degradedUser: degradedUser,
                            activeSpeakers: activeSpeakers,
                            videoGridPresentationMode: videoGridPresentationMode,
                            conversationObserverToken: conversationObserverToken)
    }

    /**
     * Updates the snapshot with the new presentation mode of the video grid.
     * - parameter presentationMode: The new mode of presentation in video grid
     */

    func updateVideoGridPresentationMode(_ presentationMode: VideoGridPresentationMode) -> CallSnapshot {
        return CallSnapshot(callParticipants: callParticipants,
                            callState: callState,
                            callStarter: callStarter,
                            isVideo: isVideo,
                            isGroup: isGroup,
                            isConstantBitRate: isConstantBitRate,
                            videoState: videoState,
                            networkQuality: networkQuality,
                            isConferenceCall: isConferenceCall,
                            degradedUser: degradedUser,
                            activeSpeakers: activeSpeakers,
                            videoGridPresentationMode: presentationMode,
                            conversationObserverToken: conversationObserverToken)
    }
}
