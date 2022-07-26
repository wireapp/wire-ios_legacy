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

import Foundation
import UIKit
import avs
import WireSyncEngine

final class CallParticipantView: BaseCallParticipantView {

    // MARK: - Public Properties

    var isPaused = false {
        didSet {
            guard oldValue != isPaused else { return }
            updateState(animated: true)
        }
    }

    override var videoView: AVSVideoViewProtocol? {
        previewView
    }

    // MARK: - Private Properties

    private var previewView: AVSVideoView?
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let pausedLabel = UILabel(
        key: "call.video.paused",
        size: .normal,
        weight: .semibold,
        color: .textForeground,
        variant: .dark
    )
    private var snapshotView: UIView?

    // MARK: - Initialization

    override init(stream: Stream,
                  isCovered: Bool,
                  shouldShowActiveSpeakerFrame: Bool,
                  shouldShowBorderWhenVideoIsStopped: Bool,
                  pinchToZoomRule: PinchToZoomRule) {
        super.init(
            stream: stream,
            isCovered: isCovered,
            shouldShowActiveSpeakerFrame: shouldShowActiveSpeakerFrame,
            shouldShowBorderWhenVideoIsStopped: shouldShowBorderWhenVideoIsStopped,
            pinchToZoomRule: pinchToZoomRule
        )

        updateState()
    }

    // MARK: - Setup

    override func setupViews() {
        super.setupViews()

        [blurView, pausedLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            insertSubview($0, belowSubview: userDetailsView)
        }
        pausedLabel.textAlignment = .center
    }

    override func createConstraints() {
        super.createConstraints()
        blurView.fitIn(view: self)
        pausedLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        pausedLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    // MARK: - Paused state update

    private func updateState(animated: Bool = false) {
        if isPaused {
            createSnapshotView()
            blurView.effect = nil
            pausedLabel.alpha = 0
            blurView.isHidden = false
            pausedLabel.isHidden = false

            executeAnimations(animated: animated, animationBlock: { [weak self] in
                self?.blurView.effect = UIBlurEffect(style: .dark)
                self?.pausedLabel.alpha = 1
            }, completionBlock: { [weak self] _ in
                self?.previewView?.removeFromSuperview()
                self?.previewView = nil
            })
        } else {
            createPreviewView()

            executeAnimations(animated: animated, animationBlock: { [weak self] in
                self?.blurView.effect = nil
                self?.snapshotView?.alpha = 0
                self?.pausedLabel.alpha = 0
            }, completionBlock: { [weak self] _ in
                self?.snapshotView?.removeFromSuperview()
                self?.snapshotView = nil
                self?.blurView.isHidden = true
                self?.pausedLabel.isHidden = true
            })
        }
    }

    private func createPreviewView() {
        let preview = AVSVideoView()
        preview.backgroundColor = .clear
        preview.userid = stream.streamId.avsIdentifier.serialized
        preview.clientid = stream.streamId.clientId
        preview.shouldFill = shouldFill
        previewView = preview

        // Adding the preview into a container allows smoother scaling
        let scalableView = ScalableView(isScalingEnabled: shouldEnableScaling)
        scalableView.addSubview(preview)
        self.scalableView?.removeFromSuperview()
        self.scalableView = scalableView

        if let snapshotView = snapshotView {
            insertSubview(scalableView, belowSubview: snapshotView)
        } else {
            insertSubview(scalableView, belowSubview: userDetailsView)
        }

        [scalableView, preview].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.fitIn(view: self)
        }
    }

    private func createSnapshotView() {
        guard let snapshotView = previewView?.snapshotView(afterScreenUpdates: true) else { return }
        insertSubview(snapshotView, belowSubview: blurView)
        snapshotView.translatesAutoresizingMaskIntoConstraints = false
        snapshotView.fitIn(view: blurView)
        self.snapshotView = snapshotView
    }

    private func executeAnimations(animated: Bool,
                                   animationBlock: @escaping () -> Void,
                                   completionBlock: @escaping (Bool) -> Void) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: animationBlock, completion: completionBlock)
        } else {
            animationBlock()
            completionBlock(true)
        }
    }
}
