//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

// this is duplicate fot CallActionsView made for ACC-143
protocol CallingActionsViewDelegate: AnyObject {
    func callingActionsViewPerformAction(_ action: CallAction)
}

// A view showing multiple buttons depending on the given `CallActionsView.Input`.
// Button touches result in `CallActionsView.Action` cases to be sent to the objects delegate.
class CallingActionsView: UIView {

    weak var delegate: CallingActionsViewDelegate?

    private let verticalStackView = UIStackView(axis: .vertical)
    private let topStackView = UIStackView(axis: .horizontal)
    private var input: CallActionsViewInputType?
    private var videoButtonDisabledTapRecognizer: UITapGestureRecognizer?

    // Buttons
    private let microphoneButton = CallingActionButton.microphoneButton()
    private let cameraButton = CallingActionButton.cameraButton()
    private let cameraButtonDisabled = UIView()
    private let speakerButton = CallingActionButton.speakerButton()
    private let flipCameraButton = CallingActionButton.flipCameraButton()
    private let endCallButton =  EndCallButton.endCallButton()
    private let acceptCallButton = IconButton.acceptCall()
    private  let handleView = UIView()

    private var allButtons: [IconLabelButton] {
        return [flipCameraButton, cameraButton, microphoneButton, speakerButton, endCallButton]
    }

    // MARK: - Setup

    init() {
        super.init(frame: .zero)
        videoButtonDisabledTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(performButtonAction))
        setupViews()
        setupAccessibility()
        createConstraints()
        updateToLayoutSize(layoutSize)

        print(ColorScheme.default.variant == .dark)
        backgroundColor = UIColor.from(scheme: .callActionBackground, variant: ColorScheme.default.variant)
    }

    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        cameraButtonDisabled.addGestureRecognizer(videoButtonDisabledTapRecognizer!)
        topStackView.distribution = .fillEqually
        topStackView.spacing = 16
        verticalStackView.alignment = .center
        verticalStackView.spacing = 10
        addSubview(verticalStackView)
        allButtons.forEach(topStackView.addArrangedSubview)
        handleView.layer.cornerRadius = 3.0
        handleView.backgroundColor = UIColor(light: Asset.gray70, dark: Asset.gray70)
        [handleView, topStackView].forEach(verticalStackView.addArrangedSubview) //add top handle
        allButtons.forEach { $0.addTarget(self, action: #selector(performButtonAction), for: .touchUpInside) }
        addSubview(cameraButtonDisabled)
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
        [verticalStackView, cameraButtonDisabled].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0),
            verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16.0),
            verticalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8),
            topStackView.widthAnchor.constraint(equalTo: verticalStackView.widthAnchor),
            cameraButtonDisabled.leftAnchor.constraint(equalTo: cameraButton.leftAnchor),
            cameraButtonDisabled.rightAnchor.constraint(equalTo: cameraButton.rightAnchor),
            cameraButtonDisabled.topAnchor.constraint(equalTo: cameraButton.topAnchor),
            cameraButtonDisabled.bottomAnchor.constraint(equalTo: cameraButton.bottomAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 129),
            handleView.heightAnchor.constraint(equalToConstant: 6)
        ])
    }

    // MARK: - Orientation

    func updateToLayoutSize(_ layoutSize: LayoutSize, animated: Bool = false) {
        let canAcceptCall = input?.callState.canAccept ?? false
        let isCompact = layoutSize == .compact
        acceptCallButton.isHidden = isCompact || !canAcceptCall
    }

    private var layoutSize: LayoutSize {
        LayoutSize(
            isConnected: input?.callState.isConnected ?? false,
            isCompactVerticalSizeClass: traitCollection.verticalSizeClass == .compact
        )
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.didSizeClassChange(from: previousTraitCollection) else { return }
        updateToLayoutSize(layoutSize)
        setNeedsLayout()
        layoutIfNeeded()
        print(ColorScheme.default.variant == .dark)
    }
    // MARK: - State Input

    // Single entry point for all state changes.
    // All side effects should be started from this method.
    func update(with input: CallActionsViewInputType) {
        self.input = input
        microphoneButton.isSelected = !input.isMuted
        microphoneButton.isEnabled = canToggleMuteButton(input)
        cameraButtonDisabled.isUserInteractionEnabled = !input.canToggleMediaType
        videoButtonDisabledTapRecognizer?.isEnabled = !input.canToggleMediaType
        cameraButton.isEnabled = input.canToggleMediaType
        cameraButton.isSelected = input.mediaState.isSendingVideo && input.permissions.canAcceptVideoCalls
        flipCameraButton.isEnabled = input.mediaState.isSendingVideo && input.permissions.canAcceptVideoCalls
        speakerButton.isSelected = input.mediaState.isSpeakerEnabled
        speakerButton.isEnabled = canToggleSpeakerButton(input)
        [microphoneButton, cameraButton, flipCameraButton, speakerButton].forEach { $0.appearance = .adaptive }
        updateToLayoutSize(layoutSize, animated: true)
        updateAccessibilityElements(with: input)
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func canToggleMuteButton(_ input: CallActionsViewInputType) -> Bool {
        return !input.permissions.isAudioDisabledForever
    }

    private func canToggleSpeakerButton(_ input: CallActionsViewInputType) -> Bool {
        return input.mediaState.canSpeakerBeToggled
    }

    // MARK: - Action Output

    func updateVideoGridPresentationMode(with mode: VideoGridPresentationMode) {
        delegate?.callingActionsViewPerformAction(.updateVideoGridPresentationMode(mode))
    }

    @objc private func performButtonAction(_ sender: IconLabelButton) {
        delegate?.callingActionsViewPerformAction(action(for: sender))
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

        microphoneButton.accessibilityLabel = input.isMuted ? Label.toggleMuteOff: Label.toggleMuteOn
        flipCameraButton.accessibilityLabel = Label.flipCamera
        speakerButton.accessibilityLabel = input.mediaState.isSpeakerEnabled ? Label.toggleSpeakerOff: Label.toggleSpeakerOn
        acceptCallButton.accessibilityLabel = Label.acceptCall
        endCallButton.accessibilityLabel = input.callState.canAccept ? Label.rejectCall: Label.terminateCall
//        cameraButtonDisabled.accessibilityLabel = Label.toggleVideoOn
        cameraButton.accessibilityLabel = input.mediaState.isSendingVideo ? Label.toggleVideoOff: Label.toggleVideoOn
        flipCameraButton.accessibilityLabel = input.cameraType == .front ? Label.switchToBackCamera: Label.switchToFrontCamera

    }

}

extension CallingActionsView {
    enum LayoutSize {
        case compact
        case regular
    }
}

extension CallingActionsView.LayoutSize {
    init(isConnected: Bool, isCompactVerticalSizeClass: Bool) {
        self = (isConnected && isCompactVerticalSizeClass) ? .compact : .regular
    }
}
