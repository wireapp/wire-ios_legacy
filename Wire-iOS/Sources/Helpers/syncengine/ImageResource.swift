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
import WireExtensionComponents

var defaultImageCache = ImageCache<MediaAsset>()

extension ZMTextMessageData {
    
    var linkPreviewImage: ImageResource {
        return LinkPreviewImageResourceAdaptor(textMessageData: self)
    }
    
}

extension ZMFileMessageData {
    
    var thumbnailImage: PreviewableImageResource {
        return FileMessageImageResourceAdaptor(fileMesssageData: self)
    }
    
}

extension ZMImageMessageData {
    
    var image: PreviewableImageResource {
        return ImageMessageImageResourceAdaptor(imageMessageData: self)
    }
    
}

struct LinkPreviewImageResourceAdaptor: ImageResource {
    
    let textMessageData: ZMTextMessageData
    
    var cacheIdentifier: String? {
        return textMessageData.linkPreviewImageCacheKey?.appending("-link")
    }
    
    var isAnimatedGIF: Bool {
        return false
    }
    
    func requestImageDownload() {
        textMessageData.requestLinkPreviewImageDownload()
    }
    
    func fetchImageData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        textMessageData.fetchLinkPreviewImageData(with: queue, completionHandler: completionHandler)
    }
    
}

struct FileMessageImageResourceAdaptor: PreviewableImageResource {
    
    let fileMesssageData: ZMFileMessageData
    
    var cacheIdentifier: String? {
        return fileMesssageData.imagePreviewDataIdentifier?.appending("-file")
    }

    var contentMode: UIView.ContentMode {
        return .scaleAspectFill
    }

    var contentSize: CGSize {
        return CGSize(width: 250, height: 140)
    }
    
    var isAnimatedGIF: Bool {
        return false
    }
    
    func requestImageDownload() {
        fileMesssageData.requestImagePreviewDownload()
    }
    
    func fetchImageData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        fileMesssageData.fetchImagePreviewData(queue: queue, completionHandler: completionHandler)
    }
    
}

struct ImageMessageImageResourceAdaptor: PreviewableImageResource {
    
    let imageMessageData: ZMImageMessageData
    
    var cacheIdentifier: String? {
        return imageMessageData.imageDataIdentifier?.appending("-image")
    }
    
    var isAnimatedGIF: Bool {
        return imageMessageData.isAnimatedGIF
    }

    var contentMode: UIView.ContentMode {
        return .scaleAspectFit
    }

    var contentSize: CGSize {
        return imageMessageData.originalSize
    }
    
    func requestImageDownload() {
        imageMessageData.requestImageDownload()
    }
    
    func fetchImageData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        imageMessageData.fetchImageData(with: queue, completionHandler: completionHandler)
    }
    
}

protocol ImageResource {
    
    var cacheIdentifier: String? { get }
    var isAnimatedGIF: Bool { get }

    func requestImageDownload()
    func fetchImageData(queue: DispatchQueue, completionHandler: @escaping (_ imageData: Data?) -> Void)
    
}

protocol PreviewableImageResource: ImageResource {
    var contentMode: UIView.ContentMode { get }
    var contentSize: CGSize { get }
}

enum ImageSizeLimit {
    case none
    case deviceOptimized
    case maxDimension(CGFloat)
    case maxDimensionForShortSide(CGFloat)
}

extension ImageSizeLimit {
    
    var cacheKeyExtension: String {
        switch self {
        case .none:
            return "default"
        case .deviceOptimized:
            return "device"
        case .maxDimension(let size):
            return "max_\(String(Int(size)))"
        case .maxDimensionForShortSide(let size):
            return "maxshort_\(String(Int(size)))"
        }
    }
}

extension ImageResource {
    
    /// Fetch image data and calls the completion handler when it is available on the main queue.
    func fetchImage(cache: ImageCache<MediaAsset> = defaultImageCache, sizeLimit: ImageSizeLimit = .deviceOptimized, completion: @escaping (_ image: MediaAsset?, _ cacheHit: Bool) -> Void) {
        
        guard let cacheIdentifier = self.cacheIdentifier else {
            return completion(nil, false)
        }
        
        let isAnimatedGIF = self.isAnimatedGIF
        var sizeLimit = sizeLimit
        
        if isAnimatedGIF {
            // animated GIFs can't be resized
            sizeLimit = .none
        }
        
        let cacheKey = "\(cacheIdentifier)_\(sizeLimit.cacheKeyExtension)" as NSString
        
        if let image = cache.cache.object(forKey: cacheKey) {
            return completion(image, true)
        }
        
        ZMUserSession.shared()?.enqueueChanges {
            self.requestImageDownload()
        }
        
        cache.dispatchGroup.enter()
        
        fetchImageData(queue: cache.processingQueue) { (imageData) in
            var image: MediaAsset?
            
            defer {
                DispatchQueue.main.async {
                    completion(image, false)
                    cache.dispatchGroup.leave()
                }
            }
            
            guard let imageData = imageData else { return }
            
            if isAnimatedGIF {
                image = FLAnimatedImage(animatedGIFData: imageData)
            } else {
                switch sizeLimit {
                case .none:
                    image = UIImage(data: imageData)?.decoded
                case .deviceOptimized:
                    image = UIImage.deviceOptimizedImage(from: imageData)
                case .maxDimension(let limit):
                    image = UIImage(from: imageData, withMaxSize: limit)
                case .maxDimensionForShortSide(let limit):
                    image = UIImage(from: imageData, withShorterSideLength: limit)
                }
            }
            
            if let image = image {
                cache.cache.setObject(image, forKey: cacheKey)
            }
        }
    }
    
}
