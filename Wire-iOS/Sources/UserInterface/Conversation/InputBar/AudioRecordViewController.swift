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
import MobileCoreServices
import UIKit
import WireSystem
import avs
import WireSyncEngine
import WireCommonComponents

private let zmLog = ZMSLog(tag: "UI")

protocol AudioRecordBaseViewController: AnyObject {
    var delegate: AudioRecordViewControllerDelegate? { get set }
}

protocol AudioRecordViewControllerDelegate: AnyObject {
    func audioRecordViewControllerDidCancel(_ audioRecordViewController: AudioRecordBaseViewController)
    func audioRecordViewControllerDidStartRecording(_ audioRecordViewController: AudioRecordBaseViewController)
    func audioRecordViewControllerWantsToSendAudio(_ audioRecordViewController: AudioRecordBaseViewController, recordingURL: URL, duration: TimeInterval, filter: AVSAudioEffectType)
}

enum AudioRecordState {
    case recording, finishedRecording
}

final class AudioRecordViewController: UIViewController, AudioRecordBaseViewController {

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
    var recordingDotViewVisible: [NSLayoutConstraint] = []
    var recordingDotViewHidden: [NSLayoutConstraint] = []
    public let recorder: AudioRecorderType
    weak public var delegate: AudioRecordViewControllerDelegate?

    var recordingState: AudioRecordState = .recording {
        didSet { updateRecordingState(recordingState) }
    }

    fileprivate let localizationBasePath = "conversation.input_bar.audio_message"

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(audioRecorder: AudioRecorderType? = nil) {
        let maxAudioLength = ZMUserSession.shared()?.maxAudioLength
        let maxUploadSize = ZMUserSession.shared()?.maxUploadFileSize
        self.recorder = audioRecorder ?? AudioRecorder(format: .wav, maxRecordingDuration: maxAudioLength, maxFileSize: maxUploadSize)

        super.init(nibName: nil, bundle: nil)

        configureViews()
        configureAudioRecorder()
        createConstraints()

        updateRecordingState(recordingState)

        if Bundle.developerModeEnabled && Settings.shared.maxRecordingDurationDebug != 0 {
            self.recorder.maxRecordingDuration = Settings.shared.maxRecordingDurationDebug
        }
    }

    deinit {
        stopAndDeleteRecordingIfNeeded()
        accentColorChangeHandler = nil
    }

    func beginRecording() {
        self.recorder.startRecording { (success) in
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.notificationOccurred(.success)
            AppDelegate.shared.mediaPlaybackManager?.audioTrackPlayer.stop()

            self.delegate?.audioRecordViewControllerDidStartRecording(self)
        }
    }

    func finishRecordingIfNeeded(_ sender: UIGestureRecognizer) {
        guard recorder.state != .initializing else {
            recorder.stopRecording()
            self.delegate?.audioRecordViewControllerDidCancel(self)
            return
        }

        let location = sender.location(in: buttonOverlay)
        let upperThird = location.y < buttonOverlay.frame.height / 3
        let shouldSend = upperThird && sender.state == .ended

        guard recorder.stopRecording() else {
            return zmLog.warn("Stopped recording but did not get file URL")
        }

        if shouldSend {
            sendAudio()
        }

        setOverlayState(.default, animated: true)
        setRecordingState(.finishedRecording, animated: true)
    }

    func updateWithChangedRecognizer(_ sender: UIGestureRecognizer) {
        let height = buttonOverlay.frame.height
        let (topOffset, mixRange) = (height / 4, height / 2)
        let locationY = sender.location(in: buttonOverlay).y - topOffset
        let offset: CGFloat = locationY < mixRange ? 1 - locationY / mixRange : 0

        setOverlayState(.expanded(offset.clamp(0, upper: 1)), animated: false)
    }

