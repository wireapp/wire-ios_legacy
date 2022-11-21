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
import UIKit
import WireSystem
import WireSyncEngine
import avs
import WireCommonComponents

private let zmLog = ZMSLog(tag: "UI")

final class AudioRecordKeyboardViewController: UIViewController, AudioRecordBaseViewController {

    enum State {
        case ready, recording, effects
    }

    // MARK: - Properties

    private(set) var state: State = .ready {
        didSet { if oldValue != state { updateRecordingState(self.state) }}
    }

    var isRecording: Bool {
        switch self.recorder.state {
        case .recording:
            return true
        default:
            return false
        }
    }

    let recorder: AudioRecorderType
    weak var delegate: AudioRecordViewControllerDelegate?

    let recordButton = IconButton()
    let stopRecordButton = IconButton()
    let confirmButton = IconButton()
    let redoButton = IconButton()
    let cancelButton = IconButton()

    private let topContainer = UIView()
    private let topSeparator = UIView()
    private let bottomToolbar = UIView()

    private let tipLabel = UILabel()
    private let timeLabel = UILabel()
    private let audioPreviewView = WaveFormView()
    private var recordTapGestureRecognizer: UITapGestureRecognizer!

    private var accentColorChangeHandler: AccentColorChangeHandler?
    private var effectPickerViewController: AudioEffectsPickerViewController?

    private var currentEffect: AVSAudioEffectType = .none
    private var currentEffectFilePath: String?

    private var appLock: AppLockType? {
        return ZMUserSession.shared()?.appLockController
    }

    private var isAppLockActive: Bool {
        return appLock?.isActive ?? false
    }
    // MARK: - Life Cycle

    convenience init() {
        self.init(audioRecorder: AudioRecorder(
            format: .wav,
            maxRecordingDuration: ZMUserSession.shared()?.maxAudioLength,
            maxFileSize: ZMUserSession.shared()?.maxUploadFileSize))
    }

    init(audioRecorder: AudioRecorderType) {
        self.recorder = audioRecorder
        super.init(nibName: nil, bundle: nil)
        configureViews()
        configureAudioRecorder()
        createConstraints()

        if Bundle.developerModeEnabled && Settings.shared.maxRecordingDurationDebug != 0 {
            self.recorder.maxRecordingDuration = Settings.shared.maxRecordingDurationDebug
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        recorder.stopRecording()
        if isAppLockActive { UIApplication.shared.firstKeyWindow?.endEditing(true) }
    }

    // MARK: - View Configuration

    func configureViews() {
        let backgroundColor = UIColor.from(scheme: .textForeground, variant: .light)
        let textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        let separatorColor = UIColor.from(scheme: .separator, variant: .light)

        self.view.backgroundColor = backgroundColor

        self.recordTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(recordButtonPressed))
        self.view.addGestureRecognizer(self.recordTapGestureRecognizer)

        self.audioPreviewView.gradientWidth = 20
        self.audioPreviewView.gradientColor = backgroundColor

        self.accentColorChangeHandler = AccentColorChangeHandler.addObserver(self) { [unowned self] color, _ in
            if let color = color {
                self.audioPreviewView.color = color
            }
        }

        self.timeLabel.font = FontSpec(.small, .light).font!
        self.timeLabel.textColor = textColor
        self.timeLabel.accessibilityLabel = "recordingTime"

        self.createTipLabel()

        [self.audioPreviewView, self.timeLabel, self.tipLabel].forEach(self.topContainer.addSubview)

        createButtons()

        [self.recordButton,
         self.stopRecordButton,
         self.confirmButton,
         self.redoButton,
         self.cancelButton].forEach(self.bottomToolbar.addSubview)

        self.topSeparator.backgroundColor = separatorColor

        [self.bottomToolbar, self.topContainer, self.topSeparator].forEach(self.view.addSubview)
        updateRecordingState(self.state)
    }

    private func createTipLabel() {
        let color = UIColor.from(scheme: .textDimmed, variant: .light)
        let text = "conversation.input_bar.audio_message.keyboard.record_tip".localized(uppercased: true)
        let attrText = NSMutableAttributedString(string: text)
        let atRange = (text as NSString).range(of: "%@")

        // insert random effect icon
        if atRange.location != NSNotFound {
            let effects = AVSAudioEffectType.displayedEffects.filter { $0 != .none }
            let max = UInt32(effects.count)
            let effect = effects[Int.random(in: 0..<Int(max))]
            let image = effect.icon.makeImage(size: 14, color: color)

            let attachment = NSTextAttachment()
            attachment.image = image

            attrText.replaceCharacters(in: atRange, with: NSAttributedString(attachment: attachment))
        }

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 8

        attrText.addAttribute(.paragraphStyle, value: style, range: attrText.wholeRange)
        self.tipLabel.attributedText = NSAttributedString(attributedString: attrText)
        self.tipLabel.numberOfLines = 2
        self.tipLabel.font = FontSpec(.small, .light).font!
        self.tipLabel.textColor = color
        self.tipLabel.textAlignment = .center
    }

