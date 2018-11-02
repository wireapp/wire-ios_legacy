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

private let zmLog = ZMSLog(tag: "UI")

@objcMembers final public class AudioRecordKeyboardViewController: UIViewController, AudioRecordBaseViewController {
    enum State {
        case ready, recording, effects
    }
    
    fileprivate let topContainer = UIView()
    fileprivate let topSeparator = UIView()
    fileprivate let bottomToolbar = UIView()
    
    fileprivate let tipLabel = UILabel()
    fileprivate var recordTapGestureRecognizer: UITapGestureRecognizer!
    internal let recordButton = IconButton()
    internal let stopRecordButton = IconButton()
    
    fileprivate let audioPreviewView = WaveFormView()
    fileprivate let timeLabel = UILabel()
    
    internal let confirmButton = IconButton()
    internal let redoButton = IconButton()
    internal let cancelButton = IconButton()
    
    fileprivate var accentColorChangeHandler: AccentColorChangeHandler?
    fileprivate var effectPickerViewController: AudioEffectsPickerViewController?
    
    fileprivate var currentEffect: AVSAudioEffectType = .none
    fileprivate var currentEffectFilePath: String?
    
    fileprivate(set) var state: State = .ready {
        didSet {
            if oldValue != state {
                updateRecordingState(self.state)
            }
        }
    }
    public let recorder: AudioRecorderType
    public weak var delegate: AudioRecordViewControllerDelegate?
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc convenience init() {
        self.init(audioRecorder: AudioRecorder(format: .wav,
                                               maxRecordingDuration: ZMUserSession.shared()?.maxAudioLength() ,
                                               maxFileSize: ZMUserSession.shared()?.maxUploadFileSize() )!)
    }
    
