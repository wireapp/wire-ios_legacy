
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

}
