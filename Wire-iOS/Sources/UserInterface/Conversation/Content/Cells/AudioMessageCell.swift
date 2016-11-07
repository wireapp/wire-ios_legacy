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
import Cartography
import CocoaLumberjackSwift

/// Displays the audio message with different states
public final class AudioMessageCell: ConversationCell {
    private let containerView = UIView()
    
    private let downloadProgressView = CircularProgressView()
    private let playButton = IconButton()
    private let timeLabel = UILabel()
    private let playerProgressView = ProgressView()
    private let waveformProgressView = WaveformProgressView()
    private let loadingView = ThreeDotsLoadingView()
    private let obfuscationView = UIImageView()

    private var audioPlayerProgressObserver: NSObject? = .none
    private var audioPlayerStateObserver: NSObject? = .none
    private var allViews : [UIView] = []
    
    private var expectingDownload: Bool = false
    
    private let proximityListener = DeviceProximityListener()
    
    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.layer.cornerRadius = 4
        self.containerView.cas_styleClass = "container-view"
        containerView.clipsToBounds = true

        self.playButton.translatesAutoresizingMaskIntoConstraints = false
        self.playButton.addTarget(self, action: #selector(AudioMessageCell.onActionButtonPressed(_:)), for: .touchUpInside)
        self.playButton.accessibilityLabel = "AudioActionButton"
        self.playButton.layer.masksToBounds = true

        self.downloadProgressView.translatesAutoresizingMaskIntoConstraints = false
        self.downloadProgressView.isUserInteractionEnabled = false
        self.downloadProgressView.accessibilityLabel = "AudioProgressView"
        
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.timeLabel.numberOfLines = 1
        self.timeLabel.textAlignment = .center
        self.timeLabel.accessibilityLabel = "AudioTimeLabel"

        self.playerProgressView.setDeterministic(true, animated: false)
        self.playerProgressView.accessibilityLabel = "PlayerProgressView"
        
        self.loadingView.translatesAutoresizingMaskIntoConstraints = false
        self.loadingView.isHidden = true

        self.obfuscationView.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorAccentDimmedFlat)
        self.obfuscationView.isOpaque = true
        self.obfuscationView.contentMode = .center
        self.obfuscationView.image = UIImage.init(for: .microphone, iconSize: .tiny, color: ColorScheme.default().color(withName: ColorSchemeColorBackground))

        self.allViews = [self.playButton, self.timeLabel, self.downloadProgressView, self.playerProgressView, self.waveformProgressView, self.loadingView, self.obfuscationView]
        self.allViews.forEach(self.containerView.addSubview)
        
        self.messageContentView.addSubview(self.containerView)
        
        CASStyler.default().styleItem(self)
        self.timeLabel.font = self.timeLabel.font.monospacedFont()

        self.createConstraints()
        
        var currentElements = self.accessibilityElements ?? []
        currentElements.append(contentsOf: [playButton, timeLabel, likeButton, messageToolboxView])
        self.accessibilityElements = currentElements
        
        let audioTrackPlayer = self.audioTrackPlayer()
        
