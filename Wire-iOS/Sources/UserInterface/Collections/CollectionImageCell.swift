//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import CocoaLumberjackSwift
import WireExtensionComponents

final public class CollectionImageCell: UICollectionViewCell {
    static var imageCache: ImageCache {
        let cache = ImageCache(name: "CollectionImageCell.imageCache")
        cache.maxConcurrentOperationCount = 4
        cache.totalCostLimit = 1024 * 1024 * 20 // 20 MB
        cache.qualityOfService = .utility
    
        return cache
    }
    
    static let cellSize: CGFloat = 120
    
    var message: ZMConversationMessage? = .none {
        didSet {
            guard let message = self.message, let _ = message.imageMessageData else {
                self.imageView.image = .none
                return
            }
            message.requestImageDownload()
            
            self.loadImage()
            ZMMessageNotification.removeMessageObserver(for: self.messageObserverToken)
            self.messageObserverToken = ZMMessageNotification.add(self, for: self.message)
        }
    }
    
    var messageObserverToken: ZMMessageObserverOpaqueToken? = .none
    
    private let imageView = FLAnimatedImageView()
    private let loadingView = ThreeDotsLoadingView()
    
    deinit {
        ZMMessageNotification.removeMessageObserver(for: self.messageObserverToken)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadView()
    }
    
    func loadView() {
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.loadingView)
        constrain(self, self.imageView, self.loadingView) { selfView, imageView, loadingView in
            imageView.edges == selfView.edges
            loadingView.center == selfView.center
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.message = .none
    }
    
    static var reuseIdentifier: String {
        return "\(self)"
    }
    
    override open var reuseIdentifier: String? {
        return type(of: self).reuseIdentifier
    }
    
    fileprivate func loadImage() {
        guard let imageMessageData = self.message?.imageMessageData else {
            self.imageView.image = .none
            fatal("Message is not an image")
        }
        
        self.imageView.isHidden = true
        self.loadingView.isHidden = false
        
        // If medium image is present, use the medium image
        if let imageData = imageMessageData.imageData, imageData.count > 0 {
            
            let isAnimatedGIF = imageMessageData.isAnimatedGIF
            
            type(of: self).imageCache.image(for: imageData, cacheKey: Message.nonNilImageDataIdentifier(self.message), creationBlock: { (data: Data) -> Any in
                var image: AnyObject? = .none
                
                if (isAnimatedGIF) {
                    image = FLAnimatedImage(animatedGIFData: data)
                } else {
                    image = UIImage(from: data, withMaxSize: CollectionImageCell.cellSize * UIScreen.main.scale)
                }
                
                if (image == nil) {
                    DDLogError("Invalid image data cannot be loaded: \(self.message)")
                }
                return image
                
                }, completion: { (image: Any?, cacheKey: String) in
                    // Double check that our cell's current image is still the same one
                    if let _ = self.message, cacheKey == Message.nonNilImageDataIdentifier(self.message) {
                        self.imageView.isHidden = false
                        self.loadingView.isHidden = true
                        
                        if let image = image as? UIImage {
                            self.imageView.image = image
                        }
                        if let image = image as? FLAnimatedImage {
                            self.imageView.animatedImage = image
                        }
                    }
                    else {
                        DDLogInfo("finished loading image but cell is no longer on screen.")
                    }
            })
        }
    }
}

extension CollectionImageCell: ZMMessageObserver {
    public func messageDidChange(_ changeInfo: MessageChangeInfo!) {
        if changeInfo.imageChanged {
            self.loadImage()
        }
    }
}
