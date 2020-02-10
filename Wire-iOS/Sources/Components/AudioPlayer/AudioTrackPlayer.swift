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
import MediaPlayer

// MARK: - ZMMessageObserver
extension AudioTrackPlayer: ZMMessageObserver {
    func messageDidChange(_ changeInfo: MessageChangeInfo?) {
        if changeInfo?.message.hasBeenDeleted != nil {
            stop()
        }
    }
}

final class AudioTrackPlayer: NSObject, MediaPlayer {
    private var avPlayer: AVPlayer?
    private weak var audioTrack: (NSObjectProtocol & AudioTrack)?
    private var progress: CGFloat = 0.0
    private var timeObserverToken: Any?
    private var messageObserverToken: Any?
    private var loadAudioTrackCompletionHandler: ((_ loaded: Bool, _ error: Error?) -> Void)?
    private var state: MediaPlayerState?
    private weak var sourceMessage: ZMConversationMessage?
    private var nowPlayingInfo: [AnyHashable : Any]?
    private var playHandler: Any?
    private var pauseHandler: Any?
    private var nextTrackHandler: Any?
    private var previousTrackHandler: Any?

    
    private(set) weak var audioTrack: (NSObjectProtocol & AudioTrack)?
    private(set) var progress: CGFloat = 0.0
    private(set) var duration: CGFloat = 0.0
    private(set) var elapsedTime: TimeInterval = 0.0
    private(set) var playing = false
    weak var mediaPlayerDelegate: MediaPlayerDelegate?

    func loadTrack(_ track: (NSObjectProtocol & AudioTrack)?, sourceMessage: ZMConversationMessage?, completionHandler: ((_ loaded: Bool, _ error: Error?) -> Void)? = nil) {
    }

    /// Start the currently loaded/paused track.
    func play() {
    }
    
    /// Pause the currently playing track.
    func pause() {
    }

    deinit {
        audioTrack = nil
        
        avPlayer.removeObserver(self, forKeyPath: "status")
        avPlayer.removeObserver(self, forKeyPath: "rate")
        avPlayer.removeObserver(self, forKeyPath: "currentItem")
        
        self.isRemoteCommandCenterEnabled = false
    }
    
    func loadTrack(_ track: (NSObjectProtocol & AudioTrack)?, sourceMessage: ZMConversationMessage?, completionHandler: @escaping (_ loaded: Bool, _ error: Error?) -> Void) {
        progress = 0
        audioTrack = track
        self.sourceMessage = sourceMessage
        loadAudioTrackCompletionHandler = completionHandler
        
        if avPlayer == nil {
            if let streamURL = track?.streamURL {
                avPlayer = AVPlayer(url: streamURL)
            }
            avPlayer.addObserver(self, forKeyPath: "status", options: .new, context: nil)
            avPlayer.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
            avPlayer.addObserver(self, forKeyPath: "currentItem", options: [.new, .initial, .old], context: nil)
        } else {
            
            if let streamURL = track?.streamURL {
                avPlayer.replaceCurrentItem(with: AVPlayerItem(url: streamURL))
            }
            
            if avPlayer.status == .readyToPlay {
                loadAudioTrackCompletionHandler(true, nil)
            }
        }
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidPlay(toEndTime:)), name: .AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
        
        if timeObserverToken != nil {
            avPlayer.removeTimeObserver(timeObserverToken)
        }
        
