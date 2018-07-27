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

fileprivate var ciContext = CIContext(options: nil)

public var defaultUserImageCache: ImageCache<UIImage> = ImageCache()

extension UserType {
    
    private func cacheKey(for size: ProfileImageSize, desaturate: Bool) -> String? {
        
        guard let baseKey = (size == .preview ? smallProfileImageCacheKey : mediumProfileImageCacheKey) else {
            return nil
        }
        
        if desaturate {
            return "\(baseKey)_desaturated"
        } else {
            return baseKey
        }
        
    }
    
    public func fetchProfileImage(cache: ImageCache<UIImage> = defaultUserImageCache, size: ProfileImageSize, completion: @escaping (_ image: UIImage?) -> Void ) -> Void {
        
        let desaturate =  !isConnected && !isSelfUser && !isTeamMember || isServiceUser
    
        guard let cacheKey = cacheKey(for: size, desaturate: desaturate) as NSString? else {
            return completion(nil)
        }
        
        if let image = cache.cache.object(forKey: cacheKey) {
            return completion(image)
        }
        
        switch size {
        case .preview:
            requestPreviewProfileImage()
        default:
            requestCompleteProfileImage()
        }
        
        imageData(for: size, queue: cache.processingQueue) { (imageData) in
            guard let imageData = imageData, let rawImage = UIImage(data: imageData) else {
                return DispatchQueue.main.async {
                    completion(nil)
                }
            }
            
            var image: UIImage?
            if desaturate {
                image = rawImage.desaturatedImage(with: ciContext, saturation: 0)
            } else {
                image = rawImage.decoded
            }
            
            if let image = image {
                cache.cache.setObject(image, forKey: cacheKey)
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
}
