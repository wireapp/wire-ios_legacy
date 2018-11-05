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
import MobileCoreServices

private let zmLog = ZMSLog(tag: "UI")

@objc public protocol AudioRecordBaseViewController: NSObjectProtocol {
    weak var delegate: AudioRecordViewControllerDelegate? { get set }
}

@objc public protocol AudioRecordViewControllerDelegate: class {
    func audioRecordViewControllerDidCancel(_ audioRecordViewController: AudioRecordBaseViewController)
    func audioRecordViewControllerDidStartRecording(_ audioRecordViewController: AudioRecordBaseViewController)
    func audioRecordViewControllerWantsToSendAudio(_ audioRecordViewController: AudioRecordBaseViewController, recordingURL: URL, duration: TimeInterval, filter: AVSAudioEffectType)
}


@objc enum AudioRecordState: UInt {
    case recording, finishedRecording
}

@objcMembers public final class AudioRecordViewController: UIViewController, AudioRecordBaseViewController {
    
    let buttonOverlay = AudioButtonOverlay()
    let topSeparator = UIView()
    let rightSeparator = UIView()
    let topTooltipLabel = UILabel()
    let timeLabel = UILabel()
    let audioPreviewView = WaveFormView()
    var accentColorChangeHandler: AccentColorChangeHandler?
    let bottomContainerView = UIView()
    let topContainerView = UIView()
    let cancelButton = IconButton()
    let recordingDotView = RecordingDotView()
    var recordingDotViewVisible: ConstraintGroup?
    var recordingDotViewHidden: ConstraintGroup?

    public let recorder = AudioRecorder(format: .wav,
                                        maxRecordingDuration: ZMUserSession.shared()?.maxAudioLength(),
                                        maxFileSize: ZMUserSession.shared()?.maxUploadFileSize())!
    
    weak public var delegate: AudioRecordViewControllerDelegate?
    
    var recordingState: AudioRecordState = .recording {
        didSet { updateRecordingState(recordingState) }
    }
    
    fileprivate let localizationBasePath = "conversation.input_bar.audio_message"
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        configureViews()
        configureAudioRecorder()
        createConstraints()

