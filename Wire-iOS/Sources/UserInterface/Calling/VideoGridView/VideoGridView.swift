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

protocol VideoGridConfiguration {
    var floatingVideoStream: ParticipantVideoState? { get }
    var videoStreams: [ParticipantVideoState] { get }
    var isMuted: Bool { get }
}

extension CGSize {
    static let floatingPreviewPortrait = CGSize(width: 108, height: 144)
    static let floatingPreviewLandscape = CGSize(width: 144, height: 108)
}

class VideoGridViewController: UIViewController {
    
    private var gridVideoStreams: [UUID] = []
    private let gridView = GridView()
    private let thumbnailViewController = PinnableThumbnailViewController()
    
    var previewOverlay: UIView? {
        return thumbnailViewController.contentView
    }
    
    private var selfPreviewView: SelfVideoPreviewView?
    
    var configuration: VideoGridConfiguration {
        didSet {
            updateState()
        }
    }
    
    init(configuration: VideoGridConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }
    
    func setupViews() {
        gridView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        addToSelf(thumbnailViewController)
    }
    
    func createConstraints() {
        gridView.fitInSuperview()
        thumbnailViewController.view.fitInSuperview()
    }
    
    func updateState() {
        let selfStreamId = ZMUser.selfUser().remoteIdentifier!
        let selfInGrid = configuration.videoStreams.contains { $0.stream == selfStreamId }
        let selfInFloatingOverlay = nil != configuration.floatingVideoStream
        let isShowingSelf = selfInGrid || selfInFloatingOverlay
        
        // Create self preview if there is none but we should show it
        if isShowingSelf && nil == selfPreviewView {
            selfPreviewView = SelfVideoPreviewView(identifier: selfStreamId.transportString())
            selfPreviewView?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        updateVideoGrid(with: configuration.videoStreams)
        updateFloatingVideo(with: configuration.floatingVideoStream)
        
        // Clear self preview we we shouldn't show it anymore
        if !isShowingSelf, let _ = selfPreviewView {
            selfPreviewView = nil
            precondition(selfPreviewView == nil)
        }
        
        // Update mute status
        selfPreviewView?.isMuted = configuration.isMuted
    }
    
    private func updateFloatingVideo(with state: ParticipantVideoState?) {
        // No stream, remove floating video if there is any
        guard let state = state else {
            return thumbnailViewController.removeCurrentThumbnailContentView()
        }
        
        // We only support the self preview in the floating overlay
        guard state.stream == ZMUser.selfUser().remoteIdentifier else {
            return Calling.log.error("Invalid operation: Non self preview in overlay")
        }
        
        // We have a stream but don't have a preview view yet
        if nil == thumbnailViewController.contentView, let previewView = selfPreviewView {
            // TODO: Calculate correct size based on device and orientation
            thumbnailViewController.setThumbnailContentView(previewView, contentSize: .floatingPreviewPortrait)
        }
    }
    
    private func updateVideoGrid(with videoStreams: [ParticipantVideoState]) {
        let streamIds = videoStreams.map { $0.stream }
        let removed = gridVideoStreams.filter { !streamIds.contains($0) }
        let added = streamIds.filter { !gridVideoStreams.contains($0) }
 
        removed.forEach(removeStream)
        added.forEach(addStream)

        updatePausedStates(with: videoStreams)
    }
    
    private func updatePausedStates(with videoStreams: [ParticipantVideoState]) {
        videoStreams.forEach {
            (streamView(for: $0.stream) as? VideoPreviewView)?.isPaused = $0.isPaused
        }
    }
    
    private func addStream(_ streamId: UUID) {
        Calling.log.debug("Adding video stream: \(streamId)")

        let view: UIView = {
            if streamId == ZMUser.selfUser().remoteIdentifier, let previewView = selfPreviewView {
                return previewView
            } else {
                return VideoPreviewView(identifier: streamId.transportString())
            }
        }()

        view.translatesAutoresizingMaskIntoConstraints = false
        gridView.append(view: view)
        gridVideoStreams.append(streamId)
    }

    private func removeStream(_ streamId: UUID) {
        Calling.log.debug("Removing video stream: \(streamId)")
        guard let videoView = streamView(for: streamId) else { return }
        gridView.remove(view: videoView)
        gridVideoStreams.index(of: streamId).apply { gridVideoStreams.remove(at: $0) }
    }
    
    private func streamView(for streamId: UUID) -> UIView? {
        return gridView.gridSubviews.first {
            ($0 as? AVSIdentifierProvider)?.identifier == streamId.transportString()
        }
    }

}
