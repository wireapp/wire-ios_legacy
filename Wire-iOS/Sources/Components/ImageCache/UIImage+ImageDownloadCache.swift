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

import UIKit

extension UIImageView {

    /**
     * Displays the image at the given URL, after downloading it in the background.
     *
     * - parameter url: The URL of the image to display.
     * - parameter cache: The cache to use to fetch the image.
     * - parameter onSuccess: The code to execute when the image is displayed.
     * - parameter onError: The code to execute when the image could not be found.
     */

    func displayImage(at url: URL, cache: ImageDownloadCache, onSuccess: ((UIImage) -> Void)?, onError: ((Error?) -> Void)?) {

        cache.fetchImage(at: url) { [weak self] downloadedImage, error in
            self?.image = downloadedImage
            if let downloadedImage = downloadedImage {
                onSuccess?(downloadedImage)
            } else {
                onError?(error)
            }
        }

    }

    /**
     * Displays the image at the given URL, after downloading it in the background with the
     * default cache.
     *
     * - parameter url: The URL of the image to display.
     * - parameter onSuccess: The code to execute when the image is displayed.
     * - parameter onError: The code to execute when the image could not be found.
     */

    @objc(displayImageAtURL:onSuccess:onError:)
    func displayImage(at url: URL, onSuccess: ((UIImage) -> Void)?, onError: ((Error?) -> Void)?) {
        displayImage(at: url, cache: .shared, onSuccess: onSuccess, onError: onError)
    }

    /**
     * Displays the image at the given URL, after downloading it in the background with the
     * default cache.
     *
     * - parameter url: The URL of the image to display.
     */

    @objc(displayImageAtURL:)
    func displayImage(at url: URL) {
        displayImage(at: url, onSuccess: nil, onError: nil)
    }

}

