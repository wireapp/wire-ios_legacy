
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

private let zmLog = ZMSLog(tag: "FullscreenImageViewController")

protocol ScreenshotProvider: NSObjectProtocol {
    func backgroundScreenshot(for fullscreenController: FullscreenImageViewController) -> UIView?
}

protocol MenuVisibilityController: NSObjectProtocol {
    var menuVisible: Bool { get }
    func fadeAndHideMenu(_ hidden: Bool)
}

final class FullscreenImageViewController: UIViewController {
    //    TODO: private
    let kZoomScaleDelta: CGFloat = 0.0003

    //    TODO: private
    let scrollView: UIScrollView = UIScrollView()
    let message: ZMConversationMessage
    var snapshotBackgroundView: UIView?
    weak var delegate: (ScreenshotProvider & MenuVisibilityController)?
    var swipeToDismiss = true {
        didSet {
            panRecognizer.isEnabled = swipeToDismiss
        }
    }
    var showCloseButton = true
    var dismissAction: DismissAction?
    
    //TODO: private
    var lastZoomScale: CGFloat = 0
    //    private, optional?
    var imageView: UIImageView!
    //TODO: private
    var minimumDismissMagnitude: CGFloat = 0
    ///TODO: still needed?
    private var obfuscationView: ObfuscationView?
    private lazy var actionController: ConversationMessageActionController = {
        return ConversationMessageActionController(responder: self, message: message, context: .collection, view: scrollView)
    }()
    
