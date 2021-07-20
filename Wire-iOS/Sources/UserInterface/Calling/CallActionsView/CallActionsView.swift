//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import UIKit
import WireSyncEngine

protocol CallActionsViewDelegate: class {
    func callActionsView(_ callActionsView: CallActionsView, perform action: CallAction)
}

enum MediaState: Equatable {
    struct SpeakerState: Equatable {
        let isEnabled: Bool
        let canBeToggled: Bool
    }
    case sendingVideo, notSendingVideo(speakerState: SpeakerState)

    var isSendingVideo: Bool {
        guard case .sendingVideo = self else { return false }
        return true
    }

    var showSpeaker: Bool {
        guard case .notSendingVideo = self else { return false }
        return true
    }

    var isSpeakerEnabled: Bool {
        guard case .notSendingVideo(let state) = self else { return false }
        return state.isEnabled
    }

    var canSpeakerBeToggled: Bool {
        guard case .notSendingVideo(let state) = self else { return false }
        return state.canBeToggled
    }
}

// This protocol describes the input for a `CallActionsView`.
protocol CallActionsViewInputType: CallTypeProvider, ColorVariantProvider {
    var canToggleMediaType: Bool { get }
    var isMuted: Bool { get }
    var mediaState: MediaState { get }
    var permissions: CallPermissionsConfiguration { get }
    var cameraType: CaptureDevice { get }
    var networkQuality: NetworkQuality { get }
    var callState: CallStateExtending { get }
    var videoGridPresentationMode: VideoGridPresentationMode { get }
    var allowPresentationModeUpdates: Bool { get }
}

extension CallActionsViewInputType {
    var appearance: CallActionAppearance {
        switch (isVideoCall, variant) {
        case (true, _): return .dark(blurred: true)
        case (false, .light): return .light
        case (false, .dark): return .dark(blurred: false)
        }
    }
}

// A view showing multiple buttons depending on the given `CallActionsView.Input`.
// Button touches result in `CallActionsView.Action` cases to be sent to the objects delegate.
final class CallActionsView: UIView {

    weak var delegate: CallActionsViewDelegate?

    private let verticalStackView = UIStackView(axis: .vertical)
    private let topStackView = UIStackView(axis: .horizontal)
    private let bottomStackView = UIStackView(axis: .horizontal)

    private var lastInput: CallActionsViewInputType?
    private var videoButtonDisabledTapRecognizer: UITapGestureRecognizer?

    private let speakersAllSegmentedView = RoundedSegmentedView()

    // Buttons
    private let microphoneButton = IconLabelButton.microphone()
    private let cameraButton = IconLabelButton.camera()
    private let cameraButtonDisabled = UIView()
    private let speakerButton = IconLabelButton.speaker()
    private let flipCameraButton = IconLabelButton.flipCamera()
    private let firstBottomRowSpacer = UIView()
    private let endCallButton = IconButton.endCall()
    private let secondBottomRowSpacer = UIView()
    private let acceptCallButton = IconButton.acceptCall()

    private var allButtons: [UIButton] {
        return [microphoneButton, cameraButton, speakerButton, flipCameraButton, endCallButton, acceptCallButton]
    }

    // MARK: - Setup

