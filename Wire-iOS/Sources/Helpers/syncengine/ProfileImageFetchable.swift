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

extension CIContext {
    static var shared: CIContext = CIContext(options: nil)
}

typealias ProfileImageFetchableUser = UserType & ProfileImageFetchable

protocol ProfileImageFetchable {

    func fetchProfileImage(session: ZMUserSessionInterface,
                           cache: ImageCache<UIImage>,
                           sizeLimit: Int?,
                           desaturate: Bool,
                           completion: @escaping (_ image: UIImage?, _ cacheHit: Bool) -> Void)

}

extension ProfileImageFetchable where Self: UserType {
    private func cacheKey(for size: ProfileImageSize, sizeLimit: Int?, desaturate: Bool) -> String? {

        guard let baseKey = (size == .preview ? smallProfileImageCacheKey : mediumProfileImageCacheKey) else {
            return nil
        }

        var derivedKey = baseKey

        if desaturate {
            derivedKey = "\(derivedKey)_desaturated"
        }

        if let sizeLimit = sizeLimit {
            derivedKey = "\(derivedKey)_\(sizeLimit)"
        }

        return derivedKey
    }

    func fetchProfileImage(session: ZMUserSessionInterface,
                           cache: ImageCache<UIImage> = UIImage.defaultUserImageCache,
                           sizeLimit: Int? = nil,
                           desaturate: Bool = false,
                           completion: @escaping (_ image: UIImage?, _ cacheHit: Bool) -> Void) {

        let screenScale = UIScreen.main.scale
        let previewSizeLimit: CGFloat = 280
        let size: ProfileImageSize
        if let sizeLimit = sizeLimit {
            size = CGFloat(sizeLimit) * screenScale < previewSizeLimit ? .preview : .complete
        } else {
            size = .complete
        }

        guard let cacheKey = cacheKey(for: size, sizeLimit: sizeLimit, desaturate: desaturate) as NSString? else {
            return completion(nil, false)
        }

        if let image = cache.cache.object(forKey: cacheKey) {
            return completion(image, true)
        }

        switch size {
        case .preview:
            self.requestPreviewProfileImage()
        default:
            self.requestCompleteProfileImage()
        }

        imageData(for: size, queue: cache.processingQueue) { (imageData) in
            guard let imageData = imageData else {
                return DispatchQueue.main.async {
                    completion(nil, false)
                }
            }

            var image: UIImage?
            if let sizeLimit = sizeLimit {
                image = UIImage(from: imageData, withMaxSize: CGFloat(sizeLimit) * screenScale)
            } else {
                image = UIImage(data: imageData)?.decoded
            }

            if desaturate {
                image = image?.desaturatedImage(with: CIContext.shared)
            }

            if let image = image {
                cache.cache.setObject(image, forKey: cacheKey)
            }

            DispatchQueue.main.async {
                completion(image, false)
            }
        }
    }
}

extension ZMUser: ProfileImageFetchable {}
extension ZMSearchUser: ProfileImageFetchable {}