        weak var weakSelf = self
        timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60), queue: DispatchQueue.main, using: { time in
            var itemRange: CMTimeRange? = nil
            if let duration = weakSelf?.avPlayer.currentItem?.asset.duration {
                itemRange = CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: 1), duration: duration)
            }
            let normalizedRange = CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: 1), duration: CMTimeMake(value: 1, timescale: 1))
            var normalizedTime: CMTime? = nil
            if let itemRange = itemRange {
                normalizedTime = CMTimeMapTimeFromRangeToRange(time, fromRange: itemRange, toRange: normalizedRange)
            }
            if let normalizedTime = normalizedTime {
                weakSelf?.progress = CMTimeGetSeconds(normalizedTime)
            }
        })
        
        let userSession = ZMUserSession.shared()
        if userSession != nil {
            messageObserverToken = MessageChangeInfo.addObserver(self, for: sourceMessage, userSession: ZMUserSession.shared())
        }

    }
    
    func setIsRemoteCommandCenterEnabled(_ enabled: Bool) {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        if !enabled {
            commandCenter.playCommand.removeTarget(playHandler)
            commandCenter.pauseCommand.removeTarget(pauseHandler)
            commandCenter.nextTrackCommand.removeTarget(nextTrackHandler)
            commandCenter.previousTrackCommand.removeTarget(previousTrackHandler)
            return
        }
        
        ZM_WEAK(self)
        pauseHandler = commandCenter.pauseCommand.addTarget(handler: { event in
            ZM_STRONG(self)
            if self.avPlayer.rate > 0 {
                self.pause()
                return .success
            } else {
                return .commandFailed
            }
        })
        
        playHandler = commandCenter.playCommand.addTarget(handler: { event in
            ZM_STRONG(self)
            if self.audioTrack == nil {
                return .noSuchContent
            }
            
            if self.avPlayer.rate == 0 {
                self.play()
                return .success
            } else {
                return .commandFailed
            }
        })
    }
    
    var elapsedTime: TimeInterval {
        let time = avPlayer.currentTime
        if CMTIME_IS_VALID(time) {
            return TimeInterval(time.value / time.timescale)
        }
        return 0
    }
    
    func duration() -> CGFloat {
        if let duration = avPlayer.currentItem?.asset.duration {
            return CGFloat(CMTimeGetSeconds(duration))
        }
        return 0.0
    }
    
    func isPlaying() -> Bool {
        return avPlayer.rate > 0 && avPlayer.error == nil
    }
    
    func play() {
        if state == MediaPlayerStateCompleted {
            avPlayer.seek(to: CMTimeMake(value: 0, timescale: 1))
        }
        
        avPlayer.play()
    }
    
    func pause() {
        avPlayer.pause()
    }
    
    func stop() {
        avPlayer.pause()
        avPlayer.replaceCurrentItem(with: nil)
        audioTrack = nil
        messageObserverToken = nil
        sourceMessage = nil
    }
    
    func title() -> String? {
        return audioTrack.title()
    }
    
    class func keyPathsForValuesAffectingPlaying() -> Set<AnyHashable>? {
        return Set<AnyHashable>(["avPlayer.rate"])
    }
    
    class func keyPathsForValuesAffectingError() -> Set<AnyHashable>? {
        return Set<AnyHashable>(["avPlayer.error"])
    }
    
    func setAudioTrack(_ audioTrack: (NSObjectProtocol & AudioTrack)?) {
        if self.audioTrack == audioTrack {
            return
        }
        
        if self.audioTrack != nil {
            self.audioTrack.removeObserver(self, forKeyPath: "status")
        }
        self.audioTrack = audioTrack
        if self.audioTrack != nil {
            self.audioTrack.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        }
    }
    
    // MARK: - KVO observer
    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (object as? AVPlayerItem) == avPlayer.currentItem && (keyPath == "status") {
            if avPlayer.currentItem?.status == .failed {
                state = MediaPlayerStateError
                audioTrack.failedToLoad = true
                mediaPlayerDelegate.mediaPlayer(self, didChangeToState: state)
            }
        }
        
        if object == avPlayer && (keyPath == "status") {
            if avPlayer.status == .readyToPlay {
                loadAudioTrackCompletionHandler(true, nil)
            } else if avPlayer.status == .failed {
                loadAudioTrackCompletionHandler(false, avPlayer.error)
            }
        }
        
        if object == avPlayer && (keyPath == "rate") {
            
            if avPlayer.rate > 0 {
                state = MediaPlayerStatePlaying
                mediaPlayerDelegate.mediaPlayer(self, didChangeToState: state)
            } else if state != MediaPlayerStateCompleted {
                state = MediaPlayerStatePaused
                mediaPlayerDelegate.mediaPlayer(self, didChangeToState: state)
            }
            
            updateNowPlayingState()
        }
        
        if object == avPlayer && (keyPath == "currentItem") {
            
            if avPlayer.currentItem == nil {
                self.isRemoteCommandCenterEnabled = false
                clearNowPlayingState()
                state = MediaPlayerStateCompleted
                mediaPlayerDelegate.mediaPlayer(self, didChangeToState: state)
            } else {
                self.isRemoteCommandCenterEnabled = true
                populateNowPlayingState()
            }
        }
        
    }
    
    // MARK: - MPNowPlayingInfoCenter
    func clearNowPlayingState() {
        let info = MPNowPlayingInfoCenter.default()
        info.nowPlayingInfo = nil
        nowPlayingInfo = nil
    }
    
    func updateNowPlayingState() {
        var newInfo = nowPlayingInfo
        newInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: elapsedTime)
        newInfo?[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: avPlayer.rate)
        
        let info = MPNowPlayingInfoCenter.default()
        info.nowPlayingInfo = newInfo
        nowPlayingInfo = newInfo
    }
    
    // MARK: AVPlayer notifications
    func itemDidPlay(toEndTime notification: Notification?) {
        // AUDIO-557 workaround for AVSMediaManager trying to pause already paused tracks.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            self.clearNowPlayingState()
            self.state = MediaPlayerStateCompleted
            self.mediaPlayerDelegate.mediaPlayer(self, didChangeToState: self.state)
        })
    }

    // MARK: - MPNowPlayingInfoCenter

    func populateNowPlayingState() {
        let playbackDuration: NSNumber
        if let duration: CMTime = avPlayer.currentItem?.asset.duration {
            playbackDuration = NSNumber(value: CMTimeGetSeconds(duration))
        } else {
            playbackDuration = 0
        }

        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: audioTrack?.title ?? "",
            MPMediaItemPropertyArtist: audioTrack?.author ?? "",
            MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: avPlayer.rate),
            MPMediaItemPropertyPlaybackDuration: playbackDuration]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
    }
}
