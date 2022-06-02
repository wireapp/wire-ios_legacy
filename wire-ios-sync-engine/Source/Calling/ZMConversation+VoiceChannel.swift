//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

private var voiceChannelAssociatedKey: UInt8 = 0

public extension ZMConversation {
    /// NOTE: this object is transient, and will be re-created periodically. Do not hold on to this object, hold on to the owning conversation instead.
    var voiceChannel: VoiceChannel? {
            guard conversationType == .oneOnOne || conversationType == .group else { return nil }

            if let voiceChannel = objc_getAssociatedObject(self, &voiceChannelAssociatedKey) as? VoiceChannel {
                return voiceChannel
            } else {
                let voiceChannel = WireCallCenterV3Factory.voiceChannelClass.init(conversation: self)
                objc_setAssociatedObject(self, &voiceChannelAssociatedKey, voiceChannel, .OBJC_ASSOCIATION_RETAIN)
                return voiceChannel
            }
    }

}