    private func configureViews() {
        accentColorChangeHandler = AccentColorChangeHandler.addObserver(self) { [unowned self] color, _ in
            if let color = color {
                self.audioPreviewView.color = color
            }
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

        topTooltipLabel.text = "conversation.input_bar.audio_message.tooltip.pull_send".localized(uppercased: true)
        topTooltipLabel.accessibilityLabel = "audioRecorderTopTooltipLabel"
        topTooltipLabel.font = FontSpec(.small, .none).font!
        topTooltipLabel.textColor = UIColor.from(scheme: .textDimmed)

        cancelButton.setIcon(.cross, size: .tiny, for: [])
        cancelButton.setIconColor(UIColor.from(scheme: .textForeground), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed(_:)), for: .touchUpInside)
        cancelButton.accessibilityLabel = "audioRecorderCancel"

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

    private func createConstraints() {
        let button = buttonOverlay.audioButton
        let margin: CGFloat = (conversationHorizontalMargins.left / 2) - (StyleKitIcon.Size.tiny.rawValue / 2)

        [bottomContainerView,
         topContainerView,
         button,
         topTooltipLabel,
         buttonOverlay,
         topSeparator,
         timeLabel,
         recordingDotView,
         audioPreviewView,
         cancelButton,
         rightSeparator].prepareForLayout()

        var constraints: [NSLayoutConstraint] = []

        constraints.append(bottomContainerView.heightAnchor.constraint(equalToConstant: 56))

        constraints.append(contentsOf: [bottomContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                        bottomContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                        bottomContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])

        constraints.append(button.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor))

        constraints.append(contentsOf: [topContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                        topContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                        topContainerView.topAnchor.constraint(equalTo: view.topAnchor)])

        constraints.append(contentsOf: [topContainerView.bottomAnchor.constraint(equalTo: bottomContainerView.topAnchor),

                                        topContainerView.centerYAnchor.constraint(equalTo: topTooltipLabel.centerYAnchor),
                                        topTooltipLabel.rightAnchor.constraint(equalTo: buttonOverlay.leftAnchor, constant: -12),

                                        topSeparator.heightAnchor.constraint(equalToConstant: .hairline),
                                        topSeparator.rightAnchor.constraint(equalTo: buttonOverlay.leftAnchor, constant: -8),
                                        topSeparator.leftAnchor.constraint(equalTo: bottomContainerView.leftAnchor, constant: 16),
                                        topSeparator.topAnchor.constraint(equalTo: bottomContainerView.topAnchor)])

        recordingDotViewHidden = [timeLabel.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
                                  timeLabel.leftAnchor.constraint(equalTo: bottomContainerView.leftAnchor, constant: margin)]

        recordingDotViewVisible = [
            timeLabel.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
            timeLabel.leftAnchor.constraint(equalTo: recordingDotView.rightAnchor, constant: 24),

            recordingDotView.leftAnchor.constraint(equalTo: bottomContainerView.leftAnchor, constant: margin + 8),
            recordingDotView.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor)
        ]

        recordingDotViewVisible.append(contentsOf: [
        recordingDotView.widthAnchor.constraint(equalToConstant: 8),
        recordingDotView.heightAnchor.constraint(equalToConstant: 8)
        ])

        NSLayoutConstraint.activate(recordingDotViewVisible)

        constraints.append(contentsOf: [rightSeparator.rightAnchor.constraint(equalTo: bottomContainerView.rightAnchor),
                                        rightSeparator.leftAnchor.constraint(equalTo: buttonOverlay.rightAnchor, constant: 8),
                                        rightSeparator.topAnchor.constraint(equalTo: bottomContainerView.topAnchor),
                                        rightSeparator.heightAnchor.constraint(equalToConstant: .hairline),

                                        audioPreviewView.leftAnchor.constraint(equalTo: timeLabel.rightAnchor, constant: 8),
                                        audioPreviewView.topAnchor.constraint(equalTo: bottomContainerView.topAnchor, constant: 12),
                                        audioPreviewView.bottomAnchor.constraint(equalTo: bottomContainerView.bottomAnchor, constant: -12),
                                        audioPreviewView.rightAnchor.constraint(equalTo: buttonOverlay.leftAnchor, constant: -12),

                                        cancelButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
                                        cancelButton.rightAnchor.constraint(equalTo: bottomContainerView.rightAnchor),
                                        buttonOverlay.rightAnchor.constraint(equalTo: cancelButton.leftAnchor, constant: -12),
                                        cancelButton.widthAnchor.constraint(equalToConstant: 56),
                                        cancelButton.heightAnchor.constraint(equalToConstant: 56)
                                       ])

        NSLayoutConstraint.activate(constraints)

    }

    private func configureAudioRecorder() {
        recorder.recordTimerCallback = { [weak self] time in
            guard let `self` = self else { return }
            self.updateTimeLabel(time)
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
            self.audioPreviewView.updateWithLevel(level)
        }
    }

    @objc func topContainerTapped(_ sender: UITapGestureRecognizer) {
        delegate?.audioRecordViewControllerDidCancel(self)
    }

    private func setRecordingState(_ state: AudioRecordState, animated: Bool) {
        updateRecordingState(state)

        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }

    private func updateRecordingState(_ state: AudioRecordState) {

        let visible = visibleViewsForState(state)
        let allViews = Set(view.subviews.flatMap { $0.subviews }) // Well, 2 levels 'all'
        let hidden = allViews.subtracting(visible)

        visible.forEach { $0.isHidden = false }
        hidden.forEach { $0.isHidden = true }

        buttonOverlay.recordingState = state
        let finished = state == .finishedRecording

        self.recordingDotView.animating = !finished

        let pathComponent = finished ? "tooltip.tap_send" : "tooltip.pull_send"
        topTooltipLabel.text = "\(localizationBasePath).\(pathComponent)".localized(uppercased: true)

        if recordingState == .recording {
            NSLayoutConstraint.deactivate(recordingDotViewHidden)
            NSLayoutConstraint.activate(recordingDotViewVisible)
        } else {
            NSLayoutConstraint.deactivate(recordingDotViewVisible)
            NSLayoutConstraint.activate(recordingDotViewHidden)
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

            AVAsset.convertAudioToUploadFormat(effectPath, outPath: convertedPath) { success in
                effectPath.deleteFileAtPath()

                if success {
                    self.delegate?.audioRecordViewControllerWantsToSendAudio(self, recordingURL: NSURL(fileURLWithPath: convertedPath) as URL, duration: self.recorder.currentDuration, filter: .none)
                }
            }
        }

    }

}