    init(audioRecorder: AudioRecorderType) {
        self.recorder = audioRecorder
        super.init(nibName: nil, bundle: nil)
        configureViews()
        configureAudioRecorder()
        createConstraints()
        
        if DeveloperMenuState.developerMenuEnabled() && Settings.shared().maxRecordingDurationDebug != 0 {
            self.recorder.maxRecordingDuration = Settings.shared().maxRecordingDurationDebug
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if AppLock.isActive {
            UIApplication.shared.keyWindow?.endEditing(true)
        }
    }
    
    func configureViews() {
        
        let colorScheme = ColorScheme()
        colorScheme.variant = .light
        
        self.view.backgroundColor = colorScheme.color(named: .textForeground)
        
        self.recordTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(recordButtonPressed(_:)))
        self.view.addGestureRecognizer(self.recordTapGestureRecognizer)
        
        self.accentColorChangeHandler = AccentColorChangeHandler.addObserver(self) { [unowned self] color, _ in
            self.audioPreviewView.color = color
        }
        
        [self.audioPreviewView, self.timeLabel, self.tipLabel, self.recordButton, self.stopRecordButton, self.confirmButton, self.redoButton, self.cancelButton, self.bottomToolbar, self.topContainer, self.topSeparator].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        self.audioPreviewView.gradientWidth = 20
        self.audioPreviewView.gradientColor = colorScheme.color(named: .textForeground)
        
        self.topSeparator.backgroundColor = colorScheme.color(named: .separator)
        
        self.createTipLabel()
        
        self.timeLabel.font = FontSpec(.small, .light).font!
        self.timeLabel.textColor = colorScheme.color(named: .textForeground, variant: .dark)
        
        [self.audioPreviewView, self.timeLabel, self.tipLabel].forEach(self.topContainer.addSubview)
        
        self.recordButton.setIcon(.recordDot, with: .tiny, for: [])
        self.recordButton.accessibilityLabel = "record"
        self.recordButton.addTarget(self, action: #selector(recordButtonPressed(_:)), for: .touchUpInside)
        self.recordButton.setBackgroundImageColor(.vividRed, for: .normal)
        self.recordButton.setIconColor(UIColor.white, for: [])
        self.recordButton.layer.masksToBounds = true
        
        self.stopRecordButton.setIcon(.stopRecording, with: .tiny, for: [])
        self.stopRecordButton.accessibilityLabel = "stopRecording"
        self.stopRecordButton.addTarget(self, action: #selector(stopRecordButtonPressed(_:)), for: .touchUpInside)
        self.stopRecordButton.setBackgroundImageColor(.vividRed, for: .normal)
        self.stopRecordButton.setIconColor(UIColor.white, for: [])
        self.stopRecordButton.layer.masksToBounds = true
        
        self.confirmButton.setIcon(.checkmark, with: .tiny, for: [])
        self.confirmButton.accessibilityLabel = "confirmRecording"
        self.confirmButton.addTarget(self, action: #selector(confirmButtonPressed(_:)), for: .touchUpInside)
        self.confirmButton.setBackgroundImageColor(.strongLimeGreen, for: .normal)
        self.confirmButton.setIconColor(UIColor.white, for: [])
        self.confirmButton.layer.masksToBounds = true
        
        self.redoButton.setIcon(.undo, with: .tiny, for: [])
        self.redoButton.accessibilityLabel = "redoRecording"
        self.redoButton.addTarget(self, action: #selector(redoButtonPressed(_:)), for: .touchUpInside)
        self.redoButton.setIconColor(UIColor.white, for: [])
        
        self.cancelButton.setIcon(.cancel, with: .tiny, for: [])
        self.cancelButton.accessibilityLabel = "cancelRecording"
        self.cancelButton.addTarget(self, action: #selector(cancelButtonPressed(_:)), for: .touchUpInside)
        self.cancelButton.setIconColor(UIColor.white, for: [])
        
        [self.recordButton, self.stopRecordButton, self.confirmButton, self.redoButton, self.cancelButton].forEach(self.bottomToolbar.addSubview)
        
        [self.bottomToolbar, self.topContainer, self.topSeparator].forEach(self.view.addSubview)
        
        self.timeLabel.accessibilityLabel = "recordingTime"
        
        updateRecordingState(self.state)
    }
    
    func createTipLabel() {
        let colorScheme = ColorScheme()
        colorScheme.variant = .light
        
        let tipText = "conversation.input_bar.audio_message.keyboard.record_tip".localized.uppercased()
        let attributedTipText = NSMutableAttributedString(string: tipText)
        let atRange = (tipText as NSString).range(of: "%@")
        
        if atRange.location != NSNotFound {
            let suitableEffects = AVSAudioEffectType.displayedEffects.filter {
                $0 != .none
            }
            
            let maxEffect : UInt32 = UInt32(suitableEffects.count)
            let randomEffect = suitableEffects[Int(arc4random_uniform(maxEffect))]
            let randomEffectImage = UIImage(for: randomEffect.icon, iconSize: .searchBar, color: colorScheme.color(named: .textDimmed))
            
            let tipEffectImageAttachment = NSTextAttachment()
            tipEffectImageAttachment.image = randomEffectImage
            
            let tipEffectImage = NSAttributedString(attachment: tipEffectImageAttachment)
            
            attributedTipText.replaceCharacters(in: atRange, with: tipEffectImage)
        }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 8
        
        attributedTipText.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, (attributedTipText.string as NSString).length))
        self.tipLabel.attributedText = NSAttributedString(attributedString: attributedTipText)
        self.tipLabel.numberOfLines = 2
        self.tipLabel.font = FontSpec(.small, .light).font!
        self.tipLabel.textColor = colorScheme.color(named: .textDimmed)
        self.tipLabel.textAlignment = .center
        
    }
    
    func createConstraints() {
        
        constrain(self.view, self.topContainer, self.bottomToolbar, self.topSeparator) { view, topContainer, bottomToolbar, topSeparator in
            topContainer.left >= view.left + 16
            topContainer.top >= view.top + 16
            topContainer.right <= view.right - 16
            
            topContainer.left == view.left + 16 ~ 750.0
            topContainer.top == view.top + 16 ~ 750.0
            topContainer.right == view.right - 16 ~ 750.0
            
            topContainer.width <= 400
            topContainer.centerX == view.centerX
            
            bottomToolbar.top == topContainer.bottom
            bottomToolbar.left == topContainer.left
            bottomToolbar.bottom == view.bottom - UIScreen.safeArea.bottom
            bottomToolbar.right == topContainer.right
            bottomToolbar.height == 72
            bottomToolbar.centerX == topContainer.centerX
            
            topSeparator.height == .hairline
            topSeparator.top == view.top
            topSeparator.left == view.left
            topSeparator.right == view.right
        }
        
        constrain(self.topContainer, self.audioPreviewView, self.timeLabel, self.tipLabel, self.stopRecordButton) { topContainer, audioPreviewView, timeLabel, tipLabel, stopRecordButton in
            
            audioPreviewView.top == topContainer.top + 20
            audioPreviewView.left == topContainer.left + 8
            audioPreviewView.right == topContainer.right - 8
            audioPreviewView.height == 100
            
            timeLabel.centerX == topContainer.centerX
            timeLabel.bottom == stopRecordButton.top - 16
            
            tipLabel.center == topContainer.center
        }
        
        constrain(self.bottomToolbar, self.recordButton, self.stopRecordButton) { bottomToolbar, recordButton, stopRecordButton in
            
            recordButton.center == bottomToolbar.center
            recordButton.width == recordButton.height
            recordButton.height == 40
            
            stopRecordButton.center == bottomToolbar.center
            stopRecordButton.width == stopRecordButton.height
            stopRecordButton.height == 40
        }
        
        constrain(self.bottomToolbar, self.redoButton, self.confirmButton, self.cancelButton) { bottomToolbar, redoButton, confirmButton, cancelButton in
            confirmButton.center == bottomToolbar.center
            confirmButton.width == confirmButton.height
            confirmButton.height == 40
            
            redoButton.centerY == bottomToolbar.centerY
            redoButton.left == bottomToolbar.left + 8
            
            cancelButton.centerY == bottomToolbar.centerY
            cancelButton.right == bottomToolbar.right - 8
        }
    }
    
    var isRecording: Bool {
        return self.recorder.state == .recording
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.confirmButton.layer.cornerRadius = self.confirmButton.bounds.size.width / 2
        self.recordButton.layer.cornerRadius = self.recordButton.bounds.size.width / 2
        self.stopRecordButton.layer.cornerRadius = self.stopRecordButton.bounds.size.width / 2
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
            self.state = .effects
            
            guard let error = result.error as? RecordingError,
                let alert = self.recorder.alertForRecording(error: error) else { return }
            
            self.present(alert, animated: true, completion: .none)
        }
        
        recorder.recordLevelCallBack = { [weak self] level in
            guard let `self` = self else { return }
            self.audioPreviewView.updateWithLevel(CGFloat(level))
        }
    }
    
    func updateTimeLabel(_ durationInSeconds: TimeInterval) {
        let duration = Int(floor(durationInSeconds))
        let (seconds, minutes) = (duration % 60, duration / 60)
        timeLabel.text = String(format: "%d:%02d", minutes, seconds)
        timeLabel.accessibilityValue = timeLabel.text
    }
    
    fileprivate func visibleViews(forState: State) -> [UIView] {
        var result = [self.topSeparator, self.topContainer, self.bottomToolbar]
        switch state {
        case .ready:
            result.append(contentsOf: [self.tipLabel, self.recordButton])
        case .recording:
            result.append(contentsOf: [self.audioPreviewView, self.timeLabel, self.stopRecordButton])
        case .effects:
            result.append(contentsOf: [self.redoButton, self.confirmButton, self.cancelButton])
        }
        
        return result
    }
    
    fileprivate func updateRecordingState(_ state: State) {
        let visibleViews = self.visibleViews(forState: state)
        let allViews = Set(view.subviews.flatMap { $0.subviews })
        let hiddenViews = allViews.subtracting(visibleViews)
        
        visibleViews.forEach { $0.isHidden = false }
        hiddenViews.forEach { $0.isHidden = true }
        
        switch state {
        case .ready:
            self.closeEffectsPicker(animated: false)
            self.recordTapGestureRecognizer.isEnabled = true
            updateTimeLabel(0)
        case .recording:
            self.closeEffectsPicker(animated: false)
            self.recordTapGestureRecognizer.isEnabled = false
        case .effects:
            self.openEffectsPicker()
            self.recordTapGestureRecognizer.isEnabled = false
        }
    }
    
    func stopAndDeleteRecordingIfNeeded() {
        recorder.stopRecording()
        recorder.deleteRecording()
    }
    
    func sendAudioAsIs() {
        recorder.stopPlaying()
        guard let url = recorder.fileURL else { return zmLog.warn("Nil url passed to send as audio file") }
        
        delegate?.audioRecordViewControllerWantsToSendAudio(self, recordingURL: url, duration: recorder.currentDuration, filter: .none)
    }
    
    fileprivate func openEffectsPicker() {
        guard let url = recorder.fileURL else { return zmLog.warn("Nil url passed to add effect to audio file") }
        
        let noizeReducePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("noize-reduce.wav")
        noizeReducePath.deleteFileAtPath()
        // To apply noize reduction filter
        AVSAudioEffectType.none.apply(url.path, outPath: noizeReducePath) {
            self.currentEffectFilePath = noizeReducePath
            url.path.deleteFileAtPath()
            
            if self.effectPickerViewController != .none {
                self.closeEffectsPicker(animated: false)
            }
            
            let newEffectPickerViewController = AudioEffectsPickerViewController(recordingPath: noizeReducePath, duration: self.recorder.currentDuration)
            newEffectPickerViewController.delegate = self
            self.addChild(newEffectPickerViewController)
            newEffectPickerViewController.view.alpha = 0
            
            UIView.transition(with: self.view, duration: 0.35, options: [.curveEaseIn], animations: {
                newEffectPickerViewController.view.translatesAutoresizingMaskIntoConstraints = false
                self.topContainer.addSubview(newEffectPickerViewController.view)
                constrain(self.topContainer, newEffectPickerViewController.view) { topContainer, newControllerView in
                    topContainer.edges == newControllerView.edges
                }
                newEffectPickerViewController.view.alpha = 1
            }) { _ in
                newEffectPickerViewController.didMove(toParent: self)
            }
            
            self.effectPickerViewController = newEffectPickerViewController
        }
    }
    
    fileprivate func closeEffectsPicker(animated: Bool) {
        if let picker = self.effectPickerViewController {
            picker.willMove(toParent: nil)
            picker.removeFromParent()
            self.effectPickerViewController = .none
        }
    }
    
    // MARK: - Button actions
    
    @objc internal func recordButtonPressed(_ sender: AnyObject!) {
        self.state = .recording
        self.recorder.startRecording()
        self.delegate?.audioRecordViewControllerDidStartRecording(self)
    }
    
    @objc func stopRecordButtonPressed(_ button: UIButton?) {
        self.recorder.stopRecording()
    }
    
    @objc func confirmButtonPressed(_ button: UIButton?) {
        
        guard let audioPath = self.currentEffectFilePath else {
            zmLog.error("No file to send")
            return
        }
        
        button?.isEnabled = false
        
        let effectName: String
        
        if self.currentEffect == .none {
            effectName = "Original"
        }
        else {
            effectName = self.currentEffect.description
        }
        
        let filename = String.filenameForSelfUser(suffix: "-" + effectName).appendingPathExtension("m4a")!
        let convertedPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(filename)
        convertedPath.deleteFileAtPath()
        
        AVAsset.wr_convertAudioToUploadFormat(audioPath, outPath: convertedPath) { (success) in
            if success {
                audioPath.deleteFileAtPath()
                self.delegate?.audioRecordViewControllerWantsToSendAudio(self, recordingURL: URL(fileURLWithPath: convertedPath), duration: self.recorder.currentDuration, filter: self.currentEffect)
            }
        }
    }
    
    @objc func redoButtonPressed(_ button: UIButton?) {
        self.state = .ready
    }
    
    @objc func cancelButtonPressed(_ button: UIButton?) {
        self.delegate?.audioRecordViewControllerDidCancel(self)
    }
}

extension AudioRecordKeyboardViewController: AudioEffectsPickerDelegate {
    public func audioEffectsPickerDidPickEffect(_ picker: AudioEffectsPickerViewController, effect: AVSAudioEffectType, resultFilePath: String) {
        self.currentEffectFilePath = resultFilePath
        self.currentEffect = effect
    }
}

