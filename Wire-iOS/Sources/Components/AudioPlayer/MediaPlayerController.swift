//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import AVFoundation
import WireDataModel

/// For playing videos in conversation
/// Controls and observe the state of a AVPlayer instance for integration with the AVSMediaManager
final class MediaPlayerController: NSObject {

    let message: ZMConversationMessage
    private let player: AVPlayer
    weak var delegate: MediaPlayerDelegate?
    fileprivate var playerRateObserver: NSKeyValueObservation!

    init(player: AVPlayer,
         message: ZMConversationMessage,
         delegate: MediaPlayerDelegate) {
        self.player = player
        self.message = message
        self.delegate = delegate

        super.init()

        playerRateObserver = self.player.observe(\AVPlayer.rate) { [weak self] _, _ in
            self?.playerRateChanged()
        }
    }

    deinit {
        playerRateObserver.invalidate()
    }

    func tearDown() {
        self.delegate?.mediaPlayer(self, didChangeTo: .completed)
    }

    private func playerRateChanged() {
        if player.rate > 0 {
            delegate?.mediaPlayer(self, didChangeTo: MediaPlayerState.playing)
        } else {
            delegate?.mediaPlayer(self, didChangeTo: MediaPlayerState.paused)
        }
    }
}

extension MediaPlayerController: MediaPlayer {

    var title: String? {
        return message.fileMessageData?.filename
    }

    var sourceMessage: ZMConversationMessage? {
        return message
    }

    var state: MediaPlayerState? {
        if player.rate > 0 {
            return MediaPlayerState.playing
        } else {
            return MediaPlayerState.paused
        }
    }

    func play() {
        player.play()
    }

    func stop() {
        player.pause()
    }

    func pause() {
        player.pause()
    }
}
