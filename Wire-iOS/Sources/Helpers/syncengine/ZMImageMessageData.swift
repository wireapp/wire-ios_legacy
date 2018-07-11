//
//  ZMImageMessageData.swift
//  Wire-iOS
//
//  Created by Jacob Persson on 03.07.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation

fileprivate var cache: NSCache<NSString, MediaAsset> = NSCache()

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
        
        imageMessageData.fetchImageData(with: DispatchQueue.global(qos: .background)) { (imageData) in
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
                image = UIImage(data: imageData)
            }
            
            if let image = image {
                cache.setObject(image, forKey: cacheKey)
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    
}
