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
import WireCommonComponents

protocol CallingActionsViewDelegate: AnyObject {
    func callingActionsViewPerformAction(_ action: CallAction)
}

protocol BottomSheetScrollingDelegate: AnyObject {
    var isBottomSheetExpanded: Bool { get }
    func toggleBottomSheetVisibility()
}

// A view showing multiple buttons depending on the given `CallActionsView.Input`.
// Button touches result in `CallActionsView.Action` cases to be sent to the objects delegate.
class CallingActionsView: UIView {

    weak var delegate: CallingActionsViewDelegate?
    weak var bottomSheetScrollingDelegate: BottomSheetScrollingDelegate? {
        didSet {
            handleView.isAccessibilityElement = true
            handleView.accessibilityAction = handleViewAccessibilityAction
            updateHandleViewAccessibilityLabel()
        }
    }

    let verticalStackView = UIStackView(axis: .vertical)
    private let topStackView = UIStackView(axis: .horizontal)
    private let botttomStackView = UIStackView(axis: .horizontal)
    private var input: CallActionsViewInputType?
    private var videoButtonDisabledTapRecognizer: UITapGestureRecognizer?
    private var verticalStackViewTopContraint: NSLayoutConstraint!

    // Buttons
    private let microphoneButton = CallingActionButton.microphoneButton()
    private let cameraButton = CallingActionButton.cameraButton()
    private let speakerButton = CallingActionButton.speakerButton()
    private let flipCameraButton = CallingActionButton.flipCameraButton()
    private let endCallButton =  EndCallButton.endCallButton()
    private let handleView = AccessibilityActionView()
    private let largePickUpButton = PickUpButton.bigPickUpButton()
    private let largeHangUpButton = EndCallButton.bigEndCallButton()

    private var establishedCallButtons: [IconLabelButton] {
        return [flipCameraButton, cameraButton, microphoneButton, speakerButton, endCallButton]
    }

    var isIncomingCall: Bool = false {
        didSet {
            guard oldValue != isIncomingCall else { return }
            topStackView.removeSubviews()
            handleView.isHidden = isIncomingCall
            handleView.accessibilityElementsHidden = isIncomingCall
            if isIncomingCall  {
                [microphoneButton, cameraButton, speakerButton].forEach(topStackView.addArrangedSubview)
                addIncomingCallControllButtons()
                verticalStackViewTopContraint.constant = 16.0
            } else {
                establishedCallButtons.forEach(topStackView.addArrangedSubview)
                removeIncomingCallControllButtons()
                verticalStackViewTopContraint.constant = 8.0
            }
            setNeedsDisplay()
        }
    }

    // MARK: - Setup