    init() {
        super.init(frame: .zero)
        videoButtonDisabledTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(performButtonAction))
        setupViews()
        setupAccessibility()
        createConstraints()
    }

    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        setupSegmentedView()
        cameraButtonDisabled.addGestureRecognizer(videoButtonDisabledTapRecognizer!)
        topStackView.distribution = .equalSpacing
        topStackView.spacing = 32
        bottomStackView.distribution = .equalSpacing
        bottomStackView.alignment = .top
        bottomStackView.spacing = 32
        verticalStackView.alignment = .center
        verticalStackView.spacing = 64
        addSubview(verticalStackView)
        [microphoneButton, cameraButton, flipCameraButton, speakerButton].forEach(topStackView.addArrangedSubview)
        [firstBottomRowSpacer, endCallButton, secondBottomRowSpacer, acceptCallButton].forEach(bottomStackView.addArrangedSubview)
        [speakersAllSegmentedView, topStackView, bottomStackView].forEach(verticalStackView.addArrangedSubview)
        allButtons.forEach { $0.addTarget(self, action: #selector(performButtonAction), for: .touchUpInside) }
        addSubview(cameraButtonDisabled)
    }

    private func setupSegmentedView() {
        VideoGridPresentationMode.allCases.forEach { mode in
            speakersAllSegmentedView.addButton(
                withTitle: mode.title,
                actionHandler: { [weak self] in self?.updateVideoGridPresentationMode(with: mode) }
            )
        }
        speakersAllSegmentedView.setSelected(true, forItemAt: VideoGridPresentationMode.allVideoStreams.index)
    }

    private func setupAccessibility() {
        typealias Voice = L10n.Localizable.Voice

        microphoneButton.accessibilityLabel = Voice.MuteButton.title
        cameraButton.accessibilityLabel = Voice.VideoButton.title
        speakerButton.accessibilityLabel = Voice.SpeakerButton.title
        flipCameraButton.accessibilityLabel = Voice.FlipVideoButton.title
        acceptCallButton.accessibilityLabel = Voice.AcceptButton.title
    }

    private func createConstraints() {
        [verticalStackView, cameraButtonDisabled, speakersAllSegmentedView].forEach {
           $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: verticalStackView.leadingAnchor),
            topAnchor.constraint(equalTo: verticalStackView.topAnchor),
            trailingAnchor.constraint(equalTo: verticalStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor),
            topStackView.widthAnchor.constraint(equalTo: verticalStackView.widthAnchor),
            bottomStackView.widthAnchor.constraint(equalTo: verticalStackView.widthAnchor),
            firstBottomRowSpacer.widthAnchor.constraint(equalToConstant: IconButton.width),
            firstBottomRowSpacer.heightAnchor.constraint(equalToConstant: IconButton.height),
            secondBottomRowSpacer.widthAnchor.constraint(equalToConstant: IconButton.width),
            secondBottomRowSpacer.heightAnchor.constraint(equalToConstant: IconButton.height),
            cameraButtonDisabled.leftAnchor.constraint(equalTo: cameraButton.leftAnchor),
            cameraButtonDisabled.rightAnchor.constraint(equalTo: cameraButton.rightAnchor),
            cameraButtonDisabled.topAnchor.constraint(equalTo: cameraButton.topAnchor),
            cameraButtonDisabled.bottomAnchor.constraint(equalTo: cameraButton.bottomAnchor),
            speakersAllSegmentedView.widthAnchor.constraint(equalToConstant: 180),
            speakersAllSegmentedView.heightAnchor.constraint(equalToConstant: 25)
        ])
    }

    // MARK: - State Input

    // Single entry point for all state changes.
    // All side effects should be started from this method.
    func update(with input: CallActionsViewInputType) {
        speakersAllSegmentedView.isHidden = !input.allowPresentationModeUpdates
        speakersAllSegmentedView.setSelected(true, forItemAt: input.videoGridPresentationMode.index)
        microphoneButton.isSelected = !input.isMuted
        microphoneButton.isEnabled = canToggleMuteButton(input)
        cameraButtonDisabled.isUserInteractionEnabled = !input.canToggleMediaType
        videoButtonDisabledTapRecognizer?.isEnabled = !input.canToggleMediaType
        cameraButton.isEnabled = input.canToggleMediaType
        cameraButton.isSelected = input.mediaState.isSendingVideo && input.permissions.canAcceptVideoCalls
        flipCameraButton.isEnabled = input.mediaState.isSendingVideo && input.permissions.canAcceptVideoCalls
        flipCameraButton.isHidden = input.mediaState.showSpeaker
        speakerButton.isHidden = !input.mediaState.showSpeaker
        speakerButton.isSelected = input.mediaState.isSpeakerEnabled
        speakerButton.isEnabled = canToggleSpeakerButton(input)
        acceptCallButton.isHidden = !input.callState.canAccept
        firstBottomRowSpacer.isHidden = input.callState.canAccept
        [microphoneButton, cameraButton, flipCameraButton, speakerButton].forEach { $0.appearance = input.appearance }
        alpha = input.callState.isTerminating ? 0.4 : 1
        isUserInteractionEnabled = !input.callState.isTerminating
        lastInput = input
        updateAccessibilityElements(with: input)
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func canToggleMuteButton(_ input: CallActionsViewInputType) -> Bool {
        return input.callState.isConnected && !input.permissions.isAudioDisabledForever
    }

    private func canToggleSpeakerButton(_ input: CallActionsViewInputType) -> Bool {
        return input.callState.isConnected && input.mediaState.canSpeakerBeToggled
    }

    // MARK: - Action Output

    func updateVideoGridPresentationMode(with mode: VideoGridPresentationMode) {
        delegate?.callActionsView(self, perform: .updateVideoGridPresentationMode(mode))
    }

    @objc private func performButtonAction(_ sender: IconLabelButton) {
        delegate?.callActionsView(self, perform: action(for: sender))
    }

    private func action(for button: IconLabelButton) -> CallAction {
        switch button {
        case microphoneButton: return .toggleMuteState
        case cameraButton: return .toggleVideoState
        case videoButtonDisabledTapRecognizer: return .alertVideoUnavailable
        case speakerButton: return .toggleSpeakerState
        case flipCameraButton: return .flipCamera
        case endCallButton: return .terminateCall
        case acceptCallButton: return .acceptCall
        default: fatalError("Unexpected Button: \(button)")
        }
    }

    // MARK: - Accessibility

    private func updateAccessibilityElements(with input: CallActionsViewInputType) {
        typealias Label = L10n.Localizable.Call.Actions.Label

        microphoneButton.accessibilityLabel = input.isMuted ? Label.toggleMuteOff : Label.toggleMuteOn
        flipCameraButton.accessibilityLabel = Label.flipCamera
        speakerButton.accessibilityLabel = input.mediaState.isSpeakerEnabled ? Label.toggleSpeakerOff : Label.toggleSpeakerOn
        acceptCallButton.accessibilityLabel = Label.acceptCall
        endCallButton.accessibilityLabel = input.callState.canAccept ? Label.rejectCall : Label.terminateCall
        cameraButtonDisabled.accessibilityLabel = Label.toggleVideoOn
        cameraButton.accessibilityLabel = input.mediaState.isSendingVideo ? Label.toggleVideoOff : Label.toggleVideoOn
        flipCameraButton.accessibilityLabel = input.cameraType == .front ? Label.switchToBackCamera : Label.switchToFrontCamera

        speakersAllSegmentedView.accessibilityIdentifier = "speakers_and_all_toggle.selected.\(input.videoGridPresentationMode.accessibilityIdentifier)"
    }

}
