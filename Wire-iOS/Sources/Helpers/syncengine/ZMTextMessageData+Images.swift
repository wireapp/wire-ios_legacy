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

var defaultImageCache = ImageCache<UIImage>()

extension ZMTextMessageData {
    
    func fetchLinkPreviewImage(cache: ImageCache<UIImage> = defaultImageCache, completion: @escaping (_ image: UIImage?) -> Void) {
        LinkPreviewImageAdaptor(textMessageData: self).fetchImage(cache: cache, completion: completion)
    }
    
}

extension ZMFileMessageData {
    
    func fetchPreviewImage(cache: ImageCache<UIImage> = defaultImageCache, completion: @escaping (_ image: UIImage?) -> Void) {
        FileMessageImageAdaptor(fileMesssageData: self).fetchImage(cache: cache, completion: completion)
    }
    
}

struct LinkPreviewImageAdaptor: ImageMessage {
    
    let textMessageData: ZMTextMessageData
    
    var cacheIdentifier: String? {
        return textMessageData.linkPreviewImageCacheKey
    }
    
    func requestImageDownload() {
        (textMessageData as? ZMConversationMessage)?.requestImageDownload()
    }
    
    func fetchImageData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        textMessageData.fetchLinkPreviewImageData(with: queue, completionHandler: completionHandler)
    }
    
}

struct FileMessageImageAdaptor: ImageMessage {
    
    let fileMesssageData: ZMFileMessageData
    
    var cacheIdentifier: String? {
        return fileMesssageData.imagePreviewDataIdentifier
    }
    
    func requestImageDownload() {
        (fileMesssageData as? ZMConversationMessage)?.requestImageDownload()
    }
    
    func fetchImageData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        fileMesssageData.fetchImagePreviewData(queue: queue, completionHandler: completionHandler)
    }
    
}

fileprivate protocol ImageMessage {
    
    var cacheIdentifier: String? { get }
    
    func requestImageDownload()
    func fetchImageData(queue: DispatchQueue, completionHandler: @escaping (_ imageData: Data?) -> Void)
    
}

extension ImageMessage {
    
    func fetchImage(cache: ImageCache<UIImage>, completion: @escaping (_ image: UIImage?) -> Void) {
        
        guard let cacheKey = cacheIdentifier as NSString? else { return }
        
        if let image = cache.cache.object(forKey: cacheKey) {
            return completion(image)
        }
        
        requestImageDownload()
        
        cache.dispatchGroup.enter()
        
        fetchImageData(queue: cache.processingQueue) { (imageData) in
            var image: UIImage? = nil
            
            defer {
                DispatchQueue.main.async {
                    completion(image)
                    cache.dispatchGroup.leave()
                }
            }
            
            guard let imageData = imageData else { return }
            
            image = UIImage.deviceOptimizedImage(from: imageData)
            
            if let image = image {
                cache.cache.setObject(image, forKey: cacheKey)
            }
        }
    }
    
}