        if DeveloperMenuState.developerMenuEnabled() && Settings.shared().maxRecordingDurationDebug != 0 {
            self.recorder.maxRecordingDuration = Settings.shared().maxRecordingDurationDebug
        }
    }
    
    deinit {
        stopAndDeleteRecordingIfNeeded()
        accentColorChangeHandler = nil
    }
    
    func beginRecording() {
        self.delegate?.audioRecordViewControllerDidStartRecording(self)

        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.success)

        self.recorder.startRecording()
    }
    
    func finishRecordingIfNeeded(_ sender: UIGestureRecognizer) {
        let location = sender.location(in: buttonOverlay)
        let upperThird = location.y < buttonOverlay.frame.height / 3
        let shouldSend = upperThird && sender.state == .ended
        
        guard recorder.stopRecording() else { return zmLog.warn("Stopped recording but did not get file URL") }
        
        if shouldSend {
            sendAudio()
        }
    }
    
    func updateWithChangedRecognizer(_ sender: UIGestureRecognizer) {
        let height = buttonOverlay.frame.height
        let (topOffset, mixRange) = (height / 4, height / 2)
        let locationY = sender.location(in: buttonOverlay).y - topOffset
        let offset: CGFloat = locationY < mixRange ? 1 - locationY / mixRange : 0

        setOverlayState(.expanded(offset.clamp(0, upper: 1)), animated: false)
    }
    
    func configureViews() {
        accentColorChangeHandler = AccentColorChangeHandler.addObserver(self) { [unowned self] color, _ in
            self.audioPreviewView.color = color
        }
        
        topContainerView.backgroundColor = UIColor.from(scheme: .background)
        bottomContainerView.backgroundColor = UIColor.from(scheme: .background)
        
        topSeparator.backgroundColor = UIColor.from(scheme: .separator)
        rightSeparator.backgroundColor = UIColor.from(scheme: .separator)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(topContainerTapped))
        topContainerView.addGestureRecognizer(tapRecognizer)
        
        topContainerView.addSubview(topTooltipLabel)
        [bottomContainerView, topContainerView, buttonOverlay].forEach(view.addSubview)
        [topSeparator, rightSeparator, audioPreviewView, timeLabel, cancelButton, recordingDotView].forEach(bottomContainerView.addSubview)
        
        timeLabel.accessibilityLabel = "audioRecorderTimeLabel"
        timeLabel.font = FontSpec(.small, .none).font!
        timeLabel.textColor = UIColor.from(scheme: .textForeground)
        
        topTooltipLabel.text = "conversation.input_bar.audio_message.tooltip.pull_send".localized.uppercased()
        topTooltipLabel.accessibilityLabel = "audioRecorderTopTooltipLabel"
        topTooltipLabel.font = FontSpec(.small, .none).font!
        topTooltipLabel.textColor = UIColor.from(scheme: .textDimmed)
        
        cancelButton.setIcon(.cancel, with: .tiny, for: [])
        cancelButton.setIconColor(UIColor.from(scheme: .textForeground), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed(_:)), for: .touchUpInside)
        cancelButton.accessibilityLabel = "audioRecorderCancel"
        updateRecordingState(recordingState)
        
        
        buttonOverlay.buttonHandler = { [weak self] buttonType in
            guard let `self` = self else {
                return
            }
            switch buttonType {
            case .send: self.sendAudio()
            case .play:
               
                self.recorder.playRecording()
            case .stop: self.recorder.stopPlaying()
            }
        }
    }
    
    func createConstraints() {
        let button = buttonOverlay.audioButton
        let margin = (UIView.conversationLayoutMargins.left / 2) - (UIImage.size(for: .tiny) / 2)

        constrain(view, bottomContainerView, topContainerView, button) { view, bottomContainer, topContainer, overlayButton in
            bottomContainer.height == 56
            bottomContainer.left == view.left
            bottomContainer.right == view.right
            bottomContainer.bottom == view.bottom
            
            overlayButton.centerY == bottomContainer.centerY
            
            topContainer.left == view.left
            topContainer.top == view.top
            topContainer.right == view.right
            topContainer.bottom == bottomContainer.top
        }
        
        constrain(topContainerView, topTooltipLabel, buttonOverlay) { topContainer, topTooltip, overlay in
            topContainer.centerY == topTooltip.centerY
            topTooltip.right == overlay.left - 12
        }
        
        constrain(bottomContainerView, buttonOverlay, topSeparator) { container, overlay, separator in
            separator.height == .hairline
            separator.right == overlay.left - 8
            separator.left == container.left + 16
            separator.top == container.top
        }
        
        self.recordingDotViewHidden = constrain(bottomContainerView, timeLabel) { container, timeLabel in
            timeLabel.centerY == container.centerY
            timeLabel.left == container.left + margin
        }
        
        self.recordingDotViewHidden?.active = false
        
        self.recordingDotViewVisible = constrain(bottomContainerView, timeLabel, recordingDotView) { container, timeLabel, recordingDotView in
            
            timeLabel.centerY == container.centerY
            timeLabel.left == recordingDotView.right + 24
            
            recordingDotView.width == recordingDotView.height
            recordingDotView.width == 8
            
            recordingDotView.left == container.left + margin + 8
            recordingDotView.centerY == container.centerY
        }
        self.recordingDotViewVisible?.active = true
        
        
        constrain(bottomContainerView, buttonOverlay, rightSeparator) { container, overlay, rightSeparator in
            rightSeparator.right == container.right
            rightSeparator.left == overlay.right + 8
            rightSeparator.top == container.top
            rightSeparator.height == .hairline
        }
        
        constrain(bottomContainerView, timeLabel, audioPreviewView, cancelButton, buttonOverlay) { container, timeLabel, previewView, cancelButton, overlay in
            previewView.left == timeLabel.right + 8
            previewView.top == container.top + 12
            previewView.bottom == container.bottom - 12
            previewView.right == overlay.left - 12

            cancelButton.centerY == container.centerY
            cancelButton.right == container.right
            cancelButton.width == cancelButton.height
            cancelButton.width == 56
            overlay.right == cancelButton.left - 12
        }
    }
    
    func configureAudioRecorder() {
        recorder.recordTimerCallback = { [weak self] time in
            guard let `self` = self else { return }
            self.updateTimeLabel(time)
        }
        
        recorder.recordStartedCallback = {
            AppDelegate.shared().mediaPlaybackManager?.audioTrackPlayer.stop()
        }
        
        recorder.recordEndedCallback = { [weak self] result in
            guard let `self` = self else { return }
            self.recordingState = .finishedRecording
            
            guard let error = result.error as? RecordingError,
                let alert = self.recorder.alertForRecording(error: error) else { return }
            
            self.present(alert, animated: true, completion: .none)
        }
        
        recorder.playingStateCallback = { [weak self] state in
            guard let `self` = self else { return }
            self.buttonOverlay.playingState = state
        }
        
        recorder.recordLevelCallBack = { [weak self] level in
            guard let `self` = self else { return }
            self.audioPreviewView.updateWithLevel(CGFloat(level))
        }
    }
    
    @objc func topContainerTapped(_ sender: UITapGestureRecognizer) {
        delegate?.audioRecordViewControllerDidCancel(self)
    }
    
    func setRecordingState(_ state: AudioRecordState, animated: Bool) {
        updateRecordingState(state)
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            }) 
        }
    }
    
    func updateRecordingState(_ state: AudioRecordState) {
        
        let visible = visibleViewsForState(state)
        let allViews = Set(view.subviews.flatMap { $0.subviews }) // Well, 2 levels 'all'
        let hidden = allViews.subtracting(visible)
        
        visible.forEach { $0.isHidden = false }
        hidden.forEach { $0.isHidden = true }
        
        buttonOverlay.recordingState = state
        let finished = state == .finishedRecording
        
        self.recordingDotView.animating = !finished
        
        let pathComponent = finished ? "tooltip.tap_send" : "tooltip.pull_send"
        topTooltipLabel.text = "\(localizationBasePath).\(pathComponent)".localized.uppercased()
        
        if self.recordingState == .recording {
            self.recordingDotViewHidden?.active = false
            self.recordingDotViewVisible?.active = true
        }
        else {
            self.recordingDotViewVisible?.active = false
            self.recordingDotViewHidden?.active = true
        }
    }
    
    func updateTimeLabel(_ durationInSeconds: TimeInterval) {
        let duration = Int(floor(durationInSeconds))
        let (seconds, minutes) = (duration % 60, duration / 60)
        timeLabel.text = String(format: "%d:%02d", minutes, seconds)
        timeLabel.accessibilityValue = timeLabel.text
    }
    
    func visibleViewsForState(_ state: AudioRecordState) -> [UIView] {
        var visibleViews = [bottomContainerView, topContainerView, buttonOverlay, topSeparator, timeLabel, audioPreviewView, topTooltipLabel]
        
        switch state {
        case .finishedRecording:
            visibleViews.append(cancelButton)
        case .recording:
            visibleViews.append(recordingDotView)
        }
        
        if traitCollection.userInterfaceIdiom == .pad { visibleViews.append(rightSeparator) }
        
        return visibleViews
    }
    
    func setOverlayState(_ state: AudioButtonOverlayState, animated: Bool) {
        let animations = { self.buttonOverlay.setOverlayState(state) }

        if state.animatable && animated {
            UIView.animate(
                withDuration: state.duration,
                delay: 0,
                usingSpringWithDamping: state.springDampening,
                initialSpringVelocity: state.springVelocity,
                options: .curveEaseOut,
                animations: animations,
                completion: nil
            )
        } else {
            animations()
        }
    }
    
    @objc func cancelButtonPressed(_ sender: IconButton) {        
        recorder.stopPlaying()
        stopAndDeleteRecordingIfNeeded()
        delegate?.audioRecordViewControllerDidCancel(self)
        updateTimeLabel(0)
    }
    
    func stopAndDeleteRecordingIfNeeded() {
        recorder.stopRecording()
        recorder.deleteRecording()
    }
    
    func sendAudio() {
        recorder.stopPlaying()
        guard let url = recorder.fileURL else { return zmLog.warn("Nil url passed to send as audio file") }
        
        
        let effectPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("effect.wav")
        effectPath.deleteFileAtPath()
        // To apply noize reduction filter
        AVSAudioEffectType.none.apply(url.path, outPath: effectPath) {
            url.path.deleteFileAtPath()
            
            let filename = String.filenameForSelfUser().appendingPathExtension("m4a")!
            let convertedPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(filename)
            convertedPath.deleteFileAtPath()
            
            AVAsset.wr_convertAudioToUploadFormat(effectPath, outPath: convertedPath) { success in
                effectPath.deleteFileAtPath()
                
                if success {
                    self.delegate?.audioRecordViewControllerWantsToSendAudio(self, recordingURL: NSURL(fileURLWithPath: convertedPath) as URL, duration: self.recorder.currentDuration, filter: .none)
                }
            }
        }
        
    }

}
