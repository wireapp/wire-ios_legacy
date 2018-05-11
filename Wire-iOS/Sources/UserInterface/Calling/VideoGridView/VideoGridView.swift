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
    var isMuted: Bool { get }
}

protocol AVSIdentifierProvider {
    var identifier: String { get }
}

extension AVSVideoView: AVSIdentifierProvider {
    var identifier: String {
        return userid
    }
}

final class SelfVideoPreviewView: UIView, AVSIdentifierProvider {
    private let previewView = AVSVideoPreview()
    private let mutedOverlayView = UIView()
    private let mutedIconImageView = UIImageView()
    let identifier: String
    
    var isMuted = false {
        didSet {
            mutedOverlayView.isHidden = !isMuted
            mutedIconImageView.isHidden = !isMuted
        }
    }
    
    init(identifier: String) {
        self.identifier = identifier
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        mutedOverlayView.isHidden = true
        mutedIconImageView.isHidden = true
        mutedIconImageView.contentMode = .center
        mutedOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        let iconColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: .dark)
        mutedIconImageView.image = UIImage(for: .microphoneWithStrikethrough, iconSize: .tiny, color: iconColor)
        [previewView, mutedOverlayView, mutedIconImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }
    
    private func createConstraints() {
        previewView.fitInSuperview()
        mutedOverlayView.fitInSuperview()
        mutedIconImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        mutedIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
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
        updateFloatingVideo(with: configuration.floatingVideoStream)
        updateVideoGrid(with: configuration.videoStreams)
    }
    
    private func updateFloatingVideo(with stream: UUID?) {
        // No stream, remove floating video if there is any
        guard let stream = stream else {
            selfPreviewView = nil
            return thumbnailViewController.removeCurrentThumbnailContentView()
        }
        
        // We only support the self preview in the floating overlay
        guard stream == ZMUser.selfUser().remoteIdentifier else {
            return Calling.log.error("Invalid operation: Non self preview in overlay")
        }
        
        // We have a stream but don't have a preview view yet
        if nil == selfPreviewView {
            let previewView = SelfVideoPreviewView(identifier: stream.transportString())
            previewView.translatesAutoresizingMaskIntoConstraints = false
            
            // TODO: Calculate correct size based on device and orientation
            thumbnailViewController.setThumbnailContentView(previewView, contentSize: .floatingPreviewPortrait)
            selfPreviewView = previewView
        }
        
        // Update mute status
        selfPreviewView?.isMuted = configuration.isMuted
    }
    
    private func updateVideoGrid(with videoStreams: [UUID]) {
        let removed = gridVideoStreams.filter({ !videoStreams.contains($0) })
        let added = videoStreams.filter({ !gridVideoStreams.contains($0) })
 
        removed.forEach(removeStream)
        added.forEach(addStream)
    }
    
    private func addStream(_ streamId: UUID) {
        Calling.log.debug("Adding video stream: \(streamId)")
        
        let view: UIView
        if streamId == ZMUser.selfUser().remoteIdentifier {
            let videoView = SelfVideoPreviewView(identifier: streamId.transportString())
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
    
    private func removeStream(_ streamId: UUID) {
        Calling.log.debug("Removing video stream: \(streamId)")
        guard let videoView = streamView(for: streamId) else { return }
        gridView.remove(view: videoView)
        gridVideoStreams.index(of: streamId).apply({ gridVideoStreams.remove(at: $0)})
    }
    
    private func streamView(for streamId: UUID) -> UIView? {
        return gridView.gridSubviews.first {
            ($0 as? AVSIdentifierProvider)?.identifier == streamId.transportString()
        }
    }

}