        self.audioPlayerProgressObserver = KeyValueObserver.observe(audioTrackPlayer, keyPath: "progress", target: self, selector: #selector(audioProgressChanged(_:)), options: [.initial, .new])
        
        self.audioPlayerStateObserver = KeyValueObserver.observe(audioTrackPlayer, keyPath: "state", target: self, selector: #selector(audioPlayerStateChanged(_:)), options: [.initial, .new])
    }
    
    deinit {
        audioPlayerStateObserver = nil
        audioPlayerProgressObserver = nil
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func createConstraints() {
        constrain(self.messageContentView, self.containerView, self.playButton, self.timeLabel, self.authorLabel) { messageContentView, containerView, playButton, timeLabel, authorLabel in
            containerView.left == authorLabel.left
            containerView.right == messageContentView.rightMargin
            containerView.top == messageContentView.top
            containerView.bottom == messageContentView.bottom
            containerView.height == 56
            
            playButton.left == containerView.left + 12
            playButton.centerY == containerView.centerY
            playButton.width == 32
            playButton.height == playButton.width
            
            timeLabel.left == playButton.right + 12
            timeLabel.centerY == containerView.centerY
            timeLabel.width >= 32
        }

        constrain(containerView, obfuscationView) { container, obfuscationView in
            obfuscationView.edges == container.edges
        }
        
        constrain(self.downloadProgressView, self.playButton) { downloadProgressView, playButton in
            downloadProgressView.center == playButton.center
            downloadProgressView.width == playButton.width - 2
            downloadProgressView.height == playButton.height - 2
        }
        
        constrain(self.playerProgressView, self.timeLabel, self.containerView, self.waveformProgressView, self.loadingView) { playerProgressView, timeLabel, containerView, waveformProgressView, loadingView in
            playerProgressView.centerY == containerView.centerY
            playerProgressView.left == timeLabel.right + 12
            playerProgressView.right == containerView.right - 12
            playerProgressView.height == 1
            
            waveformProgressView.centerY == containerView.centerY
            waveformProgressView.left == playerProgressView.left
            waveformProgressView.right == playerProgressView.right
            waveformProgressView.height == 32
            
            loadingView.center == containerView.center
        }

        constrain(containerView, countdownContainerView) { container, countDownContainer in
            countDownContainer.top == container.top
        }
    }
    
    open override func update(forMessage changeInfo: MessageChangeInfo!) -> Bool {
        let needsLayout = super.update(forMessage: changeInfo)
        
        if let fileMessageData = self.message.fileMessageData {
            self.configureForAudioMessage(message, initialConfiguration: false)
            
            if fileMessageData.transferState == .downloaded && self.expectingDownload {
                self.playTrack()
                self.expectingDownload = false
            }
        }

        if changeInfo.isObfuscatedChanged {
            stopPlaying()
        }
        
        return needsLayout
    }
    
    override open func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        self.expectingDownload = false
        
        if Message.isAudioMessage(message), let _ = message.fileMessageData {
            self.configureForAudioMessage(message, initialConfiguration: true)
        }
        else {
            fatalError("Wrong message type: \(type(of: message)): \(message)")
        }
    }
    
    private func configureForAudioMessage(_ message: ZMConversationMessage, initialConfiguration: Bool) {
        guard let fileMessageData = message.fileMessageData else {
            return
        }
        
        self.configureVisibleViews(forFileMessageData: fileMessageData, initialConfiguration: initialConfiguration)
        self.updateTimeLabel()
        
        if self.isOwnTrackPlayingInAudioPlayer() {
            self.updateActivePlayerProgressAnimated(false)
            self.updateActivePlayButton()
        }
        else {
            self.playerProgressView.setProgress(0, animated: false)
            self.waveformProgressView.setProgress(0, animated: false)
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.proximityListener.stopListening()
    }

    public override func willDeleteMessage() {
        proximityListener.stopListening()
        let player = audioTrackPlayer()
        let audioTrackPlayingSame = player.sourceMessage != nil && player.sourceMessage.isEqual(message)
        guard audioTrackPlayingSame else { return }
        player.stop()
    }
    
    private func configureVisibleViews(forFileMessageData fileMessageData: ZMFileMessageData, initialConfiguration: Bool) {
        guard let state = FileMessageCellState.fromConversationMessage(message) else { return }

        var visibleViews = [self.playButton, self.timeLabel]
        
        if (fileMessageData.normalizedLoudness.count > 0) {
            waveformProgressView.samples = fileMessageData.normalizedLoudness
            if let accentColor = message.sender?.accentColor {
                waveformProgressView.barColor = accentColor
                waveformProgressView.highlightedBarColor = UIColor.gray
            }
            visibleViews.append(self.waveformProgressView)
        } else {
            visibleViews.append(self.playerProgressView)
        }
        
        switch state {
        case .obfuscated: visibleViews = [obfuscationView]
        case .unavailable: visibleViews = [self.loadingView]
        case .downloading, .uploading:
            visibleViews.append(self.downloadProgressView)
            self.downloadProgressView.setProgress(fileMessageData.progress, animated: !initialConfiguration)
        default:
            break
        }
        
        if let viewsState = state.viewsStateForAudio() {
            self.playButton.setIcon(viewsState.playButtonIcon, with: .tiny, for: .normal)
            self.playButton.backgroundColor = viewsState.playButtonBackgroundColor
            self.playButton.accessibilityValue = viewsState.playButtonIcon == .play ? "play" : "pause"
        }
        
        updateVisibleViews(allViews, visibleViews: visibleViews, animated: !loadingView.isHidden)
    }
    
    private func updateTimeLabel() {
        var duration: Int? = .none
        
        if self.isOwnTrackPlayingInAudioPlayer() {
            duration = Int(self.audioTrackPlayer().elapsedTime)
        }
        else {
            guard let message = self.message,
                let fileMessageData = message.fileMessageData else {
                return
            }
            if fileMessageData.durationMilliseconds != 0 {
                duration = Int(roundf(Float(fileMessageData.durationMilliseconds) / 1000.0))
            }
        }
        
        if let durationUnboxed = duration {
            let (seconds, minutes) = (durationUnboxed % 60, durationUnboxed / 60)
            let time = String(format: "%d:%02d", minutes, seconds)
            self.timeLabel.text = time
        }
        else {
            self.timeLabel.text = ""
        }
        self.timeLabel.accessibilityLabel = "AudioTimeLabel"
        self.timeLabel.accessibilityValue = self.timeLabel.text
    }
    
    private func updateActivePlayButton() {
        self.playButton.backgroundColor = FileMessageCellState.normalColor
        
        if self.audioTrackPlayer().isPlaying {
            self.playButton.setIcon(.pause, with: .tiny, for: UIControlState())
            self.playButton.accessibilityValue = "pause"
        }
        else {
            self.playButton.setIcon(.play, with: .tiny, for: UIControlState())
            self.playButton.accessibilityValue = "play"
        }
    }
    
    private func updateInactivePlayer() {
        self.playButton.backgroundColor = FileMessageCellState.normalColor
        self.playButton.setIcon(.play, with: .tiny, for: UIControlState())
        self.playButton.accessibilityValue = "play"

        self.playerProgressView.setProgress(0, animated: false)
        self.waveformProgressView.setProgress(0, animated: false)
    }
    
    private func updateActivePlayerProgressAnimated(_ animated: Bool) {
        let progress: Float
        var animated = animated
        
        if fabs(1 - self.audioTrackPlayer().progress) < 0.01 {
            progress = 0
            animated = false
        }
        else {
            progress = Float(self.audioTrackPlayer().progress)
        }
        
        self.playerProgressView.setProgress(progress, animated: animated)
        self.waveformProgressView.setProgress(progress, animated: animated)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        self.playButton.layer.cornerRadius = self.playButton.bounds.size.width / 2.0
    }
    
    private func audioTrackPlayer() -> AudioTrackPlayer {
        return AppDelegate.shared().mediaPlaybackManager.audioTrackPlayer
    }

    private func stopPlaying() {
        let player = audioTrackPlayer()
        let audioTrackPlayingSame = player.sourceMessage != nil && player.sourceMessage.isEqual(message)
        guard audioTrackPlayingSame else { return }
        player.pause()
    }
    
    private func playTrack() {
        guard let fileMessageData = message.fileMessageData else {
            return
        }

        self.proximityListener.stateChanged = proximityStateDidChange
        
        let audioTrackPlayer = self.audioTrackPlayer()
        let audioTrackPlayingSame = audioTrackPlayer.sourceMessage != nil && audioTrackPlayer.sourceMessage.isEqual(self.message)
        
        if let track = self.message.audioTrack() , !audioTrackPlayingSame {
            audioTrackPlayer.load(track, sourceMessage: self.message, completionHandler: { success, error in
                if success {
                    let duration = TimeInterval(Float(fileMessageData.durationMilliseconds) / 1000.0)
                    
                    Analytics.shared()?.tagPlayedAudioMessage(duration, extensionString: (fileMessageData.filename as NSString).pathExtension)
                    
                    audioTrackPlayer.play()
                }
                else {
                    DDLogWarn("Cannot load track \(track): \(error)")
                }
            })
        } else {
            if audioTrackPlayer.isPlaying {
                audioTrackPlayer.pause()
            } else {
                audioTrackPlayer.play()
            }
        }
    }
    
    func isOwnTrackPlayingInAudioPlayer() -> Bool {
        let audioTrackPlayer = self.audioTrackPlayer()
        guard let message = self.message,
            let audioTrack = message.audioTrack() else {
            return false
        }

        let audioTrackPlayingSame = audioTrackPlayer.sourceMessage != nil && audioTrackPlayer.sourceMessage.isEqual(self.message)
        return audioTrackPlayingSame && audioTrackPlayer.audioTrack.isEqual(audioTrack)
    }
    
    // MARK: - Actions
    
    open func onActionButtonPressed(_ sender: UIButton) {
        
        guard let fileMessageData = self.message.fileMessageData else { return }
        
        switch(fileMessageData.transferState) {
        case .downloading:
            self.downloadProgressView.setProgress(0, animated: false)
            self.delegate?.conversationCell?(self, didSelect: .cancel)
        case .uploading:
            if .none != fileMessageData.fileURL {
                self.delegate?.conversationCell?(self, didSelect: .cancel)
            }
        case .cancelledUpload, .failedUpload:
            if .none != fileMessageData.fileURL {
                self.delegate?.conversationCell?(self, didSelect: .resend)
            }
        case .uploaded, .failedDownload:
            self.expectingDownload = true
            ZMUserSession.shared().enqueueChanges({
                self.message.requestFileDownload()
            })

        case .downloaded:
            self.playTrack()
        }
    }
    
    // MARK: - Audio state observer
    
    func audioProgressChanged(_ change: NSDictionary) {
        if self.isOwnTrackPlayingInAudioPlayer() {
            self.updateActivePlayerProgressAnimated(false)
            self.updateTimeLabel()
        }
    }
    
    func audioPlayerStateChanged(_ change: NSDictionary) {
        if self.isOwnTrackPlayingInAudioPlayer() {
            self.updateActivePlayButton()
            self.updateActivePlayerProgressAnimated(false)
            self.updateTimeLabel()
        }
        else {
            self.updateInactivePlayer()
            self.updateTimeLabel()
        }
        
        updateProximityObserverState()
    }
    
    // MARK: - Proximity Listener
    
    func updateProximityObserverState() {
        if audioTrackPlayer().isPlaying && isOwnTrackPlayingInAudioPlayer() {
            proximityListener.startListening()
        } else {
            proximityListener.stopListening()
        }
    }
    
    func proximityStateDidChange(_ raisedToEar: Bool) {
        do {
            if raisedToEar {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
                AVSMediaManager.sharedInstance().playbackRoute = .builtIn
            } else {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                AVSMediaManager.sharedInstance().playbackRoute = .speaker
            }
        } catch {
            DDLogError("Cannot set AVAudioSession category: \(error)")
        }
    }
    
    // MARK: - Menu

    open func setSelectedByMenu(_ selected: Bool, animated: Bool) {
        
        let animation = {
            self.messageContentView.alpha = selected ? ConversationCellSelectedOpacity : 1.0;
        }
        
        if (animated) {
            UIView.animate(withDuration: ConversationCellSelectionAnimationDuration, animations: animation)
        } else {
            animation()
        }
    }
    
    open override var selectionRect: CGRect {
        return containerView.bounds
    }
    
    open override var selectionView: UIView! {
        return containerView
    }
    
    override open func menuConfigurationProperties() -> MenuConfigurationProperties! {
        let properties = MenuConfigurationProperties()
        properties.targetRect = selectionRect
        properties.targetView = selectionView
        properties.selectedMenuBlock = setSelectedByMenu
        if message.audioCanBeSaved() {
            let menuItem = UIMenuItem(title:"content.file.save_audio".localized, action:#selector(wr_saveAudio))
            properties.additionalItems = [menuItem]
        } else {
            properties.additionalItems = []
        }
        
        return properties
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(wr_saveAudio) && self.message.audioCanBeSaved() {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    open func wr_saveAudio() {
        if self.message.audioCanBeSaved() {
            self.delegate?.conversationCell?(self, didSelect: .save)
        }
    }
    
}
