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
    var floatingVideoStream: UUID? { get }
    var videoStreams: [UUID] { get }
}

class VideoGridViewController: UIViewController {
    
    private var gridVideoStreams: [UUID] = []
    private let gridView = GridView()
    private let thumbnailViewController = PinnableThumbnailViewController()
    
    
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
        updateFloatingVideo(with: configuration.floatingVideoStream)
        updateVideoGrid(with: configuration.videoStreams)
    }
    
    private func updateFloatingVideo(with stream: UUID?) {
        thumbnailViewController.view.isHidden = nil != stream
        guard stream == ZMUser.selfUser().remoteIdentifier else { return }
        let previewView = AVSVideoPreview()
        previewView.translatesAutoresizingMaskIntoConstraints = false
        
        // TODO: Calculate correct size based on device and orientation
        thumbnailViewController.setThumbnailContentView(previewView, contentSize: CGSize(width: 400, height: 400))
    }
    
    private func updateVideoGrid(with videoStreams: [UUID]) {
        let removed = gridVideoStreams.filter({ !videoStreams.contains($0) })
        let added = videoStreams.filter({ !gridVideoStreams.contains($0) })
        
        removed.forEach(removeStream)
        added.forEach(addStream)
    }
    
    func addStream(_ streamId: UUID) {
        Calling.log.debug("Adding video stream: \(streamId)")
        
        let view: UIView
        if streamId == ZMUser.selfUser().remoteIdentifier {
            let videoView = AVSVideoPreview()
            videoView.translatesAutoresizingMaskIntoConstraints = false
            view = videoView
        } else {
            let videoView = AVSVideoView()
            videoView.translatesAutoresizingMaskIntoConstraints = false
            videoView.userid = streamId.transportString()
            videoView.shouldFill = true
            view = videoView
        }
        
        gridView.append(view: view)
        gridVideoStreams.append(streamId)
    }
    
    func removeStream(_ streamId: UUID) {
        Calling.log.debug("Removing video stream: \(streamId)")
        
        guard let videoView = gridView.gridSubviews.first(where: { ($0 as? AVSVideoView)?.userid == streamId.transportString() }) else { return }
        gridView.remove(view: videoView)
        gridVideoStreams.index(of: streamId).apply({ gridVideoStreams.remove(at: $0)})
    }
    
}
