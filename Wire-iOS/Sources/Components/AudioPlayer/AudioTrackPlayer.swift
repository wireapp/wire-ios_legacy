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

/// These enums represent the state of the current media in the player.

enum MediaPlayerState : Int {
    case ready = 0
    case playing
    case paused
    case completed
    case error
}

protocol MediaPlayer: NSObjectProtocol {
    var title: String? { get }
    var sourceMessage: ZMConversationMessage? { get }
    var state: MediaPlayerState? { get }
    func play()
    func pause()
    func stop()
}

typealias AudioTrackCompletionHandler = (_ loaded: Bool, _ error: Error?) -> Void

protocol AudioTrackPlayerDelegate: class {
    func stateDidChange(_ audioTrackPlayer: AudioTrackPlayer, state: MediaPlayerState?)
}

final class AudioTrackPlayer: NSObject, MediaPlayer {
    private var avPlayer: AVPlayer?
    private var timeObserverToken: Any?
    private var messageObserverToken: NSObjectProtocol?
    private var loadAudioTrackCompletionHandler: AudioTrackCompletionHandler?
    
    weak var audioTrackPlayerDelegate: AudioTrackPlayerDelegate?
    
    var state: MediaPlayerState? {
        didSet {
            audioTrackPlayerDelegate?.stateDidChange(self, state: state)
        }
    }
    var sourceMessage: ZMConversationMessage?
    private var nowPlayingInfo: [String : Any]?
    private var playHandler: Any?
    private var pauseHandler: Any?
    private var nextTrackHandler: Any?
    private var previousTrackHandler: Any?
    
    
    private(set) var audioTrack: AudioTrack? {
        willSet {
            (audioTrack as? NSObject)?.removeObserver(self, forKeyPath: "status")
        }
        
        didSet {
            ///TODO: Swift observer
            (audioTrack as? NSObject)?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        }
    }
    
    @objc dynamic
    private(set) var progress: CGFloat = 0 ///TODO: didSet
    
    var duration: CGFloat {
        if let duration = avPlayer?.currentItem?.asset.duration {
            return CGFloat(CMTimeGetSeconds(duration))
        }
        return 0
    }
    
    var elapsedTime: TimeInterval {
        guard let time = avPlayer?.currentTime() else { return 0}
        
        if CMTIME_IS_VALID(time) {
            return TimeInterval(time.value) / TimeInterval(time.timescale)
        }
        
        return 0
    }
    
    private(set) var playing = false
    weak var mediaPlayerDelegate: MediaPlayerDelegate?
        
    /// Start the currently loaded/paused track.
    func play() {
        if state == .completed {
            avPlayer?.seek(to: CMTimeMake(value: 0, timescale: 1))
        }
        
        avPlayer?.play()
    }
    
    /// Pause the currently playing track.
    func pause() {
        avPlayer?.pause()
    }
    
    deinit {
        audioTrack = nil
        
        avPlayer?.removeObserver(self, forKeyPath: "status")
        avPlayer?.removeObserver(self, forKeyPath: "rate")
        avPlayer?.removeObserver(self, forKeyPath: "currentItem")
        
        self.setIsRemoteCommandCenterEnabled(false)
    }
    
