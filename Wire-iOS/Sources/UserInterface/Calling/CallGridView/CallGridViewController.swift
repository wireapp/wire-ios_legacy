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
import DifferenceKit

protocol CallGridViewControllerDelegate: class {
    func callGridViewController(_ viewController: CallGridViewController, perform action: CallGridAction)
}

final class CallGridViewController: SpinnerCapableViewController {
    // MARK: - Statics

    static let isCoveredKey = "isCovered"

    static var maxItemsPerPage: Int {
        switch CallingConfiguration.config.streamLimit {
        case .limit(amount: let amount): return amount
        case .noLimit: return 8
        }
    }

    // MARK: - Private Properties

    private var streams: [Stream] {
        if let stream = configuration.streams.first(where: { isMaximized(stream: $0) }) {
            return [stream]
        }
        return configuration.streams
    }

    private var pinchToZoomRule: PinchToZoomRule {
        PinchToZoomRule(isOneToOneCall: configuration.callHasTwoParticipants)
    }

    private var visibleClientsSharingVideo: [AVSClient] = []
    private var dataSource: [Stream] = []
    private let gridView = GridView(maxItemsPerPage: maxItemsPerPage)
    private let thumbnailViewController = PinnableThumbnailViewController()
    private let networkConditionView = NetworkConditionIndicatorView()
    private let pageIndicator = RoundedPageIndicator()
    private let topStack = UIStackView(axis: .vertical)
    private let mediaManager: AVSMediaManagerInterface
    private var viewCache = [AVSClient: OrientableView]()

    // MARK: - Public Properties

    // These two views are public for testing purposes
    var maximizedView: BaseCallParticipantView?
    var hintView = CallGridHintNotificationLabel()

    var configuration: CallGridViewControllerInput {
        didSet {
            guard !configuration.isEqual(toConfiguration: oldValue) else { return }
            dismissMaximizedViewIfNeeded(oldPresentationMode: oldValue.presentationMode)
            updateState()
        }
    }

    var previewOverlay: UIView? {
        return thumbnailViewController.contentView
    }

    /// Update view visibility when this view controller is covered or not
    var isCovered: Bool = true {
        didSet {
            guard isCovered != oldValue else { return }
            notifyVisibilityChanged()
            displayIndicatorViewsIfNeeded()
            animateNetworkConditionView()
            hintView.setMessageHidden(isCovered)
        }
    }

    var dismissSpinner: SpinnerCompletion?

    weak var delegate: CallGridViewControllerDelegate?

    // MARK: - Initialization

