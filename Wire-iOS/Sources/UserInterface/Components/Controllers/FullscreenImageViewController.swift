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
import FLAnimatedImage
import UIKit
import WireSyncEngine

private let zmLog = ZMSLog(tag: "UI")

protocol ScreenshotProvider: UIViewController {
    func backgroundScreenshot(for fullscreenController: FullscreenImageViewController) -> UIView?
}

protocol MenuVisibilityController: UIViewController {
    var menuVisible: Bool { get }
    func fadeAndHideMenu(_ hidden: Bool)
}

final class FullscreenImageViewController: UIViewController {
    static let kZoomScaleDelta: CGFloat = 0.0003

    let message: ZMConversationMessage
    weak var delegate: (ScreenshotProvider & MenuVisibilityController)?
    var swipeToDismiss = true {
        didSet {
            panRecognizer.isEnabled = swipeToDismiss
        }
    }

    var showCloseButton = true
    var dismissAction: DismissAction?

    private var lastZoomScale: CGFloat = 0
    var imageView: UIImageView?
    let scrollView: UIScrollView = UIScrollView()
    var snapshotBackgroundView: UIView?
    private var minimumDismissMagnitude: CGFloat = 0
    private lazy var actionController: ConversationMessageActionController = {
        return ConversationMessageActionController(responder: self, message: message, context: .collection, view: scrollView)
    }()

    // MARK: pull to dismiss
    private var isDraggingImage = false
    private var imageViewStartingTransform: CGAffineTransform = .identity
    private var imageDragStartingPoint: CGPoint = .zero
    private var imageDragOffsetFromActualTranslation: UIOffset = .zero
    private var imageDragOffsetFromImageCenter: UIOffset = .zero
    private lazy var animator: UIDynamicAnimator = {
        return UIDynamicAnimator(referenceView: scrollView)
    }()
    private var attachmentBehavior: UIAttachmentBehavior?
    private var initialImageViewBounds = CGRect.zero
    private var initialImageViewCenter = CGPoint.zero
    private let panRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer()

    private var highlightLayer: CALayer?

    private let tapGestureRecognzier = UITapGestureRecognizer()
    private let doubleTapGestureRecognizer = UITapGestureRecognizer()
    private let longPressGestureRecognizer = UILongPressGestureRecognizer()

    private var isShowingChrome = true
    private var assetWriteInProgress = false
    private var forcePortraitMode = false {
        didSet {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    private var messageObserverToken: NSObjectProtocol?

    // MARK: - init
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: ZMConversationMessage) {
        self.message = message

        super.init(nibName: nil, bundle: nil)

        setupScrollView()
        updateForMessage()

        setupGestureRecognizers()
        setupStyle()
        setupObservers()
    }

    // MARK: - View life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if parent != nil {
            updateZoom()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator?) {
        guard let imageSize = imageView?.image?.size else { return }

        let isImageZoomedToMax = scrollView.zoomScale == scrollView.maximumZoomScale

        let isImageZoomed = abs(scrollView.minimumZoomScale - scrollView.zoomScale) > FullscreenImageViewController.kZoomScaleDelta
        updateScrollViewZoomScale(viewSize: size, imageSize: imageSize)

        let animationBlock: () -> Void = {
            if isImageZoomedToMax {
                self.scrollView.zoomScale = self.scrollView.maximumZoomScale
            } else if isImageZoomed == false {
                self.scrollView.zoomScale = self.scrollView.minimumZoomScale
            }
        }

        if let coordinator = coordinator {
            coordinator.animate(alongsideTransition: { (_) in
                animationBlock()
            })
        } else {
            animationBlock()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerScrollViewContent()
    }

    // MARK: - Overrides

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    // MARK: - Dismiss

    private func dismiss(_ completion: Completion? = nil) {
        if nil != dismissAction {
            dismissAction?(completion)
        } else if nil != navigationController {
            navigationController?.popViewController(animated: true)
            completion?()
        } else {
            dismiss(animated: true, completion: completion)
        }
    }

    private func updateForMessage() {
        if message.isObfuscated ||
           message.hasBeenDeleted {
            removeImage()
        } else {
            loadImageAndSetupImageView()
        }
    }

    func removeImage() {
        imageView?.removeFromSuperview()
        imageView = nil
    }

    // MARK: - setup

    private func setupStyle() {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            minimumDismissMagnitude = 2500
        default:
            minimumDismissMagnitude = 250
        }

        view.backgroundColor = .from(scheme: .background)
    }

