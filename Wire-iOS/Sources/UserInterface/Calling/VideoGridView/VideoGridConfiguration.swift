//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSyncEngine

protocol VideoGridConfiguration {

    var floatingVideoStream: VideoStream? { get }
    var videoStreams: [VideoStream] { get }
    var videoState: VideoState { get }
    var networkQuality: NetworkQuality { get }
    var shouldShowActiveSpeakerFrame: Bool { get }
    var presentationMode: VideoGridPresentationMode { get }
    var callHasTwoParticipants: Bool { get }

}

extension VideoGridConfiguration {

    var allStreamIds: Set<AVSClient> {
        let streamIds = (videoStreams + [floatingVideoStream]).compactMap { $0?.stream.streamId }
        return Set(streamIds)
    }

    // Workaround to make the protocol equatable, it might be possible to conform VideoGridConfiguration
    // to Equatable with Swift 4.1 and conditional conformances. Right now we would have to make
    // the `VideoGridViewController` generic to work around the `Self` requirement of
    // `Equatable` which we want to avoid.
    func isEqual(toConfiguration other: VideoGridConfiguration) -> Bool {
        return floatingVideoStream == other.floatingVideoStream &&
            videoStreams == other.videoStreams &&
            networkQuality == other.networkQuality &&
            shouldShowActiveSpeakerFrame == other.shouldShowActiveSpeakerFrame &&
            presentationMode == other.presentationMode &&
            videoState == other.videoState &&
            callHasTwoParticipants == other.callHasTwoParticipants
    }

}
