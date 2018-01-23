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
import CocoaLumberjackSwift

public enum PlayingState: UInt, CustomStringConvertible {
    case idle, playing
    
    public var description: String {
        switch self {
        case .idle: return "idle"
        case .playing: return "playing"
        }
    }
}

public typealias RecordingLevel = Float

public enum AudioRecorderFormat {
    case m4A, wav
    func fileExtension() -> String {
        switch self {
        case .m4A:
            return "m4a"
        case .wav:
            return "wav"
        }
    }
    
    func audioFormat() -> AudioFormatID {
        switch self {
        case .m4A:
            return kAudioFormatMPEG4AAC
        case .wav:
            return kAudioFormatLinearPCM
        }
    }
}

public enum AudioRecorderState {
    case recording, playback
}

public protocol AudioRecorderType: class {
    var format: AudioRecorderFormat { get }
    var state: AudioRecorderState { get set }
    var fileURL: URL? { get }
    var maxRecordingDuration: TimeInterval? { get set }
    var currentDuration: TimeInterval { get }
    var recordTimerCallback: ((TimeInterval) -> Void)? { get set }
    var recordLevelCallBack: ((RecordingLevel) -> Void)? { get set }
    var playingStateCallback: ((PlayingState) -> Void)? { get set }
    var recordStartedCallback: (() -> Void)? { get set }
    var recordEndedCallback: ((Bool) -> Void)? { get set } // recordedToMaxDuration: Bool
    
    func startRecording()
    @discardableResult func stopRecording() -> Bool
    func deleteRecording()
    func playRecording()
    func stopPlaying()
    func levelForCurrentState() -> RecordingLevel
    func durationForCurrentState() -> TimeInterval?
}

public final class AudioRecorder: NSObject, AudioRecorderType {
    
    public let format: AudioRecorderFormat
    public var state: AudioRecorderState = .recording
    
    lazy var audioRecorder : AVAudioRecorder? = { [weak self] in
        guard let `self` = self else { return nil }
        let fileName = String.filenameForSelfUser().appendingPathExtension(self.format.fileExtension())!
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        let settings = [
            AVFormatIDKey : self.format.audioFormat(),
            AVSampleRateKey : 32000,
            AVNumberOfChannelsKey : 1,
        ]
        
        let audioRecorder = try? AVAudioRecorder(url: fileURL!, settings: settings)

        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: .AVAudioSessionInterruption,
                                               object: AVAudioSession.sharedInstance())

