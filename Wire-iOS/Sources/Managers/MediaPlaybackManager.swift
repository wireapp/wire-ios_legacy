
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

private let zmLog = ZMSLog(tag: "MediaPlaybackManager")

/// An object that observes changes in the media playback manager.
protocol MediaPlaybackManagerChangeObserver: AnyObject {
    /// The title of the active media player changed.
    func activeMediaPlayerTitleDidChange()
    /// The state of the active media player changes.
    func activeMediaPlayerStateDidChange()
}

extension Notification.Name {    
    static let mediaPlaybackManagerPlayerStateChanged = Notification.Name("MediaPlaybackManagerPlayerStateChangedNotification")
}

/// This object is an interface for AVS to control conversation media playback
final class MediaPlaybackManager: NSObject, AVSMedia {
    var audioTrackPlayer:AudioTrackPlayer = AudioTrackPlayer()
    private(set) weak var activeMediaPlayer: MediaPlayer?
    weak var changeObserver: MediaPlaybackManagerChangeObserver?
    private var titleObserver: NSObject?
    var name: String!
    
    weak var delegate: AVSMediaDelegate?
    
    var volume: Float = 0
    
    var looping: Bool {
        set {
            /// no-op
        }
        get {
            return false
        }
    }
    
    var playbackMuted: Bool {
        set {
            /// no-op
        }
        get {
            return false
        }
    }
    
    var recordingMuted: Bool = false
    
    init(name: String?) {
        super.init()
        
        self.name = name
        audioTrackPlayer.mediaPlayerDelegate = self
        titleObserver = nil
    }
    
    // MARK: - AVSMedia
    
    func play() {
        // AUDIO-557 workaround for AVSMediaManager calling play after we say we started to play.
        if activeMediaPlayer?.state != .playing {
            activeMediaPlayer?.play()
        }
    }
    
    func pause() {
        // AUDIO-557 workaround for AVSMediaManager calling pause after we say we are paused.
        if activeMediaPlayer?.state == .playing {
            activeMediaPlayer?.pause()
        }
    }
    
    func stop() {
        // AUDIO-557 workaround for AVSMediaManager calling stop after we say we are stopped.
        if activeMediaPlayer?.state != .completed {
            activeMediaPlayer?.stop()
        }
    }
    
    func resume() {
        activeMediaPlayer?.play()
    }
    
    func reset() {
        audioTrackPlayer.stop()
        
        audioTrackPlayer = AudioTrackPlayer()
        audioTrackPlayer.mediaPlayerDelegate = self
    }
    
    func setPlaybackMuted(_ playbackMuted: Bool) {
        if playbackMuted {
            activeMediaPlayer?.pause()
        }
    }
    
    // MARK: - Active Media Player State
    private func startObservingMediaPlayerChanges() {
        titleObserver = KeyValueObserver.observe(activeMediaPlayer as Any, keyPath: "title", target: self, selector: #selector(activeMediaPlayerTitleChanged(_:)), options: [.initial, .new])
    }
    
    private func stopObservingMediaPlayerChanges(_ mediaPlayer: MediaPlayer?) {
        titleObserver = nil
    }
    
    @objc
    private func activeMediaPlayerTitleChanged(_ change: [AnyHashable : Any]?) {
        changeObserver?.activeMediaPlayerTitleDidChange()
    }
}

extension MediaPlaybackManager: MediaPlayerDelegate {
    func mediaPlayer(_ mediaPlayer: MediaPlayer, didChangeTo state: MediaPlayerState) {
        zmLog.debug("mediaPlayer changed state: \(state)")
        
        changeObserver?.activeMediaPlayerStateDidChange()
        
        switch state {
        case .playing:
            if activeMediaPlayer !== mediaPlayer {
                activeMediaPlayer?.pause()
            }
            delegate?.didStartPlaying(self)
            activeMediaPlayer = mediaPlayer
            startObservingMediaPlayerChanges()
        case .paused:
            delegate?.didPausePlaying(self)
        case .completed:
            if activeMediaPlayer === mediaPlayer {
                activeMediaPlayer = nil
            }
            stopObservingMediaPlayerChanges(mediaPlayer)
            delegate?.didFinishPlaying(self) // this interfers with the audio session
        case .error:
            delegate?.didFinishPlaying(self) // this interfers with the audio session
        default:
            break
        }
        
        NotificationCenter.default.post(name: .mediaPlaybackManagerPlayerStateChanged, object: mediaPlayer)
        
    }
}