    init(configuration: CallGridViewControllerInput,
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

    override func viewDidLoad() {
        super.viewDidLoad()
        updateHint(for: .viewDidLoad)
    }

    // MARK: - Setup

    private func setupViews() {
        gridView.dataSource = self
        gridView.gridViewDelegate = self
        view.addSubview(gridView)

        addToSelf(thumbnailViewController)

        view.addSubview(topStack)
        topStack.alignment = .center
        topStack.spacing = 10
        topStack.addArrangedSubview(networkConditionView)
        topStack.addArrangedSubview(hintView)

        view.addSubview(pageIndicator)
        networkConditionView.accessibilityIdentifier = "network-conditions-indicator"
    }

    private func createConstraints() {
        [gridView, thumbnailViewController.view, topStack, hintView, networkConditionView, pageIndicator].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }

        [gridView, thumbnailViewController.view].forEach {
            $0.fitIn(view: view)
        }

        NSLayoutConstraint.activate([
            topStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topStack.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 24),
            topStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            topStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            pageIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            pageIndicator.heightAnchor.constraint(equalToConstant: CGFloat.pageIndicatorHeight),
            pageIndicator.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -22) // (pageIndicatorHeight / 2 + 10)
        ])

        pageIndicator.transform = pageIndicator.transform.rotated(by: .pi/2)
    }

    // MARK: - Public Interface

    public func handleDoubleTap(gesture: UIGestureRecognizer) {
        let location = gesture.location(in: gridView)
        toggleMaximized(view: streamView(at: location))
    }

    // MARK: - View maximization

    private func toggleMaximized(view: BaseCallParticipantView?) {
        guard let view = view else { return }
        guard allowMaximizationToggling(for: view.stream) else { return }

        let shouldMaximize = !isMaximized(stream: view.stream)

        maximizedView = shouldMaximize ? view : nil
        view.isMaximized = shouldMaximize
        updateGrid(with: streams)
        updateHint(for: .maximizationChanged(stream: view.stream, maximized: view.isMaximized))
    }

    private func allowMaximizationToggling(for stream: Stream) -> Bool {
        let isStreamScreenSharingOneToOne = gridIsOneToOneWithFloatingTile && stream.isScreenSharing
        let isStreamMinimizedAndNotSharingVideo = !isMaximized(stream: stream) && !stream.isSharingVideo

        return !isStreamScreenSharingOneToOne && !(isStreamMinimizedAndNotSharingVideo && gridHasOnlyOneTile)
    }

    private func isMaximized(stream: Stream?) -> Bool {
        guard
            let streamId = stream?.streamId,
            let maximizedStreamId = maximizedView?.stream.streamId
        else { return false }

        return streamId == maximizedStreamId
    }

    private func dismissMaximizedViewIfNeeded(oldPresentationMode: VideoGridPresentationMode) {
        guard oldPresentationMode != configuration.presentationMode else { return }
        maximizedView?.isMaximized = false
        maximizedView = nil
    }

    // MARK: - Hint

    func updateHint(for event: CallGridEvent) {
        switch event {
        case .viewDidLoad:
            hintView.show(hint: .fullscreen)
        case .configurationChanged where configuration.callHasTwoParticipants:
            guard
                let stream = configuration.streams.first,
                stream.isSharingVideo
            else { return }

            if stream.isScreenSharing {
                hintView.show(hint: .zoom)
            } else if isMaximized(stream: stream) {
                hintView.show(hint: .goBackOrZoom)
            }
        case .maximizationChanged(stream: let stream, maximized: let maximized):
            if maximized {
                hintView.show(hint: stream.isSharingVideo ? .goBackOrZoom : .goBack)
            } else {
                hintView.hideAndStopTimer()
            }
        default: break
        }
    }

    // MARK: - UI Update

    private func displayIndicatorViewsIfNeeded() {
        networkConditionView.networkQuality = configuration.networkQuality
        networkConditionView.isHidden = shouldHideNetworkCondition
    }

    private var shouldHideNetworkCondition: Bool {
        return isCovered || configuration.networkQuality.isNormal
    }

    private func notifyVisibilityChanged() {
        NotificationCenter.default.post(
            name: .videoGridVisibilityChanged,
            object: nil,
            userInfo: [CallGridViewController.isCoveredKey: isCovered]
        )
    }

    private func animateNetworkConditionView() {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: { self.networkConditionView.alpha = self.isCovered ? 0.0 : 1.0 }
        )
    }

    // MARK: - Grid Update

    private func updateState() {
        displaySpinnerIfNeeded()
        updateSelfCallParticipantView()
        updateFloatingView(with: configuration.floatingStream)
        updateGrid(with: streams)
        displayIndicatorViewsIfNeeded()
        updateGridViewAxis()
        updateHint(for: .configurationChanged)
        requestVideoStreamsIfNeeded(forPage: gridView.currentPage)
    }

    private func displaySpinnerIfNeeded() {
        guard
            configuration.presentationMode == .activeSpeakers,
            configuration.streams.isEmpty
        else {
            dismissSpinner?()
            return
        }

        showLoadingView(title: L10n.Localizable.Call.Grid.noActiveSpeakers)
    }

    private func updateSelfCallParticipantView() {
        guard let selfStreamId = ZMUser.selfUser()?.selfStreamId else { return }

        // No stream to show. Update the capture state.
        guard let selfStream = stream(with: selfStreamId) else {
            Log.calling.debug("updating capture state to \(configuration.videoState)")
            selfCallParticipantView?.updateCaptureState(with: configuration.videoState)
            return
        }

        if let view = selfCallParticipantView {
            view.stream = selfStream
            view.shouldShowActiveSpeakerFrame = configuration.shouldShowActiveSpeakerFrame
            view.shouldShowBorderWhenVideoIsStopped = shouldShowBorderWhenVideoIsStopped
        } else {
            viewCache[selfStreamId] = SelfCallParticipantView(
                stream: selfStream,
                isCovered: isCovered,
                shouldShowActiveSpeakerFrame: configuration.shouldShowActiveSpeakerFrame,
                shouldShowBorderWhenVideoIsStopped: shouldShowBorderWhenVideoIsStopped,
                pinchToZoomRule: pinchToZoomRule
            )
        }
    }

    private func updateFloatingView(with stream: Stream?) {
        // No stream, remove floating video if there is any.
        guard let stream = stream else {
            Log.calling.debug("Removing self video from floating preview")
            return thumbnailViewController.removeCurrentThumbnailContentView()
        }

        // We only support the self preview in the floating overlay.
        guard stream.streamId == ZMUser.selfUser()?.selfStreamId else {
            return Log.calling.error("Invalid operation: Non self preview in overlay")
        }

        // We have a stream but don't have a preview view yet.
        if nil == thumbnailViewController.contentView, let previewView = selfCallParticipantView {
            Log.calling.debug("Adding self video to floating preview")
            thumbnailViewController.setThumbnailContentView(previewView, contentSize: .previewSize(for: traitCollection))
        }
    }

    private func updateGrid(with newStreams: [Stream]) {
        let changeSet = StagedChangeset(source: dataSource, target: newStreams)

        UIView.performWithoutAnimation {
            gridView.reload(using: changeSet) { dataSource = $0 }
        }

        pageIndicator.numberOfPages = gridView.numberOfPages
        updateStates(with: dataSource)
        pruneCache()
    }

    private func updateStates(with streams: [Stream]) {
        streams.forEach {
            let view = (cachedStreamView(for: $0) as? CallParticipantView)

            view?.stream = $0
            view?.shouldShowActiveSpeakerFrame = configuration.shouldShowActiveSpeakerFrame
            view?.isPaused = $0.isPaused
            view?.pinchToZoomRule = pinchToZoomRule
            view?.shouldShowBorderWhenVideoIsStopped = shouldShowBorderWhenVideoIsStopped
        }
    }

    private func pruneCache() {
        let existingStreamsIds = Set(viewCache.keys)
        let currentStreamsIds = configuration.allStreamIds

        for deletedStreamId in existingStreamsIds.subtracting(currentStreamsIds) {
            guard deletedStreamId != ZMUser.selfUser()?.selfStreamId else { return }
            viewCache[deletedStreamId]?.removeFromSuperview()
            viewCache.removeValue(forKey: deletedStreamId)
        }
    }

    func requestVideoStreamsIfNeeded(forPage page: Int) {
        let startIndex = page * gridView.maxItemsPerPage
        var endIndex = startIndex + gridView.maxItemsPerPage
        endIndex = min(endIndex, dataSource.count)

        guard dataSource.indices.contains(startIndex),
              endIndex > startIndex
        else { return }

        let clients = dataSource[startIndex..<endIndex]
            .filter(\.isSharingVideo)
            .map(\.streamId)

        guard Set(clients) != Set(visibleClientsSharingVideo) else { return }

        delegate?.callGridViewController(self, perform: .requestVideoStreamsForClients(clients))
        visibleClientsSharingVideo = clients
    }

    // MARK: - Grid View Axis

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.didSizeClassChange(from: previousTraitCollection) else { return }
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
        case (.pad, .regular, true), (.phone, .regular, true):
            return .horizontal
        default:
            return .vertical
        }
    }

    // MARK: - Helpers

    private var shouldShowBorderWhenVideoIsStopped: Bool {
       !gridHasOnlyOneTile && !gridIsOneToOneWithFloatingTile
    }

    private var gridHasOnlyOneTile: Bool {
        configuration.streams.count == 1
    }

    private var gridIsOneToOneWithFloatingTile: Bool {
        gridHasOnlyOneTile && configuration.floatingStream != nil
    }

    private func cachedStreamView(for stream: Stream) -> OrientableView? {
        return viewCache[stream.streamId]
    }

    private func streamView(at location: CGPoint) -> BaseCallParticipantView? {
        guard let indexPath = gridView.indexPathForItem(at: location) else {
            return nil
        }
        return cachedStreamView(for: dataSource[indexPath.row]) as? BaseCallParticipantView
    }

    private func stream(with streamId: AVSClient) -> Stream? {
        var stream = configuration.streams.first(where: { $0.streamId == streamId })

        if stream == nil && configuration.floatingStream?.streamId == streamId {
            stream = configuration.floatingStream
        }

        return stream
    }

    private var selfCallParticipantView: SelfCallParticipantView? {
        guard let selfStreamId = ZMUser.selfUser()?.selfStreamId else {
            return nil
        }
        return viewCache[selfStreamId] as? SelfCallParticipantView
    }

}