    private func createButtons() {
        self.recordButton.setIcon(.recordDot, size: .tiny, for: [])
        self.recordButton.setIconColor(.white, for: [])
        self.recordButton.addTarget(self, action: #selector(recordButtonPressed), for: .touchUpInside)
        self.recordButton.setBackgroundImageColor(SemanticColors.LegacyColors.vividRed, for: .normal)
        self.recordButton.layer.masksToBounds = true
        self.recordButton.accessibilityLabel = "record"

        self.stopRecordButton.setIcon(.stopRecording, size: .tiny, for: [])
        self.stopRecordButton.setIconColor(.white, for: [])
        self.stopRecordButton.addTarget(self, action: #selector(stopRecordButtonPressed), for: .touchUpInside)
        self.stopRecordButton.setBackgroundImageColor(SemanticColors.LegacyColors.vividRed, for: .normal)
        self.stopRecordButton.layer.masksToBounds = true
        self.stopRecordButton.accessibilityLabel = "stopRecording"

        self.confirmButton.setIcon(.checkmark, size: .tiny, for: [])
        self.confirmButton.setIconColor(.white, for: [])
        self.confirmButton.addTarget(self, action: #selector(confirmButtonPressed), for: .touchUpInside)
        self.confirmButton.setBackgroundImageColor(SemanticColors.LegacyColors.strongLimeGreen, for: .normal)
        self.confirmButton.layer.masksToBounds = true
        self.confirmButton.accessibilityLabel = "confirmRecording"

        self.redoButton.setIcon(.undo, size: .tiny, for: [])
        self.redoButton.setIconColor(.white, for: [])
        self.redoButton.addTarget(self, action: #selector(redoButtonPressed), for: .touchUpInside)
        self.redoButton.accessibilityLabel = "redoRecording"

        self.cancelButton.setIcon(.cross, size: .tiny, for: [])
        self.cancelButton.setIconColor(.white, for: [])
        self.cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        self.cancelButton.accessibilityLabel = "cancelRecording"
    }

    private func createConstraints() {
        [self.audioPreviewView,
         self.timeLabel,
         self.tipLabel,
         self.recordButton,
         self.stopRecordButton,
         self.confirmButton,
         self.redoButton,
         self.cancelButton,
         self.bottomToolbar,
         self.topContainer,
         self.topSeparator
        ].prepareForLayout()

        NSLayoutConstraint.activate([
            topContainer.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            topContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            topContainer.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            topContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            topContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            bottomToolbar.topAnchor.constraint(equalTo: topContainer.bottomAnchor),
            bottomToolbar.leftAnchor.constraint(equalTo: topContainer.leftAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIScreen.safeArea.bottom),
            bottomToolbar.rightAnchor.constraint(equalTo: topContainer.rightAnchor),
            bottomToolbar.heightAnchor.constraint(equalToConstant: 72),
            bottomToolbar.centerXAnchor.constraint(equalTo: topContainer.centerXAnchor),

            topSeparator.heightAnchor.constraint(equalToConstant: .hairline),
            topSeparator.topAnchor.constraint(equalTo: view.topAnchor),
            topSeparator.leftAnchor.constraint(equalTo: view.leftAnchor),
            topSeparator.rightAnchor.constraint(equalTo: view.rightAnchor),

            audioPreviewView.topAnchor.constraint(equalTo: topContainer.topAnchor, constant: 20),
            audioPreviewView.leftAnchor.constraint(equalTo: topContainer.leftAnchor, constant: 8),
            audioPreviewView.rightAnchor.constraint(equalTo: topContainer.rightAnchor, constant: -8),
            audioPreviewView.heightAnchor.constraint(equalToConstant: 100),

            timeLabel.centerXAnchor.constraint(equalTo: topContainer.centerXAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: stopRecordButton.topAnchor, constant: -16),

            tipLabel.centerXAnchor.constraint(equalTo: topContainer.centerXAnchor),
            tipLabel.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor),

            recordButton.centerXAnchor.constraint(equalTo: bottomToolbar.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            recordButton.heightAnchor.constraint(equalToConstant: 40),
            recordButton.widthAnchor.constraint(equalTo: recordButton.heightAnchor),

            stopRecordButton.centerXAnchor.constraint(equalTo: bottomToolbar.centerXAnchor),
            stopRecordButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            stopRecordButton.heightAnchor.constraint(equalToConstant: 40),
            stopRecordButton.widthAnchor.constraint(equalTo: stopRecordButton.heightAnchor),

            confirmButton.centerXAnchor.constraint(equalTo: bottomToolbar.centerXAnchor),
            confirmButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            confirmButton.heightAnchor.constraint(equalToConstant: 40),
            confirmButton.widthAnchor.constraint(equalTo: confirmButton.heightAnchor),

            redoButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            redoButton.leftAnchor.constraint(equalTo: bottomToolbar.leftAnchor, constant: 8),

            cancelButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            cancelButton.rightAnchor.constraint(equalTo: bottomToolbar.rightAnchor, constant: -8)
        ])
    }

    // MARK: - View Updates

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.confirmButton.layer.cornerRadius = self.confirmButton.bounds.size.width / 2
        self.recordButton.layer.cornerRadius = self.recordButton.bounds.size.width / 2
        self.stopRecordButton.layer.cornerRadius = self.stopRecordButton.bounds.size.width / 2
    }

    func updateTimeLabel(_ durationInSeconds: TimeInterval) {
        let duration = Int(floor(durationInSeconds))
        let (seconds, minutes) = (duration % 60, duration / 60)
        timeLabel.text = String(format: "%d:%02d", minutes, seconds)
        timeLabel.accessibilityValue = timeLabel.text
    }

    private func visibleViews(forState: State) -> [UIView] {
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

    // MARK: - Recording

    func configureAudioRecorder() {
        recorder.recordTimerCallback = { [weak self] time in
            guard let `self` = self else { return }
            self.updateTimeLabel(time)
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
            self.audioPreviewView.updateWithLevel(level)
        }
    }

    private func updateRecordingState(_ state: State) {
        let allViews = Set(view.subviews.flatMap { $0.subviews })
        let visibleViews = self.visibleViews(forState: state)
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

    private func openEffectsPicker() {
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

            let picker = AudioEffectsPickerViewController(recordingPath: noizeReducePath, duration: self.recorder.currentDuration)
            self.addChild(picker)
            picker.delegate = self
            picker.view.alpha = 0

            let changes: () -> Void = {
                picker.view.translatesAutoresizingMaskIntoConstraints = false
                self.topContainer.addSubview(picker.view)
                picker.view.fitIn(view: self.topContainer)
                picker.view.alpha = 1
            }

            UIView.transition(
                with: self.view,
                duration: 0.35,
                options: [.curveEaseIn],
                animations: changes,
                completion: { _ in picker.didMove(toParent: self)}
            )

            self.effectPickerViewController = picker
        }
    }

    private func closeEffectsPicker(animated: Bool) {
        if let picker = self.effectPickerViewController {
            picker.willMove(toParent: nil)
            picker.removeFromParent()
            self.effectPickerViewController = .none
        }
    }

    // MARK: - Button Actions

    @objc func recordButtonPressed(_ sender: AnyObject!) {
        self.recorder.startRecording { _ in
            self.state = .recording
            self.delegate?.audioRecordViewControllerDidStartRecording(self)
            AppDelegate.shared.mediaPlaybackManager?.audioTrackPlayer.stop()
        }
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

        let effectName = self.currentEffect == .none ? "Original" : self.currentEffect.description

        let filename = String.filenameForSelfUser(suffix: "-" + effectName).appendingPathExtension("m4a")!
        let convertedPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(filename)
        convertedPath.deleteFileAtPath()

        AVAsset.convertAudioToUploadFormat(audioPath, outPath: convertedPath) { success in
            if success {
                audioPath.deleteFileAtPath()
                self.delegate?.audioRecordViewControllerWantsToSendAudio(
                    self,
                    recordingURL: URL(fileURLWithPath: convertedPath),
                    duration: self.recorder.currentDuration,
                    filter: self.currentEffect
                )
            }
        }
    }

    @objc func redoButtonPressed(_ button: UIButton?) {
        recorder.deleteRecording()
        self.state = .ready
    }

    @objc func cancelButtonPressed(_ button: UIButton?) {
        self.delegate?.audioRecordViewControllerDidCancel(self)
    }
}

// MARK: - AudioEffectsPickerDelegate

extension AudioRecordKeyboardViewController: AudioEffectsPickerDelegate {
    public func audioEffectsPickerDidPickEffect(_ picker: AudioEffectsPickerViewController, effect: AVSAudioEffectType, resultFilePath: String) {
        self.currentEffectFilePath = resultFilePath
        self.currentEffect = effect
    }
}
