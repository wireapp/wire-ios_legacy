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

// TODO jacob move into class for easier testing
fileprivate var cache: NSCache<NSString, MediaAsset> = NSCache()
fileprivate var processingQueue = DispatchQueue(label: "ImageProcessingQueue", qos: .background, attributes: [.concurrent])

extension ZMConversationMessage {

    /// Fetch image data and calls the completion handler when it's available on the main queue.=
    func fetchImage(completion: @escaping (_ image: MediaAsset?) -> Void) {
        guard let imageMessageData = imageMessageData else { return completion(nil) }
        
        let cacheKey = imageMessageData.imageDataIdentifier as NSString
        let isAnimatedGIF = imageMessageData.isAnimatedGIF
        
        if let image = cache.object(forKey: cacheKey) {
            return completion(image)
        }
        
        requestImageDownload()
        
        imageMessageData.fetchImageData(with: processingQueue) { (imageData) in
            var image: MediaAsset?
            
            defer {
                DispatchQueue.main.async {
                    completion(image)
                }
            }
            
            guard let imageData = imageData else { return }
            
            if isAnimatedGIF {
                image = FLAnimatedImage(animatedGIFData: imageData) }
            else {
                image = UIImage(data: imageData)?.decoded
            }
            
            if let image = image {
                cache.setObject(image, forKey: cacheKey)
            }
        }
    }
    
    
}