    private func setupSnapshotBackgroundView() {
        guard let snapshotBackgroundView = delegate?.backgroundScreenshot(for: self) else { return }

        snapshotBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(snapshotBackgroundView)

        let topBarHeight: CGFloat = navigationController?.navigationBar.frame.maxY ?? 0

        snapshotBackgroundView.pinToSuperview(anchor: .top, inset: topBarHeight)
        snapshotBackgroundView.pinToSuperview(anchor: .leading)
        snapshotBackgroundView.setDimensions(size: UIScreen.main.bounds.size)

        snapshotBackgroundView.alpha = 0

        self.snapshotBackgroundView = snapshotBackgroundView
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        scrollView.fitInSuperview()

        if #available(iOS 11, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }

        scrollView.delegate = self
        scrollView.accessibilityIdentifier = "fullScreenPage"

    }

    fileprivate func setupObservers() {
        guard let userSession = ZMUserSession.shared() else { return }

        messageObserverToken = MessageChangeInfo.add(observer: self, for: message, userSession: userSession)
    }

    private func setupGestureRecognizers() {
        tapGestureRecognzier.addTarget(self, action: #selector(didTapBackground(_:)))

        let delayedTouchBeganRecognizer = scrollView.gestureRecognizers?[0]
        delayedTouchBeganRecognizer?.require(toFail: tapGestureRecognzier)

        view.addGestureRecognizer(tapGestureRecognzier)

        doubleTapGestureRecognizer.addTarget(self, action: #selector(handleDoubleTap(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGestureRecognizer)

        longPressGestureRecognizer.addTarget(self, action: #selector(handleLongPress(_:)))
        view.addGestureRecognizer(longPressGestureRecognizer)

        panRecognizer.maximumNumberOfTouches = 1
        panRecognizer.delegate = self
        panRecognizer.isEnabled = swipeToDismiss
        panRecognizer.addTarget(self, action: #selector(dismissingPanGestureRecognizerPanned(_:)))
        scrollView.addGestureRecognizer(panRecognizer)

        doubleTapGestureRecognizer.require(toFail: panRecognizer)
        tapGestureRecognzier.require(toFail: panRecognizer)
        delayedTouchBeganRecognizer?.require(toFail: panRecognizer)

        tapGestureRecognzier.require(toFail: doubleTapGestureRecognizer)
    }

    // MARK: - Utilities, custom UI
    func performSaveImageAnimation(from saveView: UIView) {
        guard let imageView = imageView else { return }

        let ghostImageView = UIImageView(image: imageView.image)
        ghostImageView.contentMode = .scaleAspectFit
        ghostImageView.translatesAutoresizingMaskIntoConstraints = false

        ghostImageView.frame = view.convert(imageView.frame, from: imageView.superview)
        view.addSubview(ghostImageView)

        let targetCenter = view.convert(saveView.center, from: saveView.superview)

        UIView.animate(easing: .easeInExpo, duration: 0.55, animations: {
            ghostImageView.center = targetCenter
            ghostImageView.alpha = 0
            ghostImageView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }) { _ in
            ghostImageView.removeFromSuperview()
        }
    }

    private func loadImageAndSetupImageView() {
        let imageIsAnimatedGIF = message.imageMessageData?.isAnimatedGIF
        let imageData = message.imageMessageData?.imageData

        DispatchQueue.global(qos: .default).async(execute: { [weak self] in

            let mediaAsset: MediaAsset

            if imageIsAnimatedGIF == true,
               let gifImageData = imageData {
                mediaAsset = FLAnimatedImage(animatedGIFData: gifImageData)
            } else if let image = imageData.map(UIImage.init) as? UIImage {
                mediaAsset = image
            } else {
                return
            }

            DispatchQueue.main.async(execute: {
                if let parentSize = self?.parent?.view.bounds.size {
                    self?.setupImageView(image: mediaAsset, parentSize: parentSize)
                }
            })
        })
    }

    // MARK: - PullToDismiss
    @objc
    private func dismissingPanGestureRecognizerPanned(_ panner: UIPanGestureRecognizer) {

        let translation = panner.translation(in: panner.view)
        let locationInView = panner.location(in: panner.view)
        let velocity = panner.velocity(in: panner.view)
        let vectorDistance = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))

        switch panner.state {
        case .began:
            isDraggingImage = imageView?.frame.contains(locationInView) == true
            if isDraggingImage {
                initiateImageDrag(fromLocation: locationInView, translationOffset: .zero)
            }
        case .changed:
            if isDraggingImage {
                var newAnchor = imageDragStartingPoint
                newAnchor.x += (translation.x) + imageDragOffsetFromActualTranslation.horizontal
                newAnchor.y += (translation.y) + imageDragOffsetFromActualTranslation.vertical
                attachmentBehavior?.anchorPoint = newAnchor
                if let center = imageView?.center { updateBackgroundColor(imageViewCenter: center)
                }
            } else {
                isDraggingImage = imageView?.frame.contains(locationInView) == true
                if isDraggingImage {
                    let translationOffset = UIOffset(horizontal: -1 * (translation.x), vertical: -1 * (translation.y))
                    initiateImageDrag(fromLocation: locationInView, translationOffset: translationOffset)
                }
            }
        default:
            if vectorDistance > 300 && abs(translation.y) > 100 {
                if isDraggingImage {
                    dismissImageFlicking(withVelocity: velocity)
                } else {
                    dismiss()
                }
            } else {
                cancelCurrentImageDrag(animated: true)
            }
        }
    }

    // MARK: - Dynamic Image Dragging
    private func initiateImageDrag(fromLocation panGestureLocationInView: CGPoint, translationOffset: UIOffset) {
        guard let imageView = imageView else { return }
        setupSnapshotBackgroundView()
        isShowingChrome = false

        initialImageViewCenter = imageView.center
        let nearLocationInView = CGPoint(x: (panGestureLocationInView.x - initialImageViewCenter.x) * 0.1 + initialImageViewCenter.x,
                                         y: (panGestureLocationInView.y - initialImageViewCenter.y) * 0.1 + initialImageViewCenter.y)

        imageDragStartingPoint = nearLocationInView
        imageDragOffsetFromActualTranslation = translationOffset

        let anchor = imageDragStartingPoint
        let offset = UIOffset(horizontal: nearLocationInView.x - initialImageViewCenter.x, vertical: nearLocationInView.y - initialImageViewCenter.y)
        imageDragOffsetFromImageCenter = offset

        // Proxy object is used because the UIDynamics messing up the zoom level transform on imageView
        let proxy = DynamicsProxy()
        imageViewStartingTransform = imageView.transform
        proxy.center = imageView.center
        initialImageViewBounds = view.convert(imageView.bounds, from: imageView)
        proxy.bounds = initialImageViewBounds

        attachmentBehavior = UIAttachmentBehavior(item: proxy, offsetFromCenter: offset, attachedToAnchor: anchor)
        attachmentBehavior?.damping = 1
        attachmentBehavior?.action = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.imageView?.center = CGPoint(x: weakSelf.imageView?.center.x ?? 0.0, y: proxy.center.y)
            weakSelf.imageView?.transform = proxy.transform.concatenating(weakSelf.imageViewStartingTransform)
        }
        if let attachmentBehavior = attachmentBehavior {
            animator.addBehavior(attachmentBehavior)
        }

        let modifier = UIDynamicItemBehavior(items: [proxy])
        modifier.density = 10000000
        modifier.resistance = 1000
        modifier.elasticity = 0
        modifier.friction = 0
        animator.addBehavior(modifier)
    }

    private func cancelCurrentImageDrag(animated: Bool) {
        animator.removeAllBehaviors()
        attachmentBehavior = nil
        isDraggingImage = false

        if !animated {
            imageView?.transform = imageViewStartingTransform
            imageView?.center = initialImageViewCenter
        } else {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: { [weak self] in
                guard let weakSelf = self else { return }
                if !weakSelf.isDraggingImage {
                    weakSelf.imageView?.transform = weakSelf.imageViewStartingTransform
                    weakSelf.updateBackgroundColor(progress: 0)
                    if !weakSelf.scrollView.isDragging && !weakSelf.scrollView.isDecelerating {
                        weakSelf.imageView?.center = weakSelf.initialImageViewCenter
                    }
                }
            })
        }
    }

