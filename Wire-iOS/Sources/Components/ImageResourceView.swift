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
import FLAnimatedImage
import WireDataModel

final class ImageResourceView: FLAnimatedImageView {
    
    weak var delegate: ContextMenuDelegate?

    fileprivate var loadingView = ThreeDotsLoadingView()
    
    /// This token is changes everytime the cell is re-used. Useful when performing
    /// asynchronous tasks where the cell might have been re-used in the mean time.
    fileprivate var reuseToken = UUID()
    fileprivate var imageResourceInternal: ImageResource? = nil
    
    var imageSizeLimit: ImageSizeLimit = .deviceOptimized
    var imageResource: ImageResource? {
        set {
            setImageResource(newValue)
        }
        get {
            return imageResourceInternal
        }
    }
    
    func setImageResource(_ imageResource: ImageResource?, hideLoadingView: Bool = false, completion: (() -> Void)? = nil) {
        let token = UUID()
        mediaAsset = nil

        imageResourceInternal = imageResource
        reuseToken = token
        loadingView.isHidden = hideLoadingView || loadingView.isHidden || imageResource == nil

        guard let imageResource = imageResource, imageResource.cacheIdentifier != nil else {
            loadingView.isHidden = true
            completion?()
            return
        }
        
        imageResource.fetchImage(sizeLimit: imageSizeLimit, completion: { [weak self] (mediaAsset, cacheHit) in
            guard token == self?.reuseToken, let `self` = self else { return }
            
            let update = {
                self.loadingView.isHidden = hideLoadingView || mediaAsset != nil
                self.mediaAsset = mediaAsset
                completion?()
            }
            
            if cacheHit || ProcessInfo.processInfo.isRunningTests {
                update()
            } else {
                UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve, animations: update)
            }
        })
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadingView.accessibilityIdentifier = "loading"
        
        addSubview(loadingView)
        
        constrain(self, loadingView) { containerView, loadingView in
            loadingView.center == containerView.center
        }
        
        
        if #available(iOS 13.0, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            addInteraction(interaction)
        }
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - UIContextMenuInteractionDelegate

@available(iOS 13.0, *)
extension ImageResourceView: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        let previewProvider: UIContextMenuContentPreviewProvider = {
            guard let message = self.delegate?.message,
                  let actionResponder = self.delegate?.delegate else { return nil}
            
            let messagePresenter = MessagePresenter(mediaPlaybackManager: nil)
            
            return messagePresenter.viewController(forImageMessagePreview: message, actionResponder: actionResponder)
        }

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: previewProvider,
                                          actionProvider:  { _ in
                                            return self.delegate?.makeContextMenu(title: "conversation.input_bar.message_preview.image".localized, view: self)
        })
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            ///TODO
//            self.openURL()
        }
    }
}
