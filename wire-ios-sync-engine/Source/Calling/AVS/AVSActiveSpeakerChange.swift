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
import avs

struct AVSActiveSpeakersChange: Codable {
    let activeSpeakers: [ActiveSpeaker]

    struct ActiveSpeaker: Codable, Equatable {
        let userId: String
        let clientId: String

        /// Audio level smoothed over time
        let audioLevel: Int

        /// Instantaneous audio level
        let audioLevelNow: Int

        enum CodingKeys: String, CodingKey {
            case userId = "userid"
            case clientId = "clientid"
            case audioLevel = "audio_level"
            case audioLevelNow = "audio_level_now"
        }
    }

    enum CodingKeys: String, CodingKey {
        case activeSpeakers = "audio_levels"
    }
}

extension AVSActiveSpeakersChange.ActiveSpeaker {
    var client: AVSClient {
        AVSClient(activeSpeaker: self)
    }
}

private extension AVSClient {
    init(activeSpeaker: AVSActiveSpeakersChange.ActiveSpeaker) {
        userId = activeSpeaker.userId
        clientId = activeSpeaker.clientId
    }
}
