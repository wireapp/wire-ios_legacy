
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ConversationContentViewController {
    @objc
    func activeMediaPlayerChanged(_ change: NSDictionary) {
        let mediaPlayingMessage = AppDelegate.shared().mediaPlaybackManager?.activeMediaPlayer?.sourceMessage

        if let mediaPlayingMessage = mediaPlayingMessage,
            mediaPlayingMessage.conversation == conversation,
            !displaysMessage(mediaPlayingMessage),
            !mediaPlayingMessage.isVideo {
            DispatchQueue.main.async(execute: {
                self.delegate.conversationContentViewController(self, didEndDisplayingActiveMediaPlayerFor: mediaPlayingMessage)
            })
        } else {
            DispatchQueue.main.async(execute: {
                self.delegate.conversationContentViewController(self, willDisplayActiveMediaPlayerFor: mediaPlayingMessage)
            })
        }
    }

    private func displaysMessage(_ message: ZMConversationMessage) -> Bool {
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else { return false }

        let index = dataSource?.indexOfMessage(message)

        for indexPath in indexPathsForVisibleRows {
            if indexPath.section == index {
                return true
            }
        }

        return false
    }


}
