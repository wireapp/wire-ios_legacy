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

final class VideoPreviewView: BaseVideoPreviewView {

    var isPaused = false {
        didSet {
            guard oldValue != isPaused else { return }
            updateState(animated: true)
        }
    }

    override var isMaximized: Bool {
        didSet {
            updateFillMode()
        }
    }
    
    override var stream: Stream {
        didSet {
            updateVideoKind()
        }
    }

    var shouldFill: Bool {
        return isMaximized ? false : videoKind.shouldFill
    }

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
    override init(stream: Stream, isCovered: Bool, shouldShowActiveSpeakerFrame: Bool = false) {
        super.init(
            stream: stream,
            isCovered: isCovered,
            shouldShowActiveSpeakerFrame: shouldShowActiveSpeakerFrame
        )
        updateState()
        updateVideoKind()
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
        blurView.fitInSuperview()
        pausedLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        pausedLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    // MARK: - Fill mode

    private var videoKind: VideoKind = .none {
        didSet {
            guard oldValue != videoKind else { return }
            updateFillMode()
        }
    }

    private func updateVideoKind() {
        videoKind = VideoKind(videoState: stream.videoState)
    }

    private func updateFillMode() {
        guard let previewView = previewView else { return }

        previewView.shouldFill = shouldFill
    }

    // MARK: - Paused state update
    private func updateState(animated: Bool = false) {
        if isPaused {
            createSnapshotView()
            blurView.effect = nil
            pausedLabel.alpha = 0
            blurView.isHidden = false
            pausedLabel.isHidden = false

            let animationBlock = { [weak self] in
                self?.blurView.effect = UIBlurEffect(style: .dark)
                self?.pausedLabel.alpha = 1
            }
            
            let completionBlock = { [weak self] (_: Bool) -> () in
                self?.previewView?.removeFromSuperview()
                self?.previewView = nil
            }
            
            if animated {
                UIView.animate(withDuration: 0.2, animations: animationBlock, completion: completionBlock)
            }
            else {
                animationBlock()
                completionBlock(true)
            }
        } else {
            createPreviewView()
            let animationBlock = { [weak self] in
                self?.blurView.effect = nil
                self?.snapshotView?.alpha = 0
                self?.pausedLabel.alpha = 0
            }
            
            let completionBlock =  { [weak self] (_: Bool) -> () in
                self?.snapshotView?.removeFromSuperview()
                self?.snapshotView = nil
                self?.blurView.isHidden = true
                self?.pausedLabel.isHidden = true
            }
            
            if animated {
                UIView.animate(withDuration: 0.2, animations: animationBlock, completion: completionBlock)
            }
            else {
                animationBlock()
                completionBlock(true)
            }
        }
    }
    
    private func createPreviewView() {
        let preview = AVSVideoView()
        preview.backgroundColor = .clear
        preview.userid = stream.streamId.userId.transportString()
        preview.clientid = stream.streamId.clientId
        preview.translatesAutoresizingMaskIntoConstraints = false
        if let snapshotView = snapshotView {
            insertSubview(preview, belowSubview: snapshotView)
        } else {
            insertSubview(preview, belowSubview: userDetailsView)
        }
        preview.fitInSuperview()
        preview.shouldFill = shouldFill
        
        previewView = preview
    }
    
    private func createSnapshotView() {
        guard let snapshotView = previewView?.snapshotView(afterScreenUpdates: true) else { return }
        insertSubview(snapshotView, belowSubview: blurView)
        snapshotView.translatesAutoresizingMaskIntoConstraints = false
        snapshotView.fitInSuperview()
        self.snapshotView = snapshotView
    }
}

private enum VideoKind {
    case camera
    case screenshare
    case none
    
    init(videoState: VideoState?) {
        guard let state = videoState else {
            self = .none
            return
        }
        switch state {
        case .stopped, .paused:
            self = .none
        case .started, .badConnection:
            self = .camera
        case .screenSharing:
            self = .screenshare
        }
    }
    
    var shouldFill: Bool {
        return self == .camera
    }
}
