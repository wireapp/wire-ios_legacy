
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

protocol ScreenshotProvider: NSObjectProtocol {
    func backgroundScreenshot(for fullscreenController: FullscreenImageViewController) -> UIView?
}

protocol MenuVisibilityController: NSObjectProtocol {
    var menuVisible: Bool { get }
    func fadeAndHideMenu(_ hidden: Bool)
}

private let kZoomScaleDelta: CGFloat = 0.0003

extension FullscreenImageViewController: UIScrollViewDelegate {
}

extension FullscreenImageViewController: UIGestureRecognizerDelegate {
    func dismissingPanGestureRecognizerPanned(_ panner: UIPanGestureRecognizer?) {
    }
}

final class FullscreenImageViewController: UIViewController {
    private(set) var scrollView: UIScrollView?
    private(set) weak var message: ZMConversationMessage?
    var snapshotBackgroundView: UIView?
    weak var delegate: (ScreenshotProvider & MenuVisibilityController)?
    var swipeToDismiss = false
    var showCloseButton = false
    var dismissAction: ((_ dispatch_block_t: ) -> Void)?
    
    private var lastZoomScale: CGFloat = 0.0
    private var imageView: UIImageView?
    private var minimumDismissMagnitude: CGFloat = 0.0
    private var scrollView: UIScrollView!
    private var loadingSpinner: UIActivityIndicatorView?
    private var obfuscationView: ObfuscationView!
    private var actionController: ConversationMessageActionController!
    
    // MARK: pull to dismiss
    private var isDraggingImage = false
    private var imageViewStartingTransform: CGAffineTransform!
    private var imageDragStartingPoint = CGPoint.zero
    private var imageDragOffsetFromActualTranslation: UIOffset!
    private var imageDragOffsetFromImageCenter: UIOffset!
    private var animator: UIDynamicAnimator?
    private var attachmentBehavior: UIAttachmentBehavior?
    private var initialImageViewBounds = CGRect.zero
    private var initialImageViewCenter = CGPoint.zero
    private var panRecognizer: UIPanGestureRecognizer?

    private var highlightLayer: CALayer?
    private var tapGestureRecognzier: UITapGestureRecognizer?
    private var doubleTapGestureRecognizer: UITapGestureRecognizer?
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?
    private var isShowingChrome = false
    private var assetWriteInProgress = false
    private var forcePortraitMode = false
    private var messageObserverToken: Any?

    private func centerScrollViewContent() {
    }
    
    private func setSelectedByMenu(_ selected: Bool, animated: Bool) {
    }

    init(message: ZMConversationMessage?) {
    }
    
    func showChrome(_ shouldShow: Bool) {
    }
    
    func dismiss(withCompletion completion: () -> ()? = nil) {
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    convenience init(message: ZMConversationMessage?) {
        self.init()
        
        self.message = message
        forcePortraitMode = false
        swipeToDismiss = true
        showCloseButton = true
        
        setupScrollView()
        updateForMessage()
        
        view.isUserInteractionEnabled = true
        setupGestureRecognizers()
        showChrome(true)
        
        setupStyle()
        
        setActionController()
        
        if nil != ZMUserSession.shared() {
            messageObserverToken = MessageChangeInfo.addObserver(self, for: message, userSession: ZMUserSession.shared())
        }
    }
    
    func dismiss(withCompletion completion: () -> ()) {
        if nil != dismissAction {
            dismissAction(completion)
        } else if nil != navigationController {
            navigationController?.popViewController(animated: true)
            if completion != nil {
                completion()
            }
        } else {
            dismiss(animated: true, completion: completion)
        }
    }
    
    func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerScrollViewContent()
    }
    
    var prefersStatusBarHidden: Bool {
        return false
    }
    
