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

enum ImageSizeLimit {
    case none
    case maxDimension(CGFloat)
    case maxDimensionForShortSide(CGFloat)
}

extension ImageSizeLimit {
    
    var cacheKeyExtension: String {
        switch self {
        case .none:
            return "default"
        case .maxDimension(let size):
            return "max_\(String(Int(size)))"
        case .maxDimensionForShortSide(let size):
            return "maxshort_\(String(Int(size)))"
        }
    }
}

var defaultMediaAssetCache = ImageCache<MediaAsset>()

extension ZMConversationMessage {

    /// Fetch image data and calls the completion handler when it's available on the main queue.
    func fetchImage(cache: ImageCache<MediaAsset> = defaultMediaAssetCache, sizeLimit: ImageSizeLimit = .none, completion: @escaping (_ image: MediaAsset?) -> Void) {
        guard let imageMessageData = imageMessageData else { return completion(nil) }
        
        let isAnimatedGIF = imageMessageData.isAnimatedGIF
        var sizeLimit = sizeLimit
        
        if isAnimatedGIF {
            // animated GIFs can't be resized
            sizeLimit = .none
        }
        
        let cacheKey = "\(imageMessageData.imageDataIdentifier)_\(sizeLimit.cacheKeyExtension)" as NSString
        
        if let image = cache.cache.object(forKey: cacheKey) {
            return completion(image)
        }
        
        ZMUserSession.shared()?.enqueueChanges {
            self.requestImageDownload()
        }
        
        cache.dispatchGroup.enter()
        
        imageMessageData.fetchImageData(with: cache.processingQueue) { (imageData) in
            var image: MediaAsset?
            
            defer {
                DispatchQueue.main.async {
                    completion(image)
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
