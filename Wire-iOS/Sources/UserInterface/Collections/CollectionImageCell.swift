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
        cache.totalCostLimit = 1024 * 1024 * 10 // 10 MB
        cache.qualityOfService = .utility
    
        return cache
    }
    
    static let cellSize: CGFloat = 120
    
    var message: ZMConversationMessage? = .none {
        didSet {
            guard let _ = self.message?.imageMessageData else {
                self.imageView.image = .none
                return
            }
            
            self.loadImage()
            ZMMessageNotification.removeMessageObserver(for: self.messageObserverToken)
            self.messageObserverToken = ZMMessageNotification.add(self, for: self.message)
        }
    }
    
    var messageObserverToken: ZMMessageObserverOpaqueToken? = .none
    
    private let imageView = FLAnimatedImageView()
    
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
        constrain(self, self.imageView) { selfView, imageView in
            imageView.edges == selfView.edges
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
            return
        }
        
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
                    DDLogError("Invalid image data returned from sync engine!")
                }
                return image
                
                }, completion: { (image: Any?, cacheKey: String) in
                    // Double check that our cell's current image is still the same one
                    if let _ = self.message, cacheKey == Message.nonNilImageDataIdentifier(self.message) {
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
