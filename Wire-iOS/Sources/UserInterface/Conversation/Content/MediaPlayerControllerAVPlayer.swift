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
import AVKit

/**
 an AVPlayer instance for integration with the AVSMediaManager
 */
@objc class MediaPlayerControllerAVPlayer: AVPlayer {

    var message : ZMConversationMessage!
    weak var delegate : MediaPlayerDelegate?

    fileprivate var playerRateObserver : Any?

    init(url: URL, message: ZMConversationMessage, delegate: MediaPlayerDelegate) {
        self.message = message
        self.delegate = delegate

        super.init(url: url)

        NotificationCenter.default.addObserver(self, selector: #selector(playerRateChanged), name:NSNotification.Name(rawValue: "rate"), object: .none)
    }


    required override init(playerItem item: AVPlayerItem?) {
        super.init(playerItem: item)
    }

    required override init() {
        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "rate"), object: nil)
        delegate?.mediaPlayer(self, didChangeTo: MediaPlayerState.completed)
    }

}

extension MediaPlayerControllerAVPlayer : MediaPlayer {

    var title: String {
        return message.fileMessageData?.filename ?? ""
    }

    var sourceMessage: ZMConversationMessage! {
        return message
    }

    var state: MediaPlayerState {
        if self.rate > 0 {
            return MediaPlayerState.playing
        } else {
            return MediaPlayerState.paused
        }
    }

    func stop() {
        self.pause()
    }
}

extension MediaPlayerControllerAVPlayer {

    func playerRateChanged() {
        if self.rate > 0 {
            delegate?.mediaPlayer(self, didChangeTo: MediaPlayerState.playing)
        } else {
            delegate?.mediaPlayer(self, didChangeTo: MediaPlayerState.paused)
        }
    }

}