    // MARK: pull to dismiss
    private var isDraggingImage = false
    private var imageViewStartingTransform: CGAffineTransform!
    private var imageDragStartingPoint = CGPoint.zero
    private var imageDragOffsetFromActualTranslation: UIOffset!
    private var imageDragOffsetFromImageCenter: UIOffset!
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

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: ZMConversationMessage) {
        self.message = message

        super.init(nibName: nil, bundle: nil)

        setupScrollView()
        updateForMessage()
        
        view.isUserInteractionEnabled = true
        setupGestureRecognizers()
        
        setupStyle()
        
        if let userSession = ZMUserSession.shared() {
            messageObserverToken = MessageChangeInfo.add(observer: self, for: message, userSession: userSession)
        }
    }
    
    //MARK: - override
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerScrollViewContent()
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
            obfuscationView?.isHidden = false
        } else {
            obfuscationView?.isHidden = true
            loadImageAndSetupImageView()
        }
    }
    
    func removeImage() {
        imageView?.removeFromSuperview()
        imageView = nil
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

    func attributedNameString(forDisplayName displayName: String?) -> NSAttributedString? {
        let text = displayName?.uppercasedWithCurrentLocale
        let attributes = [
            NSAttributedString.Key.font: UIFont.smallMediumFont,
            NSAttributedString.Key.foregroundColor: UIColor.from(scheme: .textForeground),
            NSAttributedString.Key.backgroundColor: UIColor.from(scheme: .textBackground)
        ]
        
        let attributedName = NSAttributedString(string: text ?? "", attributes: attributes)
        
        return attributedName
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
    
    @objc
    func loadImageAndSetupImageView() {
        let imageIsAnimatedGIF = message.imageMessageData?.isAnimatedGIF
        let imageData = message.imageMessageData?.imageData
        
        DispatchQueue.global(qos: .default).async(execute: { [weak self] in
            
            let mediaAsset: MediaAsset
            
            if imageIsAnimatedGIF == true {
                mediaAsset = FLAnimatedImage(animatedGIFData: imageData)
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

    //MARK: - PullToDismiss
    @objc
    private func dismissingPanGestureRecognizerPanned(_ panner: UIPanGestureRecognizer) {
        
        let translation = panner.translation(in: panner.view)
        let locationInView = panner.location(in: panner.view)
        let velocity = panner.velocity(in: panner.view)
        let vectorDistance = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
        
        switch panner.state {
        case .began:
            isDraggingImage = imageView.frame.contains(locationInView)
            if isDraggingImage {
                initiateImageDrag(fromLocation: locationInView, translationOffset: .zero)
            }
        case .changed:
            if isDraggingImage {
                var newAnchor = imageDragStartingPoint
                newAnchor.x += (translation.x) + imageDragOffsetFromActualTranslation.horizontal
                newAnchor.y += (translation.y) + imageDragOffsetFromActualTranslation.vertical
                attachmentBehavior?.anchorPoint = newAnchor
                updateBackgroundColor(withImageViewCenter: imageView.center)
            } else {
                isDraggingImage = imageView.frame.contains(locationInView)
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
        setupSnapshotBackgroundView()
        isShowingChrome = false
        
        initialImageViewCenter = imageView.center
        let nearLocationInView = CGPoint(x: (panGestureLocationInView.x - initialImageViewCenter.x) * 0.1 + initialImageViewCenter.x, y: (panGestureLocationInView.y - initialImageViewCenter.y) * 0.1 + initialImageViewCenter.y)
        
        imageDragStartingPoint = nearLocationInView
        imageDragOffsetFromActualTranslation = translationOffset
        
        let anchor = imageDragStartingPoint
        let offset = UIOffset(horizontal: nearLocationInView.x - initialImageViewCenter.x, vertical: nearLocationInView.y - initialImageViewCenter.y)
        imageDragOffsetFromImageCenter = offset
        
        // Proxy object is used because the UIDynamics messing up the zoom level transform on imageView
        let proxy = DynamicsProxy()
        imageViewStartingTransform = imageView?.transform
        proxy.center = imageView.center
        initialImageViewBounds = view.convert(imageView?.bounds ?? CGRect.zero, from: imageView)
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
                    weakSelf.updateBackgroundColor(withProgress: 0)
                    if !weakSelf.scrollView.isDragging && !weakSelf.scrollView.isDecelerating {
                        weakSelf.imageView?.center = weakSelf.initialImageViewCenter
                    }
                }
            })
        }
    }

    private func dismissImageFlicking(withVelocity velocity: CGPoint) {
        // Proxy object is used because the UIDynamics messing up the zoom level transform on imageView
        let proxy = DynamicsProxy()
        proxy.center = imageView.center
        proxy.bounds = initialImageViewBounds
        isDraggingImage = false
        
        let push = UIPushBehavior(items: [proxy], mode: .instantaneous)
        push.pushDirection = CGVector(dx: velocity.x * 0.1, dy: velocity.y * 0.1)
        if let imageView = imageView,
            let attachmentBehavior = attachmentBehavior {
            push.setTargetOffsetFromCenter(UIOffset(horizontal: attachmentBehavior.anchorPoint.x - initialImageViewCenter.x, vertical: attachmentBehavior.anchorPoint.y - initialImageViewCenter.y), for: imageView)
        }
        
        push.magnitude = max(minimumDismissMagnitude, abs(velocity.y) / 6)
        
        push.action = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.imageView?.center = CGPoint(x: weakSelf.imageView?.center.x ?? 0, y: proxy.center.y)
            
            weakSelf.updateBackgroundColor(withImageViewCenter: weakSelf.imageView.center)
            if weakSelf.imageViewIsOffscreen {
                UIView.animate(withDuration: 0.1, animations: {
                    weakSelf.updateBackgroundColor(withProgress: 1)
                }) { finished in
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

    private func updateBackgroundColor(withImageViewCenter imageViewCenter: CGPoint) {
        let progress: CGFloat = abs(imageViewCenter.y - initialImageViewCenter.y) / 1000
        updateBackgroundColor(withProgress: progress)
    }
    
    func updateBackgroundColor(withProgress progress: CGFloat) {
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

    // MARK: - Gesture Handling
    @objc
    private func didTapBackground(_ tapper: UITapGestureRecognizer?) {
        isShowingChrome = !isShowingChrome
        setSelectedByMenu(false, animated: false)
        UIMenuController.shared.isMenuVisible = false
        delegate?.fadeAndHideMenu(delegate?.menuVisible == false)
    }
    
    @objc
    private func handleLongPress(_ longPressRecognizer: UILongPressGestureRecognizer?) {
        if longPressRecognizer?.state == .began {
            
            NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide(_:)), name: UIMenuController.didHideMenuNotification, object: nil)
            
            ///  The reason why we are touching the window here is to workaround a bug where,
            ///  After dismissing the webplayer, the window would fail to become the first responder,
            ///  preventing us to show the menu at all.
            ///  We now force the window to be the key window and to be the first responder to ensure that we can
            ///  show the menu controller.
            view.window?.makeKey()
            view.window?.becomeFirstResponder()
            becomeFirstResponder()
            
            let menuController = UIMenuController.shared
            menuController.menuItems = ConversationMessageActionController.allMessageActions
            
            if let imageView = imageView {
                menuController.setTargetRect(imageView.bounds, in: imageView)
            }
            menuController.setMenuVisible(true, animated: true)
            setSelectedByMenu(true, animated: true)
        }
    }

    // MARK: - Actions
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return actionController.canPerformAction(action)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return actionController
    }
    
    //TODO: private
    func setSelectedByMenu(_ selected: Bool, animated: Bool) {
        zmLog.debug("Setting selected: \(selected) animated: \(animated)")
        if selected {
            
            let highlightLayer = CALayer()
            highlightLayer.backgroundColor = UIColor.clear.cgColor
            highlightLayer.frame = CGRect(x: 0, y: 0, width: (imageView?.frame.size.width ?? 0.0) / scrollView.zoomScale, height: (imageView?.frame.size.height ?? 0.0) / scrollView.zoomScale)
            imageView?.layer.insertSublayer(highlightLayer, at: 0)
            
            if animated {
                UIView.animate(withDuration: 0.33, animations: {
                    self.highlightLayer?.backgroundColor = UIColor.black.withAlphaComponent(0.4).cgColor
                })
            } else {
                highlightLayer.backgroundColor = UIColor.black.withAlphaComponent(0.4).cgColor
            }
            self.highlightLayer = highlightLayer
        } else {
            if animated {
                UIView.animate(withDuration: 0.33, animations: {
                    self.highlightLayer?.backgroundColor = UIColor.clear.cgColor
                }) { finished in
                    if finished {
                        self.highlightLayer?.removeFromSuperlayer()
                    }
                }
            } else {
                highlightLayer?.backgroundColor = UIColor.clear.cgColor
                highlightLayer?.removeFromSuperlayer()
            }
        }
    }

    @objc
    private func menuDidHide(_ notification: Notification?) {
        NotificationCenter.default.removeObserver(self, name: UIMenuController.didHideMenuNotification, object: nil)
        setSelectedByMenu(false, animated: true)
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
        UIMenuController.shared.isMenuVisible = false
        
        centerScrollViewContent()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // TODO: private
    func centerScrollViewContent() {
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