    private func dismissImageFlicking(withVelocity velocity: CGPoint) {
        guard let imageView = imageView else { return }
        // Proxy object is used because the UIDynamics messing up the zoom level transform on imageView
        let proxy = DynamicsProxy()
        proxy.center = imageView.center
        proxy.bounds = initialImageViewBounds
        isDraggingImage = false

        let push = UIPushBehavior(items: [proxy], mode: .instantaneous)
        push.pushDirection = CGVector(dx: velocity.x * 0.1, dy: velocity.y * 0.1)
        if let attachmentBehavior = attachmentBehavior {
            push.setTargetOffsetFromCenter(UIOffset(horizontal: attachmentBehavior.anchorPoint.x - initialImageViewCenter.x, vertical: attachmentBehavior.anchorPoint.y - initialImageViewCenter.y), for: imageView)
        }

        push.magnitude = max(minimumDismissMagnitude, abs(velocity.y) / 6)

        push.action = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.imageView?.center = CGPoint(x: imageView.center.x, y: proxy.center.y)

            weakSelf.updateBackgroundColor(imageViewCenter: imageView.center)
            if weakSelf.imageViewIsOffscreen {
                UIView.animate(withDuration: 0.1, animations: {
                    weakSelf.updateBackgroundColor(progress: 1)
                }) { _ in
                    weakSelf.animator.removeAllBehaviors()
                    weakSelf.attachmentBehavior = nil
                    weakSelf.imageView?.removeFromSuperview()
                    weakSelf.dismiss()
                }
            }
        }
        if let attachmentBehavior = attachmentBehavior {
            animator.removeBehavior(attachmentBehavior)
        }
        animator.addBehavior(push)
    }

    private var imageViewIsOffscreen: Bool {
        // tiny inset threshold for small zoom
        return !view.bounds.insetBy(dx: -10, dy: -10).intersects(view.convert(imageView?.bounds ?? .zero, from: imageView))
    }

    private func updateBackgroundColor(imageViewCenter: CGPoint) {
        let progress: CGFloat = abs(imageViewCenter.y - initialImageViewCenter.y) / 1000
        updateBackgroundColor(progress: progress)
    }

    func updateBackgroundColor(progress: CGFloat) {
        let orientation = UIDevice.current.orientation
        let interfaceIdiom = UIDevice.current.userInterfaceIdiom
        if orientation.isLandscape && interfaceIdiom == .phone {
            return
        }
        var newAlpha = 1 - progress
        if isDraggingImage {
            newAlpha = max(newAlpha, 0.8)
        }

        if let snapshotBackgroundView = snapshotBackgroundView {
            snapshotBackgroundView.alpha = 1 - newAlpha
        } else {
            view.backgroundColor = view.backgroundColor?.withAlphaComponent(newAlpha)
        }
    }

    // MARK: - Gesture Handling
    private let fadeAnimationDuration: TimeInterval = 0.33

    private var isImageViewHightlighted: Bool {
        if let highlightLayer = highlightLayer,
            imageView?.layer.sublayers?.contains(highlightLayer) == true {
            return true
        }

        return false
    }

    func setSelectedByMenu(_ selected: Bool, animated: Bool) {
        zmLog.debug("Setting selected: \(selected) animated: \(animated)")

        if selected {

            guard !isImageViewHightlighted else {
                return
            }

            if let highlightLayer = highlightLayer {
                guard imageView?.layer.sublayers?.contains(highlightLayer) == false else {
                    return
                }
            }

            let layer = CALayer()
            layer.backgroundColor = UIColor.clear.cgColor
            layer.frame = CGRect(x: 0,
                                 y: 0,
                                 width: (imageView?.frame.size.width ?? 0) / scrollView.zoomScale,
                                 height: (imageView?.frame.size.height ?? 0) / scrollView.zoomScale)
            imageView?.layer.insertSublayer(layer, at: 0)

            let blackLayerClosure: Completion = {
                self.highlightLayer?.backgroundColor = UIColor.black.withAlphaComponent(0.4).cgColor
            }

            highlightLayer = layer

            animated ?
                UIView.animate(withDuration: fadeAnimationDuration, animations: blackLayerClosure) :
                blackLayerClosure()
        } else {

            let removeLayerClosure: Completion = {
                self.highlightLayer?.removeFromSuperlayer()
                self.highlightLayer = nil
            }

            if animated {
                UIView.animate(withDuration: fadeAnimationDuration, animations: {
                    self.highlightLayer?.backgroundColor = UIColor.clear.cgColor
                }) { finished in
                    if finished {
                        removeLayerClosure()
                    }
                }
            } else {
                highlightLayer?.backgroundColor = UIColor.clear.cgColor
                removeLayerClosure()
            }
        }
    }

    @objc
    private func didTapBackground(_ tapper: UITapGestureRecognizer?) {
        isShowingChrome = !isShowingChrome
        setSelectedByMenu(false, animated: false)
        UIMenuController.shared.isMenuVisible = false
        delegate?.fadeAndHideMenu(delegate?.menuVisible == false)
    }

    @objc
    private func handleLongPress(_ longPressRecognizer: UILongPressGestureRecognizer?) {
        guard longPressRecognizer?.state == .began else { return }

        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide(_:)), name: UIMenuController.didHideMenuNotification, object: nil)

        let menuController = UIMenuController.shared
        menuController.menuItems = ConversationMessageActionController.allMessageActions

        prepareShowingMenu()

        if #available(iOS 13.0, *) {

            if let imageView = imageView {
                let frame = imageView.frame
                menuController.showMenu(from: imageView, rect: frame)
            }
        } else {
            if let imageView = imageView {
                menuController.setTargetRect(imageView.bounds, in: imageView)
            }
            menuController.setMenuVisible(true, animated: true)
        }
        setSelectedByMenu(true, animated: true)
    }

    private func hideMenu() {
        if #available(iOS 13.0, *) {
            UIMenuController.shared.hideMenu()
        } else {
            UIMenuController.shared.isMenuVisible = false
        }
    }

    @objc
    func handleDoubleTap(_ doubleTapper: UITapGestureRecognizer) {
        setSelectedByMenu(false, animated: false)

        guard let image = imageView?.image else { return }

        hideMenu()

        /// Notice: fix the case the the image is just fit on the screen and call scrollView.zoom causes images move outside the frame issue
        guard scrollView.minimumZoomScale != scrollView.maximumZoomScale else {
            return
        }

        let scaleDiff: CGFloat = scrollView.zoomScale - scrollView.minimumZoomScale

        // image view in minimum zoom scale, zoom in to a 50 x 50 rect
        if scaleDiff < FullscreenImageViewController.kZoomScaleDelta {
            // image is smaller than screen bound and zoom sclae is max(1), do not zoom in
            let point = doubleTapper.location(in: doubleTapper.view)

            let zoomLength = image.size.longestLength < 50 ? image.size.longestLength : 50

            let zoomRect = CGRect(x: point.x - zoomLength / 2, y: point.y - zoomLength / 2, width: zoomLength, height: zoomLength)
            let finalRect = imageView?.convert(zoomRect, from: doubleTapper.view)

            scrollView.zoom(to: finalRect ?? .zero,
                            animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }

    // MARK: - Zoom scale

    func updateScrollViewZoomScale(viewSize: CGSize, imageSize: CGSize) {
        scrollView.minimumZoomScale = viewSize.minZoom(imageSize: imageSize)

        // if the image is small than the screen size, max zoom level is "zoom to fit screen"
        if viewSize.contains(imageSize) {
            scrollView.maximumZoomScale = min(viewSize.height / imageSize.height, viewSize.width / imageSize.width)
        } else {
            scrollView.maximumZoomScale = 1
        }
    }

    func updateZoom() {
        guard let size = parent?.view?.frame.size else { return }
        updateZoom(withSize: size)
    }

    /// Zoom to show as much image as possible unless image is smaller than screen
    ///
    /// - Parameter size: size of the view which contains imageView
    func updateZoom(withSize size: CGSize) {
        guard let image = imageView?.image else { return }
        guard !(size.width == 0 && size.height == 0) else { return }

        var minZoom = size.minZoom(imageSize: image.size)

        // Force scrollViewDidZoom fire if zoom did not change
        if minZoom == lastZoomScale {
            minZoom += 0.000001
        }
        scrollView.zoomScale = minZoom
        lastZoomScale = minZoom
    }

    // MARK: - Image view

    /// Setup image view(UIImageView or FLAnimatedImageView) for given MediaAsset
    ///
    /// - Parameters:
    ///   - image: a MediaAsset object contains GIF or other images
    ///   - parentSize: parent view's size
    func setupImageView(image: MediaAsset, parentSize: CGSize) {
        let imageView = image.imageView

        imageView.clipsToBounds = true
        imageView.layer.allowsEdgeAntialiasing = true
        self.imageView = imageView as? UIImageView
        imageView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(imageView)
        scrollView.contentSize = self.imageView?.image?.size ?? .zero

        updateScrollViewZoomScale(viewSize: parentSize, imageSize: image.size)
        updateZoom(withSize: parentSize)

        centerScrollViewContent()
    }
}

extension FullscreenImageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let imageViewRect = view.convert(imageView?.bounds ?? CGRect.zero, from: imageView)

        // image view is not contained within view
        if !view.bounds.insetBy(dx: -10, dy: -10).contains(imageViewRect) {
            return false
        }

        if gestureRecognizer == panRecognizer {
            // touch is not within image view
            if !imageViewRect.contains(panRecognizer.location(in: view)) {
                return false
            }

            let offset = panRecognizer.translation(in: view)

            return abs(offset.y) > abs(offset.x)
        } else {
            return true
        }
    }

    // MARK: - Actions
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return actionController.canPerformAction(action)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return actionController
    }

    @objc
    private func menuDidHide(_ notification: Notification?) {
        NotificationCenter.default.removeObserver(self, name: UIMenuController.didHideMenuNotification, object: nil)
        setSelectedByMenu(false, animated: true)
    }
}