    init() {
        super.init(frame: .zero)

        videoButtonDisabledTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(performButtonAction))
        setupViews()
        createConstraints()
    }

    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = SemanticColors.View.backgroundDefaultWhite
        topStackView.distribution = .equalSpacing
        topStackView.spacing = 6
        verticalStackView.alignment = .center
        verticalStackView.spacing = 10
        addSubview(verticalStackView)
        establishedCallButtons.forEach(topStackView.addArrangedSubview)
        handleView.layer.cornerRadius = 3.0
        handleView.backgroundColor = SemanticColors.View.backgroundCallDragBarIndicator
        [handleView, topStackView].forEach(verticalStackView.addArrangedSubview)
        [
            flipCameraButton,
            cameraButton,
            microphoneButton,
            speakerButton,
            endCallButton,
            largeHangUpButton,
            largePickUpButton
        ].forEach { $0.addTarget(self, action: #selector(performButtonAction), for: .touchUpInside) }
        setupContentViewer()
    }

    private func createConstraints() {
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackViewTopContraint = verticalStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8)
        NSLayoutConstraint.activate([
            verticalStackViewTopContraint,
            verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topStackView.heightAnchor.constraint(equalToConstant: 84).withPriority(.required),
            handleView.heightAnchor.constraint(equalToConstant: 5),
            handleView.widthAnchor.constraint(equalToConstant: 130)
        ])
    }

    private func setupContentViewer() {
        showsLargeContentViewer = true
        scalesLargeContentImage = true

        let interaction = UILargeContentViewerInteraction(delegate: self)
        addInteraction(interaction)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        establishedCallButtons.forEach { $0.updateState() }
    }

    private func addIncomingCallControllButtons() {
        [largeHangUpButton, largePickUpButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.updateButtonWidth(width: 72.0)
            $0.subtitleTransformLabel.font = FontSpec(.small, .bold).font!
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            largeHangUpButton.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: 16),
            largeHangUpButton.bottomAnchor.constraint(equalTo: safeBottomAnchor, constant: -12),
            largePickUpButton.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -16),
            largePickUpButton.bottomAnchor.constraint(equalTo: safeBottomAnchor, constant: -12)
        ])
    }

    private func removeIncomingCallControllButtons() {
        [largeHangUpButton, largePickUpButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.removeFromSuperview()
        }
    }

    // MARK: - State Input

    // Single entry point for all state changes.
    // All side effects should be started from this method.
    func update(with input: CallActionsViewInputType) {
        self.input = input
        microphoneButton.isSelected = !input.isMuted
        microphoneButton.isEnabled = canToggleMuteButton(input)
        videoButtonDisabledTapRecognizer?.isEnabled = !input.canToggleMediaType
        cameraButton.isEnabled = input.canToggleMediaType
        cameraButton.isSelected = input.mediaState.isSendingVideo && input.permissions.canAcceptVideoCalls
        flipCameraButton.isEnabled = input.mediaState.isSendingVideo && input.permissions.canAcceptVideoCalls
        speakerButton.isSelected = input.mediaState.isSpeakerEnabled
        speakerButton.isEnabled = canToggleSpeakerButton(input)
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
        case endCallButton, largeHangUpButton: return .terminateCall
        case largePickUpButton: return .acceptCall
        default: fatalError("Unexpected Button: \(button)")
        }
    }

    // MARK: - Accessibility

    private func updateAccessibilityElements(with input: CallActionsViewInputType) {
        typealias Calling = L10n.Accessibility.Calling

        microphoneButton.accessibilityLabel = input.isMuted ? Calling.MicrophoneOnButton.description : Calling.MicrophoneOffButton.description
        speakerButton.accessibilityLabel = input.mediaState.isSpeakerEnabled ? Calling.SpeakerOffButton.description : Calling.SpeakerOnButton.description
        endCallButton.accessibilityLabel = Calling.HangUpButton.description
        cameraButton.accessibilityLabel = input.mediaState.isSendingVideo ? Calling.VideoOffButton.description : Calling.VideoOnButton.description
        flipCameraButton.accessibilityLabel = input.cameraType == .front ? Calling.FlipCameraBackButton.description : Calling.FlipCameraFrontButton.description
    }

    private func updateHandleViewAccessibilityLabel() {
        typealias Calling = L10n.Accessibility.Calling

        guard let bottomSheetScrollingDelegate = bottomSheetScrollingDelegate else { return }
        handleView.accessibilityHint = bottomSheetScrollingDelegate.isBottomSheetExpanded
                                     ? Calling.SwipeDownParticipants.hint
                                     : Calling.SwipeUpParticipants.hint
    }

    @objc private func handleViewAccessibilityAction() {
        bottomSheetScrollingDelegate?.toggleBottomSheetVisibility()
        updateHandleViewAccessibilityLabel()
    }
}

// MARK: - UILargeContentViewerInteractionDelegate

extension CallingActionsView: UILargeContentViewerInteractionDelegate {

    func largeContentViewerInteraction(_: UILargeContentViewerInteraction, itemAt: CGPoint) -> UILargeContentViewerItem? {
        let itemWidth = self.frame.width / CGFloat(establishedCallButtons.count)
        let position: Int = Int(itemAt.x / itemWidth)
        largeContentTitle = establishedCallButtons[position].subtitleTransformLabel.text
        largeContentImage = establishedCallButtons[position].iconButton.imageView?.image

        return self
    }

}
