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

extension VoiceChannelParticipantCell {
    
    func configure(for user: ZMUser, participantState: CallParticipantState) {
        if let existingUser = userImage.user, !existingUser.isEqual(user) {
            userImage.user = user
        }
        
        nameLabel.text = user.displayName.localizedUppercase
        
        if participantState == .connecting {
            userImage.state = .connecting
        } else {
            userImage.state = .talking
        }
        
        if case .connected(muted: let muted, sendingVideo: _) = participantState {
            userImage.badgeIcon = muted ? .microphoneWithStrikethrough : .none
        }

    }
    
}
