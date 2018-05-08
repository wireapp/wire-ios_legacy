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

struct VideoConfiguration {
    let voiceChannel: VoiceChannel
}

extension VideoConfiguration: VideoGridConfiguration {
    
    var floatingVideoStream: UUID? {
        return nil
    }
    
    var videoStreams: [UUID] {
        let otherParticipants: [UUID] = voiceChannel.participants.compactMap { user in
            guard let user = user as? ZMUser else { return nil }
            
            if case .connected(.started) = voiceChannel.state(forParticipant: user) {
                return user.remoteIdentifier
            }
            
            return nil
        }
        
        return [ZMUser.selfUser().remoteIdentifier] + otherParticipants
    }

}
