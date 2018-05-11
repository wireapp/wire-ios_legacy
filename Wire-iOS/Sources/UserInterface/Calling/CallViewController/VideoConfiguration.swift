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
        return computeVideoStreams().preview
    }
    
    var videoStreams: [UUID] {
        return computeVideoStreams().grid
    }
    
    private func computeVideoStreams() -> (preview: UUID?, grid: [UUID]) {
        var otherParticipants: [UUID] = voiceChannel.participants.compactMap { user in
            guard let user = user as? ZMUser else { return nil }
            switch voiceChannel.state(forParticipant: user) {
            case .connected(videoState: let state) where state.isSending: return user.remoteIdentifier
            default: return nil
            }
        }
        
        // TODO: Do we need this? Right now the participants array is empty for 1-1 calls.
        if otherParticipants.isEmpty, voiceChannel.conversation?.conversationType == .oneOnOne,
            let otherUser = voiceChannel.conversation?.firstActiveParticipantOtherThanSelf()?.remoteIdentifier {
            otherParticipants += [otherUser]
        }
        
        let selfStream = voiceChannel.videoState.isSending ? ZMUser.selfUser().remoteIdentifier : nil

        if 1 == otherParticipants.count, let selfStream = selfStream {
            return (selfStream, otherParticipants)
        } else {
            return (nil, nil == selfStream ? otherParticipants : [selfStream!] + otherParticipants)
        }
    }

}
