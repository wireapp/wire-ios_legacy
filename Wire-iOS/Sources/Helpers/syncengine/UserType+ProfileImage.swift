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
import WireSyncEngine
import WireDataModel

public var defaultUserImageCache: ImageCache<UIImage> = ImageCache()

typealias ProfileImageCompletion = (_ image: UIImage?, _ cacheHit: Bool) -> Void

extension UserType {
    func fetchProfileImage(session: ZMUserSessionInterface,
                           imageCache: ImageCache<UIImage>,
                           sizeLimit: Int?,
                           isDesaturated: Bool,
                           completion: @escaping ProfileImageCompletion) {

        let imageSize = profileImageSize(with: sizeLimit)

        guard let cacheKey = buildCachedImageKey(for: imageSize,
                                                 sizeLimit: sizeLimit,
                                                 isDesaturated: isDesaturated) else {
            completion(nil, false)
            return
        }

        guard let cachedImage = cachedImage(imageCache: imageCache,
                                            cacheKey: cacheKey) else {
            downloadProfileImage(for: imageSize)
            processDownloadedProfileImage(for: imageSize,
                                          sizeLimit: sizeLimit,
                                          isDesaturated: isDesaturated,
                                          imageCache: imageCache,
                                          cacheKey: cacheKey,
                                          completion: completion)
            return
        }

        completion(cachedImage, true)
    }

    // MARK: ImageSize Helper

    private func profileImageSize(with sizeLimit: Int?) -> ProfileImageSize {
        guard let sizeLimit = sizeLimit else { return .complete }

        let screenScale = UIScreen.main.scale
        let previewSizeLimit: CGFloat = 280
        return CGFloat(sizeLimit) * screenScale < previewSizeLimit ? .preview : .complete
    }

    // MARK: Cache Image Helper

    private func cachedImage(imageCache: ImageCache<UIImage>, cacheKey: String) -> UIImage? {
        guard let cachedImage = imageCache.cache.object(forKey: cacheKey as NSString) else {
            return nil
        }
        return cachedImage
    }

    private func buildCachedImageKey(for imageSize: ProfileImageSize,
                                     sizeLimit: Int?,
                                     isDesaturated: Bool) -> String? {
        guard let baseKey = imageSize == .preview ? smallProfileImageCacheKey : mediumProfileImageCacheKey else {
            return nil
        }

        var derivedKey = baseKey

        if isDesaturated {
            derivedKey = "\(derivedKey)_desaturated"
        }

        if let sizeLimit = sizeLimit {
            derivedKey = "\(derivedKey)_\(sizeLimit)"
        }

        return derivedKey
    }

    // MARK: Preview Image Helper

    private func downloadProfileImage(for imageSize: ProfileImageSize) {
        switch imageSize {
        case .preview:
            requestPreviewProfileImage()
        default:
            requestCompleteProfileImage()
        }
    }

    // MARK: Dowload Image Helper

    private func processDownloadedProfileImage(for imageSize: ProfileImageSize,
                                               sizeLimit: Int?,
                                               isDesaturated: Bool,
                                               imageCache: ImageCache<UIImage>,
                                               cacheKey: String,
                                               completion: @escaping ProfileImageCompletion) {
        imageData(for: imageSize, queue: imageCache.processingQueue) { (imageData) in
            guard let imageData = imageData else {
                return DispatchQueue.main.async {
                    completion(nil, false)
                }
            }

            var image: UIImage?
            if let sizeLimit = sizeLimit {
                image = UIImage(from: imageData, withMaxSize: CGFloat(sizeLimit) * UIScreen.main.scale)
            } else {
                image = UIImage(data: imageData)?.decoded
            }

            if isDesaturated {
                image = image?.desaturatedImage(with: CIContext.shared)
            }

            if let image = image {
                imageCache.cache.setObject(image, forKey: cacheKey as NSString)
            }

            imageCache.dispatchGroup.enter()

            DispatchQueue.main.async {
                completion(image, false)
                imageCache.dispatchGroup.leave()
            }
        }
    }
}