        return audioRecorder
    }()
    
    var displayLink: CADisplayLink?
    var audioPlayer : AVAudioPlayer?
    var audioPlayerDelegate: AudioPlayerDelegate?
    public var maxRecordingDuration: TimeInterval? = .none
    let fm = FileManager.default
    public var currentDuration: TimeInterval = 0
    public var recordTimerCallback: ((TimeInterval) -> Void)?
    public var recordLevelCallBack: ((RecordingLevel) -> Void)?
    public var playingStateCallback: ((PlayingState) -> Void)?
    public var recordStartedCallback: (() -> Void)?
    public var recordEndedCallback: ((Bool) -> Void)? // recordedToMaxDuration: Bool
    public var fileURL: URL?
    
    fileprivate var recordingStartTime: TimeInterval?
    
    override init() {
        fatalError("init() is not implemented for AudioRecorder")
    }
    
    init?(format: AudioRecorderFormat = .m4A, maxRecordingDuration: TimeInterval?) {
        self.maxRecordingDuration = maxRecordingDuration
        self.format = format
        super.init()
    }
    
    deinit {
        removeDisplayLink()
    }
    
    // MARK: Audio Session Interruption handling
    
    func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
                return
        }
        if type == .began {
            stopRecording()
        }
    }
    
    // MARK: Recording
    
    public func startRecording() {
        guard let audioRecorder = self.audioRecorder else { return }

        setSessionActive(true)

        state = .recording
        recordTimerCallback?(0)
        fileURL = nil
        setupDisplayLink()
        
        var successfullyStarted = false
        
        if let maxDuration = self.maxRecordingDuration {
            successfullyStarted = audioRecorder.record(forDuration: maxDuration)
            if !successfullyStarted { DDLogError("Failed to start audio recording") }
            else { self.recordStartedCallback?() }
        }
        else {
            successfullyStarted = audioRecorder.record()
            if !successfullyStarted { DDLogError("Failed to start audio recording") }
        }
        
        recordingStartTime = successfullyStarted ? audioRecorder.deviceCurrentTime : nil
    }
    
    @discardableResult public func stopRecording() -> Bool {
        audioRecorder?.stop()
        return postRecordingProcessing()
    }
    
    fileprivate func postRecordingProcessing() -> Bool {
        recordLevelCallBack?(0)
        removeDisplayLink()
        guard let filePath = audioRecorder?.url.path , fm.fileExists(atPath: filePath) else { return false }
        fileURL = audioRecorder?.url
        setSessionActive(false)
        return true
    }
    
    public func deleteRecording() {
        currentDuration = 0
        if let filePath = audioRecorder?.url.path, FileManager.default.fileExists(atPath: filePath) {
            audioRecorder?.deleteRecording()
        }
    }
    
    fileprivate func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
    
    fileprivate func removeDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc fileprivate func displayLinkDidFire() {
        recordLevelCallBack?(levelForCurrentState())
        guard let duration = durationForCurrentState() , currentDuration != duration else { return }
        currentDuration = duration
        recordTimerCallback?(currentDuration)
    }
    
    private func setSessionActive(_ active: Bool) {
        if active {
            AVSMediaManager.sharedInstance().stopAudio()
            AppDelegate.shared().mediaPlaybackManager?.audioTrackPlayer.stop()
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        }
        catch let error {
            DDLogError("Failed to set session activity to \(active): \(error)")
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(active ? AVAudioSessionCategoryPlayAndRecord : AVAudioSessionCategorySoloAmbient)
        } catch let error {
            DDLogError("Failed change audio category for recording: \(error)")
        }
    }
    
    // MARK: Playing
    
    public func playRecording() {
        guard let audioRecorder = self.audioRecorder else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch let error {
            DDLogError("Failed change audio category for playback: \(error)")
        }
        
        state = .playback
        setupDisplayLink()
        audioPlayer = try? AVAudioPlayer(contentsOf: audioRecorder.url)
        audioPlayer?.isMeteringEnabled = true
        
        audioPlayerDelegate = AudioPlayerDelegate { [weak self] _ in
            guard let `self` = self else { return }
            self.removeDisplayLink()
            self.playingStateCallback?(.idle)
            self.recordLevelCallBack?(0)
            guard let duration = self.audioPlayer?.duration else { return }
            self.recordTimerCallback?(duration)
        }
        
        audioPlayer?.delegate = audioPlayerDelegate
        audioPlayer?.play()
        playingStateCallback?(.playing)
    }
    
    public func stopPlaying() {
        recordLevelCallBack?(0)
        removeDisplayLink()
        audioPlayer?.pause()
        playingStateCallback?(.idle)
    }
    
    // MARK: Leveling & Duration
    
    public func levelForCurrentState() -> RecordingLevel {
        let powerProvider: PowerProvider? = state == .recording ? audioRecorder : audioPlayer
        powerProvider?.updateMeters()
        let level = powerProvider?.averagePowerForFirstActiveChannel() ?? minimumPower
        // This value is in dB (logarithmic, [-160, 0]) and varies between -160 and 0 so we need to normalize it, see
        // https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVAudioRecorder_ClassReference/#//apple_ref/occ/instm/AVAudioRecorder/peakPowerForChannel:
        return level.normalizedDecibelValue()
    }
    
    public func durationForCurrentState() -> TimeInterval? {
        switch state {
        case .recording:
            guard let recorder = audioRecorder, let startTime = recordingStartTime else {
                return nil
            }
            return recorder.deviceCurrentTime - startTime
            
        case .playback:
            return audioPlayer?.currentTime
        }
    }
    
}


extension AudioRecorder: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        var recordedToMaxDuration = false
        recordingStartTime = nil
        
        if let maxRecordingDuration = self.maxRecordingDuration {
            let duration = AVURLAsset(url: recorder.url).duration.seconds
            recordedToMaxDuration = duration >= maxRecordingDuration
        }
        
        // in the case that the recording finished due to the maxRecordingDuration
        // reached, we should still clean up afterwards
        if recordedToMaxDuration { _ = postRecordingProcessing() }
        
        self.recordEndedCallback?(recordedToMaxDuration)
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DDLogError("Cannot finish recording: \(String(describing: error))")
    }
}

// MARK: AVAvdioPlayerDelegate

final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    
    let playerDidFinishClosure: (Bool) -> Void
    
    init(playerDidFinishClosure: @escaping (Bool) -> Void) {
        self.playerDidFinishClosure = playerDidFinishClosure
        super.init()
    }
    
    @objc func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playerDidFinishClosure(flag)
    }
}



// MARK: Power Provider

protocol PowerProvider {
    func updateMeters() /* call to refresh meter values */
    func averagePower(forChannel channelNumber: Int) -> Float
}

let minimumPower: Float = -160

extension PowerProvider {
    
    func averagePowerForFirstActiveChannel() -> Float {
        for power in (0..<3).map(averagePower) where power != minimumPower {
            return power
        }
        
        return minimumPower
    }
}

extension AVAudioPlayer: PowerProvider {}
extension AVAudioRecorder: PowerProvider {}