// MARK: - MessageActionResponder

extension FullscreenImageViewController: MessageActionResponder {
    func perform(action: MessageAction, for message: ZMConversationMessage!, view: UIView) {
        switch action {
        case .forward:
            perform(action: action)
        case .showInConversation,
             .reply:
            dismiss(animated: true) {
                self.perform(action: action)
            }
        case .openDetails:
            let detailsViewController = MessageDetailsViewController(message: message)
            present(detailsViewController, animated: true)
        default:
            perform(action: action)
        }
    }

    fileprivate func perform(action: MessageAction) {
        let sourceView: UIView

        /// iPad popover points to delete button of container is availible. The scrollView occupies most of the screen area and the popover is compressed.
        if action == .delete,
            let conversationImagesViewController = delegate as? ConversationImagesViewController {
            sourceView = conversationImagesViewController.deleteButton
        } else if action == .forward,
            let shareButton = (delegate as? ConversationImagesViewController)?.shareButton {
            sourceView = shareButton
        } else {
            sourceView = scrollView
        }

        (delegate as? MessageActionResponder)?.perform(action: action, for: message, view: sourceView)
    }

}

extension FullscreenImageViewController: ZMMessageObserver {
    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        if ((changeInfo.transferStateChanged || changeInfo.imageChanged) && (message.imageMessageData?.imageData != nil)) || changeInfo.isObfuscatedChanged {

            updateForMessage()
        }
    }

}

// MARK: - UIScrollViewDelegate

extension FullscreenImageViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        if let imageSize = imageView?.image?.size,
           let viewSize = self.view?.frame.size {
            updateScrollViewZoomScale(viewSize: viewSize, imageSize: imageSize)
        }

        delegate?.fadeAndHideMenu(true)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setSelectedByMenu(false, animated: false)
        hideMenu()

        centerScrollViewContent()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    private func centerScrollViewContent() {
        let imageWidth: CGFloat = imageView?.image?.size.width ?? 0
        let imageHeight: CGFloat = imageView?.image?.size.height ?? 0

        let viewWidth = view.bounds.size.width
        let viewHeight = view.bounds.size.height

        var horizontalInset: CGFloat = (viewWidth - scrollView.zoomScale * imageWidth) / 2
        horizontalInset = max(0, horizontalInset)

        var verticalInset: CGFloat = (viewHeight - scrollView.zoomScale * imageHeight) / 2
        verticalInset = max(0, verticalInset)

        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }

}
