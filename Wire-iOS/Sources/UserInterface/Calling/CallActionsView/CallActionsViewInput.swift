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

struct CallActionsViewInput: CallActionsViewInputType {
    
    var isMuted: Bool
    var isVideoCall: Bool
    var canToggleMediaType: Bool
    var isTerminating: Bool
    var canAccept: Bool
    var mediaState: MediaState
    
    init(mediaManager: AVSMediaManager = .sharedInstance(), properties: CallProperties) {
        isMuted = mediaManager.isMicrophoneMuted
        isVideoCall = properties.isVideoCall
        canToggleMediaType = properties.state.canToggleMediaType
        isTerminating = properties.state.isTerminating
        canAccept = properties.state.canAccept
        mediaState = CallActionsViewInput.mediaState(for: mediaManager, properties: properties)
    }
    
    private static func mediaState(for mediaManager: AVSMediaManager, properties: CallProperties) -> MediaState {
        guard !properties.isVideoCall else { return .sendingVideo } // TODO: Adjust check whether we're sending video
        return .notSendingVideo(speakerEnabled: mediaManager.isSpeakerEnabled)
    }
    
}
