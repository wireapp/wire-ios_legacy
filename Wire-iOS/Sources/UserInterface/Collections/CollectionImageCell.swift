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

final public class CollectionImageCell: CollectionCell {
    public static var imageCache: ImageCache = {
        let cache = ImageCache(name: "CollectionImageCell.imageCache")
        cache.maxConcurrentOperationCount = 4
        cache.totalCostLimit = UInt(1024 * 1024 * 20) // 20 MB
        cache.qualityOfService = .utility
    
        return cache
    }()
    
    public static func loadImageThumbnail(for message: ZMConversationMessage, completion: ((_ image: Any?, _ cacheKey: String)->())?) {
        
        // If medium image is present, use the medium image
        if let imageMessageData = message.imageMessageData, let imageData = imageMessageData.imageData, imageData.count > 0 {
            
            let isAnimatedGIF = imageMessageData.isAnimatedGIF
            
            self.imageCache.image(for: imageData, cacheKey: Message.nonNilImageDataIdentifier(message), creationBlock: { (data: Data) -> Any in
                var image: AnyObject? = .none
                
                if (isAnimatedGIF) {
                    image = FLAnimatedImage(animatedGIFData: data)
                } else {
                    image = UIImage(from: data, withMaxSize: CollectionImageCell.maxCellSize * UIScreen.main.scale)
                }
                
                guard let finalImage = image else {
                    fatal("Invalid image data cannot be loaded: \(message)")
                }
                
                return finalImage
                
            }, completion: completion)
        }
    }
    
    static let maxCellSize: CGFloat = 100

    override var message: ZMConversationMessage? {
        didSet {
            guard let message = self.message, let _ = message.imageMessageData else {
                self.imageView.image = .none
                return
            }
            message.requestImageDownload()
        }
    }
        
    private let imageView = FLAnimatedImageView()
    private let loadingView = ThreeDotsLoadingView()
    
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadView()
    }
    
    var isHeightCalculated: Bool = false
    
    func loadView() {
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.imageView.accessibilityIdentifier = "image"
        self.loadingView.accessibilityIdentifier = "loading"
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.loadingView)
        constrain(self, self.imageView, self.loadingView) { selfView, imageView, loadingView in
            imageView.left == selfView.left
            imageView.right == selfView.right
            imageView.top == selfView.top
            imageView.bottom == selfView.bottom
            loadingView.center == selfView.center
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.message = .none
        self.isHeightCalculated = false
    }
    
    override func updateForMessage(changeInfo: MessageChangeInfo?) {
        super.updateForMessage(changeInfo: changeInfo)
        
        guard let changeInfo = changeInfo else {
            self.loadImage()
            return
        }
        
        if changeInfo.imageChanged {
            self.loadImage()
        }
    }
    
    override func menuConfigurationProperties() -> MenuConfigurationProperties? {
        guard let properties = super.menuConfigurationProperties() else {
            return .none
        }
        
        var mutableItems = properties.additionalItems ?? []
        
        let saveItem = UIMenuItem(title: "content.image.save_image".localized, action: #selector(CollectionImageCell.save(_:)))
        mutableItems.append(saveItem)
        
        properties.additionalItems = mutableItems
        return properties
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(CollectionImageCell.save(_:)): fallthrough
        case #selector(copy(_:)):
            return true
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }
    
    override public func copy(_ sender: Any?) {
        guard let imageData = self.message?.imageMessageData?.imageData else {
            return
        }
        
        UIPasteboard.general.setMediaAsset(UIImage(data: imageData))
    }
    
    func save(_ sender: AnyObject!) {
        guard let imageData = self.message?.imageMessageData?.imageData, let orientation = self.imageView.image?.imageOrientation else {
            return
        }
        
        let savableImage = SavableImage(data: imageData, orientation: orientation)
        savableImage.saveToLibrary()
    }
    
    fileprivate func loadImage() {
        guard let message = self.message, message.imageMessageData != nil else {
            self.imageView.image = .none
            return
        }
        
        self.imageView.isHidden = true
        self.loadingView.isHidden = false
        
        type(of: self).loadImageThumbnail(for: message) { (image, cacheKey) in
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
        }
    }
}