    func load(_ track: AudioTrack,
              sourceMessage: ZMConversationMessage,
              completionHandler: AudioTrackCompletionHandler? = nil) {
        progress = 0
        audioTrack = track
        self.sourceMessage = sourceMessage
        loadAudioTrackCompletionHandler = completionHandler
        
        if let streamURL = track.streamURL {
            if let avPlayer = avPlayer {
                avPlayer.replaceCurrentItem(with: AVPlayerItem(url: streamURL))
                
                if avPlayer.status == .readyToPlay {
                    loadAudioTrackCompletionHandler?(true, nil)
                }
            } else {
                let avPlayer = AVPlayer(url: streamURL)
                
                
                ///TODO: Swift KVO, not override observeValue
                avPlayer.addObserver(self, forKeyPath: "status", options: .new, context: nil)
                avPlayer.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
                avPlayer.addObserver(self, forKeyPath: "currentItem", options: [.new, .initial, .old], context: nil)
                
                self.avPlayer = avPlayer
            }
        } else {
            ///For testing only! streamURL is nil in test.
            self.avPlayer = AVPlayer()
        }
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidPlay(toEndTime:)), name: .AVPlayerItemDidPlayToEndTime, object: avPlayer?.currentItem)
        
        if let timeObserverToken = timeObserverToken {
            avPlayer?.removeTimeObserver(timeObserverToken)
        }
        
        timeObserverToken = avPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60), queue: DispatchQueue.main, using: { [weak self] time in
            guard let weakSelf = self,
                let duration = weakSelf.avPlayer?.currentItem?.asset.duration
                else { return }
            
            let itemRange = CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: 1), duration: duration)
            
            let normalizedRange = CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: 1), duration: CMTimeMake(value: 1, timescale: 1))
            
            let normalizedTime = CMTimeMapTimeFromRangeToRange(time, fromRange: itemRange, toRange: normalizedRange)
            
            weakSelf.progress = CGFloat(CMTimeGetSeconds(normalizedTime))
        })
        
        
        if let userSession = ZMUserSession.shared() {
            messageObserverToken = MessageChangeInfo.add(observer:self, for: sourceMessage, userSession: userSession)
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
        
        pauseHandler = commandCenter.pauseCommand.addTarget(handler: { [weak self] event in
            if self?.avPlayer?.rate > 0 {
                self?.pause()
                return .success
            } else {
                return .commandFailed
            }
        })
        
        playHandler = commandCenter.playCommand.addTarget(handler: { [weak self] event in
            if self?.audioTrack == nil {
                return .noSuchContent
            }
            
            if self?.avPlayer?.rate == 0 {
                self?.play()
                return .success
            } else {
                return .commandFailed
            }
        })
    }
    
    
    
    var isPlaying: Bool {
        return avPlayer?.rate > 0 && avPlayer?.error == nil
    }
    
    func stop() {
        avPlayer?.pause()
        avPlayer?.replaceCurrentItem(with: nil)
        audioTrack = nil
        messageObserverToken = nil
        sourceMessage = nil
    }
    
    var title: String? {
        return audioTrack?.title
    }
    
    //    class func keyPathsForValuesAffectingPlaying() -> Set<AnyHashable>? {
    //        return Set<AnyHashable>(["avPlayer?.rate"])///TODO: keyPath?
    //    }
    //
    //    class func keyPathsForValuesAffectingError() -> Set<AnyHashable>? {
    //        return Set<AnyHashable>(["avPlayer?.error"])
    //    }
    
    
    ///TODO: still need override?
    // MARK: - KVO observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (object as? AVPlayerItem) == avPlayer?.currentItem && (keyPath == "status") {
            if avPlayer?.currentItem?.status == .failed {
                let state: MediaPlayerState = .error
                audioTrack?.failedToLoad = true
                mediaPlayerDelegate?.mediaPlayer(self, didChangeTo: state)
                
                self.state = state
            }
        }
        
        if object as? AVPlayer == avPlayer && (keyPath == "status") {
            if avPlayer?.status == .readyToPlay {
                loadAudioTrackCompletionHandler?(true, nil)
            } else if avPlayer?.status == .failed {
                loadAudioTrackCompletionHandler?(false, avPlayer?.error)
            }
        }
        
        if object as? AVPlayer == avPlayer && (keyPath == "rate") {
            
            if avPlayer?.rate > 0 {
                let state: MediaPlayerState = .playing
                mediaPlayerDelegate?.mediaPlayer(self, didChangeTo: state)
                self.state = state
            } else if state != .completed {
                let state: MediaPlayerState = .paused
                mediaPlayerDelegate?.mediaPlayer(self, didChangeTo: state)
                self.state = state
            }
            
            updateNowPlayingState()
        }
        
        if object as? AVPlayer == avPlayer && (keyPath == "currentItem") {
            
            if avPlayer?.currentItem == nil {
                setIsRemoteCommandCenterEnabled(false)
                clearNowPlayingState()
                let state: MediaPlayerState = .completed
                mediaPlayerDelegate?.mediaPlayer(self, didChangeTo: state)
                
                self.state = state
            } else {
                setIsRemoteCommandCenterEnabled(true)
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
        if let rate = avPlayer?.rate {
            newInfo?[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: rate)
        }
        
        let info = MPNowPlayingInfoCenter.default()
        info.nowPlayingInfo = newInfo
        nowPlayingInfo = newInfo
    }
    
    // MARK: AVPlayer notifications
    @objc
    func itemDidPlay(toEndTime notification: Notification?) {
        // AUDIO-557 workaround for AVSMediaManager trying to pause already paused tracks.
        delay(0.1) { [weak self] in
            guard let weakSelf = self else { return }
            
            self?.clearNowPlayingState()
            self?.state = .completed
            if let state = weakSelf.state {
                self?.mediaPlayerDelegate?.mediaPlayer(weakSelf, didChangeTo: state)
            }
        }
    }
    
    // MARK: - MPNowPlayingInfoCenter
    
    func populateNowPlayingState() {
        let playbackDuration: NSNumber
        if let duration: CMTime = avPlayer?.currentItem?.asset.duration {
            playbackDuration = NSNumber(value: CMTimeGetSeconds(duration))
        } else {
            playbackDuration = 0
        }
        
        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: audioTrack?.title ?? "",
            MPMediaItemPropertyArtist: audioTrack?.author ?? "",
            MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: avPlayer?.rate ?? 0),
            MPMediaItemPropertyPlaybackDuration: playbackDuration]
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: - ZMMessageObserver
extension AudioTrackPlayer: ZMMessageObserver {
    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        if changeInfo.message.hasBeenDeleted {
            stop()
        }
    }
}

