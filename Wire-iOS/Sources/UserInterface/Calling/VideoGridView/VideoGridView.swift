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
import Cartography
import UIKit
import WireDataModel
import WireSyncEngine
import avs

struct Stream: Equatable {
    let streamId: AVSClient
    let participantName: String?
    let microphoneState: MicrophoneState?
}

struct VideoStream: Equatable {
    let stream: Stream
    let isPaused: Bool
}

protocol VideoGridConfiguration {
    var floatingVideoStream: VideoStream? { get }
    var videoStreams: [VideoStream] { get }
    var networkQuality: NetworkQuality { get }
}

// Workaround to make the protocol equatable, it might be possible to conform VideoGridConfiguration
// to Equatable with Swift 4.1 and conditional conformances. Right now we would have to make
// the `VideoGridViewController` generic to work around the `Self` requirement of
// `Equatable` which we want to avoid.
extension VideoGridConfiguration {
    
    func isEqual(toConfiguration other: VideoGridConfiguration) -> Bool {
        return floatingVideoStream == other.floatingVideoStream &&
            videoStreams == other.videoStreams &&
            networkQuality == other.networkQuality
    }
    
}

extension ZMEditableUser {
    var selfStreamId: AVSClient {
        
        guard let selfUser = ZMUser.selfUser(),
              let userId = selfUser.remoteIdentifier,
              let clientId = selfUser.selfClient()?.remoteIdentifier
        else {
            fatal("Could not create self user stream which should always exist")
        }
        return AVSClient(userId: userId, clientId: clientId)
    }
}

extension CGSize {
    static let floatingPreviewSmall = CGSize(width: 108, height: 144)
    static let floatingPreviewLarge = CGSize(width: 150, height: 200)
    
    static func previewSize(for traitCollection: UITraitCollection) -> CGSize {
        switch traitCollection.horizontalSizeClass {
        case .regular: return .floatingPreviewLarge
        case .compact, .unspecified: return .floatingPreviewSmall
        @unknown default:
            return .floatingPreviewSmall
        }
    }
}

extension Notification.Name {
    static let videoGridVisibilityChanged = Notification.Name(rawValue: "VideoGridVisibilityChanged")
}

// MARK: - VideoGridViewController
final class VideoGridViewController: UIViewController {
    static let isCoveredKey = "isCovered"
    
    private var gridVideoStreams: [Stream] = []
    private let gridView = GridView()
    private let thumbnailViewController = PinnableThumbnailViewController()
    private let networkConditionView = NetworkConditionIndicatorView()
    private let mediaManager: AVSMediaManagerInterface
    private var selfPreviewView: SelfVideoPreviewView?

    var previewOverlay: UIView? {
        return thumbnailViewController.contentView
    }