    func setForcePortraitMode(_ forcePortraitMode: Bool) {
        self.forcePortraitMode = forcePortraitMode
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    var shouldAutorotate: Bool {
        return true
    }
    
    func updateForMessage() {
        if message.isObfuscated || message.hasBeenDeleted {
            removeImage()
            obfuscationView.hidden = false
        } else {
            obfuscationView.hidden = true
            loadImageAndSetupImageView()
        }
    }
    
    func removeImage() {
        imageView?.removeFromSuperview()
        imageView = nil
    }
    
    func showChrome(_ shouldShow: Bool) {
        isShowingChrome = shouldShow
    }
    
    func setSwipeToDismiss(_ swipeToDismiss: Bool) {
        self.swipeToDismiss = swipeToDismiss
        panRecognizer.enabled = self.swipeToDismiss
    }


    func setupGestureRecognizers() {
        tapGestureRecognzier = UITapGestureRecognizer(target: self, action: #selector(didTapBackground(_:)))
        
        let delayedTouchBeganRecognizer = scrollView.gestureRecognizers?[0]
        delayedTouchBeganRecognizer?.require(toFail: tapGestureRecognzier)
        
        view.addGestureRecognizer(tapGestureRecognzier)
        
        
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGestureRecognizer)
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        view.addGestureRecognizer(longPressGestureRecognizer)
        
        panRecognizer = UIPanGestureRecognizer()
        panRecognizer.maximumNumberOfTouches = 1
        panRecognizer.delegate = self
        panRecognizer.enabled = swipeToDismiss
        panRecognizer.addTarget(self, action: #selector(dismissingPanGestureRecognizerPanned(_:)))
        scrollView.addGestureRecognizer(panRecognizer)
        
        doubleTapGestureRecognizer.require(toFail: panRecognizer)
        tapGestureRecognzier.require(toFail: panRecognizer)
        delayedTouchBeganRecognizer?.require(toFail: panRecognizer)
        
        tapGestureRecognzier.require(toFail: doubleTapGestureRecognizer)
    }

    func attributedNameString(forDisplayName displayName: String?) -> NSAttributedString? {
        let text = displayName?.uppercasedWithCurrentLocale()
        let attributes = [
            NSAttributedString.Key.font: UIFont.smallMediumFont,
            NSAttributedString.Key.foregroundColor: UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground),
            NSAttributedString.Key.backgroundColor: UIColor.wr_color(fromColorScheme: ColorSchemeColorTextBackground)
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
    func dismissingPanGestureRecognizerPanned(_ panner: UIPanGestureRecognizer?) {
        
        let translation = panner?.translation(in: panner?.view)
        let locationInView = panner?.location(in: panner?.view)
        let velocity = panner?.velocity(in: panner?.view)
        let vectorDistance = sqrtf(powf(velocity?.x, 2) + powf(velocity?.y, 2))
        
        if panner?.state == .began {
            isDraggingImage = imageView.frame.contains(locationInView)
            if isDraggingImage {
                initiateImageDrag(fromLocation: locationInView, translationOffset: UIOffset.zero)
            }
        } else if panner?.state == .changed {
            if isDraggingImage {
                var newAnchor = imageDragStartingPoint
                newAnchor.x += (translation?.x ?? 0.0) + imageDragOffsetFromActualTranslation.horizontal
                newAnchor.y += (translation?.y ?? 0.0) + imageDragOffsetFromActualTranslation.vertical
                attachmentBehavior.anchorPoint = newAnchor
                updateBackgroundColor(withImageViewCenter: imageView.center)
            } else {
                isDraggingImage = imageView.frame.contains(locationInView)
                if isDraggingImage {
                    let translationOffset = UIOffsetMake(-1 * (translation?.x ?? 0.0), -1 * (translation?.y ?? 0.0))
                    initiateImageDrag(fromLocation: locationInView, translationOffset: translationOffset)
                }
            }
        } else {
            if vectorDistance > 300 && fabs(Float(translation?.y ?? 0.0)) > 100 {
                if isDraggingImage {
                    dismissImageFlicking(withVelocity: velocity)
                } else {
                    dismiss(withCompletion: nil)
                }
            } else {
                cancelCurrentImageDrag(animated: true)
            }
        }
    }
    
    // MARK: - Dynamic Image Dragging
    func initiateImageDrag(fromLocation panGestureLocationInView: CGPoint, translationOffset: UIOffset) {
        setupSnapshotBackgroundView()
        showChrome(false)
        
        initialImageViewCenter = imageView?.center
        let nearLocationInView = CGPoint(x: (panGestureLocationInView.x - initialImageViewCenter.x) * 0.1 + initialImageViewCenter.x, y: (panGestureLocationInView.y - initialImageViewCenter.y) * 0.1 + initialImageViewCenter.y)
        
        imageDragStartingPoint = nearLocationInView
        imageDragOffsetFromActualTranslation = translationOffset
        
        let anchor = imageDragStartingPoint
        let offset = UIOffsetMake(nearLocationInView.x - initialImageViewCenter.x, nearLocationInView.y - initialImageViewCenter.y)
        imageDragOffsetFromImageCenter = offset
        
        // Proxy object is used because the UIDynamics messing up the zoom level transform on imageView
        let proxy = DynamicsProxy()
        imageViewStartingTransform = imageView?.transform
        proxy.center = imageView?.center
        initialImageViewBounds = view.convert(imageView?.bounds ?? CGRect.zero, from: imageView)
        proxy.bounds = initialImageViewBounds
        
        attachmentBehavior = UIAttachmentBehavior(item: proxy, offsetFromCenter: offset, attachedToAnchor: anchor)
        attachmentBehavior.damping = 1
        ZM_WEAK(self)
        attachmentBehavior.action = {
            ZM_STRONG(self)
            self.imageView?.center = CGPoint(x: self.imageView?.center.x ?? 0.0, y: proxy.center.y)
            self.imageView?.transform = proxy.transform.concatenating(self.imageViewStartingTransform)
        }
        animator.addBehavior(attachmentBehavior)
        
        let modifier = UIDynamicItemBehavior(items: [proxy])
        modifier.density = 10000000
        modifier.resistance = 1000
        modifier.elasticity = 0
        modifier.friction = 0
        animator.addBehavior(modifier)
    }

    func cancelCurrentImageDrag(animated: Bool) {
        animator.removeAllBehaviors()
        attachmentBehavior = nil
        isDraggingImage = false
        
        if animated == false {
            imageView?.transform = imageViewStartingTransform
            imageView?.center = initialImageViewCenter
        } else {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                if self.isDraggingImage == false {
                    self.imageView?.transform = self.imageViewStartingTransform
                    self.updateBackgroundColor(withProgress: 0)
                    if self.scrollView.isDragging == false && self.scrollView.isDecelerating == false {
                        self.imageView?.center = self.initialImageViewCenter
                    }
                }
            })
        }
    }

    func dismissImageFlicking(withVelocity velocity: CGPoint) {
        ZM_WEAK(self)
        // Proxy object is used because the UIDynamics messing up the zoom level transform on imageView
        let proxy = DynamicsProxy()
        proxy.center = imageView?.center
        proxy.bounds = initialImageViewBounds
        isDraggingImage = false
        
        let push = UIPushBehavior(items: [proxy], mode: .instantaneous)
        push.pushDirection = CGVectorMake(velocity.x * 0.1, velocity.y * 0.1)
        if let imageView = imageView {
            push.setTargetOffsetFromCenter(UIOffsetMake(attachmentBehavior.anchorPoint.x - initialImageViewCenter.x, attachmentBehavior.anchorPoint.y - initialImageViewCenter.y), for: imageView)
        }
        
        push.magnitude = max(minimumDismissMagnitude, fabs(Float(velocity.y)) / 6.0)
        
        push.action = {
            ZM_STRONG(self)
            self.imageView?.center = CGPoint(x: self.imageView?.center.x ?? 0.0, y: proxy.center.y)
            
            self.updateBackgroundColor(withImageViewCenter: self.imageView?.center)
            if self.imageViewIsOffscreen() {
                UIView.animate(withDuration: 0.1, animations: {
                    self.updateBackgroundColor(withProgress: 1)
                }) { finished in
                    self.animator.removeAllBehaviors()
                    self.attachmentBehavior = nil
                    self.imageView?.removeFromSuperview()
                    self.dismiss(completion: nil)
                }
            }
        }
        animator.remove(attachmentBehavior)
        animator.addBehavior(push)
    }
    
    func imageViewIsOffscreen() -> Bool {
        // tiny inset threshold for small zoom
        return !view.bounds.insetBy(dx: -10, dy: -10).intersects(view.convert(imageView?.bounds ?? CGRect.zero, from: imageView))
    }

    func updateBackgroundColor(withImageViewCenter imageViewCenter: CGPoint) {
        let progress = CGFloat(fabs(Float(imageViewCenter.y - initialImageViewCenter.y)) / 1000)
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
            newAlpha = max(newAlpha, 0.80)
        }
        
        if snapshotBackgroundView {
            snapshotBackgroundView.alpha = 1 - newAlpha
        } else {
            view.backgroundColor = view.backgroundColor?.init(alphaComponent: newAlpha)
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
            
            return fabs(Float(offset.y)) > fabs(Float(offset.x))
        } else {
            return true
        }
    }

}

extension FullscreenImageViewController: ZMMessageObserver {
}

extension FullscreenImageViewController: UIScrollViewDelegate {
}
//TODO: new file
final class DynamicsProxy: NSObject, UIDynamicItem {
    var bounds = CGRect.zero
    var center = CGPoint.zero
    var transform: CGAffineTransform!
}