// MARK: - UICollectionViewDataSource

extension CallGridViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridCell.reuseIdentifier, for: indexPath) as? GridCell else {
            return UICollectionViewCell()
        }

        let stream = dataSource[indexPath.row]
        cell.add(streamView: streamView(for: stream))

        return cell
    }

    private func streamView(for stream: Stream) -> OrientableView {
        let streamId = stream.streamId

        if let streamView = cachedStreamView(for: stream) {
            return streamView
        } else {
            let view = CallParticipantView(
                stream: stream,
                isCovered: isCovered,
                shouldShowActiveSpeakerFrame: configuration.shouldShowActiveSpeakerFrame,
                shouldShowBorderWhenVideoIsStopped: shouldShowBorderWhenVideoIsStopped,
                pinchToZoomRule: pinchToZoomRule
            )
            viewCache[streamId] = view
            return view
        }
    }
}

// MARK: - GridViewDelegate

extension CallGridViewController: GridViewDelegate {
    func gridView(_ gridView: GridView, didChangePageTo page: Int) {
        pageIndicator.currentPage = page
        requestVideoStreamsIfNeeded(forPage: page)
    }
}

// MARK: - Test Helpers

extension CallGridViewController {
    /// used by snapshot tests
    func hideHintView() {
        hintView.hideAndStopTimer()
    }
}

// MARK: - Extensions

extension ZMEditableUser {
    var selfStreamId: AVSClient {

        guard
            let selfUser = ZMUser.selfUser(),
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
        case .regular:
            return .floatingPreviewLarge
        case .compact, .unspecified:
            return .floatingPreviewSmall
        @unknown default:
            return .floatingPreviewSmall
        }
    }

}

extension Notification.Name {

    static let videoGridVisibilityChanged = Notification.Name(rawValue: "VideoGridVisibilityChanged")

}

fileprivate extension CGFloat {
    static let pageIndicatorHeight: CGFloat = 24
}