    /// Update view visibility when this view controller is covered or not
    var isCovered: Bool = true {
        didSet {
            NotificationCenter.default.post(name: .videoGridVisibilityChanged, object: nil, userInfo: [VideoGridViewController.isCoveredKey: isCovered])
            
            displayIndicatorViewsIfNeeded()
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: {
                    self.networkConditionView.alpha = self.isCovered ? 0.0 : 1.0
            })
        }
    }

    var shouldHideNetworkCondition: Bool {
        return isCovered || configuration.networkQuality.isNormal
    }

    var configuration: VideoGridConfiguration {
        didSet {
            guard !configuration.isEqual(toConfiguration: oldValue) else { return }
            updateState()
        }
    }
    
    func displayIndicatorViewsIfNeeded() {
        networkConditionView.networkQuality = configuration.networkQuality
        networkConditionView.isHidden = shouldHideNetworkCondition
    }

    init(configuration: VideoGridConfiguration,
         mediaManager: AVSMediaManagerInterface = AVSMediaManager.sharedInstance()) {
        self.configuration = configuration
        self.mediaManager = mediaManager

        super.init(nibName: nil, bundle: nil)

        setupViews()
        createConstraints()
        updateState()
        displayIndicatorViewsIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup
extension VideoGridViewController {
    func setupViews() {
        gridView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        addToSelf(thumbnailViewController)

        view.addSubview(networkConditionView)

        networkConditionView.accessibilityIdentifier = "network-conditions-indicator"
    }

    func createConstraints() {
        gridView.fitInSuperview()
        [thumbnailViewController].forEach{ $0.view.fitInSuperview() }

        constrain(view, networkConditionView) { view, networkConditionView in
            networkConditionView.centerX == view.centerX
            networkConditionView.top == view.safeAreaLayoutGuideOrFallback.top + 24
        }
    }
}

// MARK: - Interface
extension VideoGridViewController {
    public func switchFillMode(location: CGPoint) {
        for view in gridView.videoStreamViews {
            let convertedRect = self.view.convert(view.frame, from: view.superview)
            if let videoPreviewView = view as? VideoPreviewView, convertedRect.contains(location) {
                videoPreviewView.switchFillMode()
                break
            }
        }
    }
}

// MARK: - Grid Update
extension VideoGridViewController {
    private func updateState() {
        Log.calling.debug("\nUpdating video configuration from:\n\(videoConfigurationDescription())")
        
        updateSelfPreview()
        
        updateFloatingVideo(with: configuration.floatingVideoStream)
        
        updateVideoGrid(with: configuration.videoStreams)
        
        displayIndicatorViewsIfNeeded()
        
        updateGridViewAxis()
        
        Log.calling.debug("\nUpdated video configuration to:\n\(videoConfigurationDescription())")
    }
    
    private func updateSelfPreview() {
        guard
            let selfStreamId = ZMUser.selfUser()?.selfStreamId,
            let selfStream = stream(with: selfStreamId) else {
                return
        }
        
        if selfPreviewView == nil {
            selfPreviewView = SelfVideoPreviewView(stream: selfStream)
        }
        
        if selfPreviewView?.stream != selfStream {
            selfPreviewView?.stream = selfStream
        }
    }
    
    private func updateFloatingVideo(with state: VideoStream?) {
        // No stream, remove floating video if there is any
        guard let state = state else {
            Log.calling.debug("Removing self video from floating preview")
            return thumbnailViewController.removeCurrentThumbnailContentView()
        }

        // We only support the self preview in the floating overlay
        guard state.stream.streamId == ZMUser.selfUser()?.selfStreamId else {
            return Log.calling.error("Invalid operation: Non self preview in overlay")
        }

        // We have a stream but don't have a preview view yet
        if nil == thumbnailViewController.contentView, let previewView = selfPreviewView {
            Log.calling.debug("Adding self video to floating preview")
            thumbnailViewController.setThumbnailContentView(previewView, contentSize: .previewSize(for: traitCollection))
        }
    }
    
    private func updateVideoGrid(with videoStreams: [VideoStream]) {
        let streams = videoStreams.map { $0.stream }
        let streamIds = streams.map { $0.streamId }
        
        let currentStreamIds = gridVideoStreams.map { $0.streamId }
        
        let removed = gridVideoStreams.filter { !streamIds.contains($0.streamId) }
        let added = streams.filter { !currentStreamIds.contains($0.streamId) }

        removed.forEach(removeStream)
        added.forEach(addStream)
        
        updateStates(with: videoStreams)
    }
    
    private func updateStates(with videoStreams: [VideoStream]) {
        videoStreams.forEach {
            let view = (streamView(for: $0.stream) as? VideoPreviewView)
            view?.isPaused = $0.isPaused
            view?.stream = $0.stream
        }
    }

    private func addStream(_ stream: Stream) {
        Log.calling.debug("Adding video stream: \(stream)")

        let view: UIView = {
            if stream.streamId == ZMUser.selfUser()?.selfStreamId, let previewView = selfPreviewView {
                return previewView
            } else {
                return VideoPreviewView(stream: stream)
            }
        }()

        view.translatesAutoresizingMaskIntoConstraints = false
        gridView.append(view: view)
        gridVideoStreams.append(stream)
    }

    private func removeStream(_ stream: Stream) {
        Log.calling.debug("Removing video stream: \(stream)")
        guard let videoView = streamView(for: stream) else {
            return Log.calling.debug("Failed to remove video stream \(stream) since view was not found")
        }
        gridView.remove(view: videoView)
        gridVideoStreams.firstIndex(of: stream).apply { gridVideoStreams.remove(at: $0) }
    }
}

// MARK: - Grid View Axis
extension VideoGridViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }
        thumbnailViewController.updateThumbnailContentSize(.previewSize(for: traitCollection), animated: false)
        updateGridViewAxis()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [updateGridViewAxis] _ in updateGridViewAxis() })
    }
    
    private func updateGridViewAxis() {
        let newAxis = gridAxis(for: traitCollection)
        guard newAxis != gridView.layoutDirection else { return }
        gridView.layoutDirection = newAxis
    }
    
    private func gridAxis(for traitCollection: UITraitCollection) -> UICollectionView.ScrollDirection {
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        switch (traitCollection.userInterfaceIdiom, traitCollection.horizontalSizeClass, isLandscape) {
        case (.pad, .regular, true): return .horizontal
        default: return .vertical
        }
    }
}

// MARK: - Helpers
extension VideoGridViewController {
    private func streamView(for stream: Stream) -> UIView? {
        return gridView.videoStreamViews.first {
            ($0 as? AVSIdentifierProvider)?.stream.streamId == stream.streamId
        }
    }
    
    private func stream(with streamId: AVSClient) -> Stream? {
        var stream = configuration.videoStreams.first(where: { $0.stream.streamId == streamId })?.stream
        
        if stream == nil && configuration.floatingVideoStream?.stream.streamId == streamId {
            stream = configuration.floatingVideoStream?.stream
        }
        
        return stream
    }
    
    private func videoConfigurationDescription() -> String {
        return """
        showing self preview: \(selfPreviewView != nil)
        videos in grid: [\(gridVideoStreams)]\n
        """
    }
}
