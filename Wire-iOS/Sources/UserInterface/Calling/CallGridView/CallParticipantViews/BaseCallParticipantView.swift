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
import UIKit
import avs
import WireSyncEngine

class BaseCallParticipantView: OrientableView, AVSIdentifierProvider {

    // MARK: - Public Properties

    var stream: Stream {
        didSet {
            updateUserDetails()
            updateBorderStyle()
            updateVideoKind()
            hideVideoViewsIfNeeded()
        }
    }

    var shouldShowActiveSpeakerFrame: Bool {
        didSet {
            updateBorderStyle()
        }
    }

    var shouldShowBorderWhenVideoIsStopped: Bool {
        didSet {
            updateBorderStyle()
        }
    }

    /// indicates wether or not the view is shown in full in the grid
    var isMaximized: Bool = false {
        didSet {
            updateBorderStyle()
            updateFillMode()
            updateScalableView()
        }
    }

    var shouldFill: Bool {
        return isMaximized ? false : videoKind.shouldFill
    }

    let userDetailsView = CallParticipantDetailsView()
    var scalableView: ScalableView?
    var avatarView = UserImageView(size: .normal)
    var userSession = ZMUserSession.shared()
    private(set) var videoView: AVSVideoViewProtocol?

    // MARK: - Private Properties

    private var delta: OrientationDelta = OrientationDelta()
    private var detailsConstraints: UserDetailsConstraints?
    private var isCovered: Bool

    private var adjustedInsets: UIEdgeInsets {
        safeAreaInsetsOrFallback.adjusted(for: delta)
    }

    private var userDetailsAlpha: CGFloat {
        isCovered ? 0 : 1
    }

    // MARK: - View Life Cycle

    init(stream: Stream,
         isCovered: Bool,
         shouldShowActiveSpeakerFrame: Bool,
         shouldShowBorderWhenVideoIsStopped: Bool,
         pinchToZoomRule: PinchToZoomRule) {
        self.stream = stream
        self.isCovered = isCovered
        self.shouldShowActiveSpeakerFrame = shouldShowActiveSpeakerFrame
        self.shouldShowBorderWhenVideoIsStopped = shouldShowBorderWhenVideoIsStopped
        self.pinchToZoomRule = pinchToZoomRule

        super.init(frame: .zero)

        setupViews()
        createConstraints()
        updateUserDetails()
        updateVideoKind()
        updateBorderStyle()
        hideVideoViewsIfNeeded()

        NotificationCenter.default.addObserver(self, selector: #selector(updateUserDetailsVisibility), name: .videoGridVisibilityChanged, object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    func updateUserDetails() {
        userDetailsView.name = stream.user?.name
        userDetailsView.microphoneIconStyle = MicrophoneIconStyle(state: stream.microphoneState, shouldPulse: stream.activeSpeakerState.isSpeakingNow)
        userDetailsView.alpha = userDetailsAlpha
    }

    func setupViews() {
        addSubview(avatarView)
        addSubview(userDetailsView)

        backgroundColor = .graphite
        avatarView.user = stream.user
        avatarView.userSession = userSession
        userDetailsView.alpha = 0
    }

    func createConstraints() {

        [avatarView, userDetailsView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        detailsConstraints = UserDetailsConstraints(
            view: userDetailsView,
            superview: self,
            safeAreaInsets: adjustedInsets
        )

        NSLayoutConstraint.activate([
            userDetailsView.heightAnchor.constraint(equalToConstant: 24),
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 88),
            avatarView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.7),
            avatarView.heightAnchor.constraint(equalTo: avatarView.widthAnchor)
        ])
    }

    private func hideVideoViewsIfNeeded() {
        scalableView?.isHidden = !stream.isSharingVideo
    }

    // MARK: - Pinch To Zoom

    var pinchToZoomRule: PinchToZoomRule {
        didSet {
            guard oldValue != pinchToZoomRule else { return }
            updateScalableView()
        }
    }

    func updateScalableView() {
        scalableView?.isScalingEnabled = shouldEnableScaling
    }

    var shouldEnableScaling: Bool {
        switch pinchToZoomRule {
        case .enableWhenFitted:
            return !shouldFill
        case .enableWhenMaximized:
            return isMaximized
        }
    }

    // MARK: - Fill Mode

    private var videoKind: VideoKind = .none {
        didSet {
            guard oldValue != videoKind else { return }
            updateFillMode()
            updateScalableView()
        }
    }

    private func updateVideoKind() {
        videoKind = VideoKind(videoState: stream.videoState)
    }

    private func updateFillMode() {
        // Reset scale if the view was zoomed in
        scalableView?.resetScale()
        videoView?.shouldFill = shouldFill
    }

    // MARK: - Border Style

    private func updateBorderStyle() {
        let showBorderForActiveSpeaker = shouldShowActiveSpeakerFrame && stream.isParticipantUnmutedAndSpeakingNow
        let showBorderForAudioParticipant = shouldShowBorderWhenVideoIsStopped && !stream.isSharingVideo

        layer.borderWidth = (showBorderForActiveSpeaker || showBorderForAudioParticipant) && !isMaximized ? 1 : 0
        layer.borderColor = showBorderForActiveSpeaker ? UIColor.accent().cgColor : UIColor.black.cgColor
    }

    // MARK: - Orientation & Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        detailsConstraints?.updateEdges(with: adjustedInsets)
    }

    func layout(forInterfaceOrientation interfaceOrientation: UIInterfaceOrientation,
                deviceOrientation: UIDeviceOrientation) {
        guard let superview = superview else { return }

        delta = OrientationDelta(interfaceOrientation: interfaceOrientation,
                                 deviceOrientation: deviceOrientation)

        transform = CGAffineTransform(rotationAngle: delta.radians)
        frame = superview.bounds

        layoutSubviews()
    }

    // MARK: - Visibility
    @objc private func updateUserDetailsVisibility(_ notification: Notification?) {
        guard let isCovered = notification?.userInfo?[CallGridViewController.isCoveredKey] as? Bool else {
            return
        }
        self.isCovered = isCovered
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                self.userDetailsView.alpha = self.userDetailsAlpha
        })
    }

    // MARK: - Accessibility for automation
    override var accessibilityIdentifier: String? {
        get {
            let name = stream.user?.name ?? ""
            let maximizationState = isMaximized ? "maximized" : "minimized"
            let activityState = stream.isParticipantUnmutedAndActive ? "active" : "inactive"
            let viewKind = stream.isSharingVideo ? "videoView" : "audioView"
            return "\(viewKind).\(name).\(maximizationState).\(activityState)"
        }
        set {}
    }
}

// MARK: - User Details Constraints
private struct UserDetailsConstraints {
    private let bottom: NSLayoutConstraint
    private let leading: NSLayoutConstraint
    private let trailing: NSLayoutConstraint

    private let margin: CGFloat = 8

    init(view: UIView, superview: UIView, safeAreaInsets insets: UIEdgeInsets) {
        bottom = view.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        leading = view.leadingAnchor.constraint(equalTo: superview.leadingAnchor)
        trailing = view.trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor)
        updateEdges(with: insets)
        NSLayoutConstraint.activate([bottom, leading, trailing])
    }

    func updateEdges(with insets: UIEdgeInsets) {
        leading.constant = margin + insets.left
        trailing.constant = -(margin + insets.right)
        bottom.constant = -(margin + insets.bottom)
    }
}
