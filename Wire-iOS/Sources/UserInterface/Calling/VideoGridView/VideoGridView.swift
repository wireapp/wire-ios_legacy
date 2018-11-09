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

struct ParticipantVideoState: Equatable {
    let stream: UUID
    let isPaused: Bool
}

protocol VideoGridConfiguration {
    var floatingVideoStream: ParticipantVideoState? { get }
    var videoStreams: [ParticipantVideoState] { get }
    var isMuted: Bool { get }
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
            isMuted == other.isMuted &&
            networkQuality == other.networkQuality
    }
    
}

fileprivate extension CGSize {
    static let floatingPreviewSmall = CGSize(width: 108, height: 144)
    static let floatingPreviewLarge = CGSize(width: 150, height: 200)
    
    static func previewSize(for traitCollection: UITraitCollection) -> CGSize {
        switch traitCollection.horizontalSizeClass {
        case .regular: return .floatingPreviewLarge
        case .compact, .unspecified: return .floatingPreviewSmall
        }
    }
}


class VideoGridViewController: UIViewController {

    private var gridVideoStreams: [UUID] = []
    private let gridView = GridView()
    private let thumbnailViewController = PinnableThumbnailViewController()
    private let muteIndicatorView = MuteIndicatorView()
    private let networkConditionView = NetworkConditionIndicatorView()
    fileprivate let mediaManager: AVSMediaManagerInterface

    var previewOverlay: UIView? {
        return thumbnailViewController.contentView
    }

    private var selfPreviewView: SelfVideoPreviewView?

    /// Update view visibility when this view controller is covered or not
    var isCovered: Bool = true {
        didSet {
            displayIndicatorViewsIfNeeded()
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: {
                    self.muteIndicatorView.alpha = self.isCovered ? 0.0 : 1.0
                    self.networkConditionView.alpha = self.isCovered ? 0.0 : 1.0
            },
                completion: nil
            )
        }
    }

    func displayIndicatorViewsIfNeeded() {
        networkConditionView.networkQuality = configuration.networkQuality
        networkConditionView.isHidden = shouldHideNetworkCondition
        muteIndicatorView.isHidden = shouldHideMuteIndicator
    }

    var shouldHideMuteIndicator: Bool {
        return isCovered || !configuration.isMuted
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

    func setupViews() {
        gridView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        addToSelf(thumbnailViewController)

        view.addSubview(muteIndicatorView)
        view.addSubview(networkConditionView)
    }

    func createConstraints() {
        gridView.fitInSuperview()
        [thumbnailViewController].forEach{ $0.view.fitInSuperview() }

        constrain(view, muteIndicatorView, networkConditionView) { view, muteIndicatorView, networkConditionView in
            let bottomOffset: CGFloat = UIScreen.safeArea.bottom + (UIScreen.hasNotch ? 8 : 24)
            
            muteIndicatorView.centerX == view.centerX
            muteIndicatorView.bottom == view.bottom - bottomOffset
            muteIndicatorView.height == CGFloat.MuteIndicator.containerHeight
            networkConditionView.centerX == view.centerX
            networkConditionView.top == view.safeAreaLayoutGuideOrFallback.top + 24
        }
    }

    public func switchFillMode(location: CGPoint) {
        for view in gridView.gridSubviews {
            let convertedRect = self.view.convert(view.frame, from: view.superview)
            if let videoPreviewView = view as? VideoPreviewView, convertedRect.contains(location) {
                videoPreviewView.switchFillMode()
                break
            }
        }
    }

    func updateState() {
        Log.calling.debug("\nUpdating video configuration from:\n\(videoConfigurationDescription())")

        let selfStreamId = ZMUser.selfUser().remoteIdentifier!
        let selfInGrid = configuration.videoStreams.contains { $0.stream == selfStreamId }
        let selfInFloatingOverlay = nil != configuration.floatingVideoStream
        let isShowingSelf = selfInGrid || selfInFloatingOverlay

        // Create self preview if there is none but we should show it
        if isShowingSelf && nil == selfPreviewView {
            selfPreviewView = SelfVideoPreviewView(identifier: selfStreamId.transportString())
            selfPreviewView?.translatesAutoresizingMaskIntoConstraints = false
        }

        // It's important to remove remove the existing preview view before moving it to the grid/floating location
        if selfInGrid {
            updateFloatingVideo(with: configuration.floatingVideoStream)
            updateVideoGrid(with: configuration.videoStreams)
        } else {
            updateVideoGrid(with: configuration.videoStreams)
            updateFloatingVideo(with: configuration.floatingVideoStream)
        }

        // Clear self preview we we shouldn't show it anymore
        if !isShowingSelf, let _ = selfPreviewView {
            selfPreviewView = nil
        }

        displayIndicatorViewsIfNeeded()
        
        // Update grid view axis
        updateGridViewAxis()

        Log.calling.debug("\nUpdated video configuration to:\n\(videoConfigurationDescription())")
    }

    private func updateFloatingVideo(with state: ParticipantVideoState?) {
        // No stream, remove floating video if there is any
        guard let state = state else {
            Log.calling.debug("Removing self video from floating preview")
            return thumbnailViewController.removeCurrentThumbnailContentView()
        }

        // We only support the self preview in the floating overlay
        guard state.stream == ZMUser.selfUser().remoteIdentifier else {
            return Log.calling.error("Invalid operation: Non self preview in overlay")
        }

        // We have a stream but don't have a preview view yet
        if nil == thumbnailViewController.contentView, let previewView = selfPreviewView {
            Log.calling.debug("Adding self video to floating preview")
            thumbnailViewController.setThumbnailContentView(previewView, contentSize: .previewSize(for: traitCollection))
        }
    }

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

    private func gridAxis(for traitCollection: UITraitCollection) -> NSLayoutConstraint.Axis {
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        switch (traitCollection.userInterfaceIdiom, traitCollection.horizontalSizeClass, isLandscape) {
        case (.pad, .regular, true): return .horizontal
        default: return .vertical
        }
    }

    private func videoConfigurationDescription() -> String {
        return """
        showing self preview: \(selfPreviewView != nil)
        videos in grid: [\(gridVideoStreams)]\n
        """
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
        Log.calling.debug("Adding video stream: \(streamId)")

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
        Log.calling.debug("Removing video stream: \(streamId)")
        guard let videoView = streamView(for: streamId) else {
            return Log.calling.debug("Failed to remove video stream \(streamId) since view was not found")
        }
        gridView.remove(view: videoView)
        gridVideoStreams.index(of: streamId).apply { gridVideoStreams.remove(at: $0) }
    }

    private func streamView(for streamId: UUID) -> UIView? {
        return gridView.gridSubviews.first {
            ($0 as? AVSIdentifierProvider)?.identifier == streamId.transportString()
        }
    }

}
