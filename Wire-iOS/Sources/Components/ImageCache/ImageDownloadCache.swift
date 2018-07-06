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

enum ImageDownloadCacheError: Error, Equatable {
    case invalidResponse
    case invalidResponseCode(Int)
}

/**
 * An object that fetches and caches remote images.
 */

class ImageDownloadCache {

    /// The session that performs network requests.
    private let session: DataTaskSession

    /// The object that handles image downloads.
    private let downloadHandler: ResourceDownloadHandler

    /// The operation queue used for decoding images.
    private let imageDecodingQueue = OperationQueue()

    // MARK: - Initialization

    /**
     * Creates the cache for downloading images.
     *
     * - parameter memoryCapacity: The size to allocate for the cache in memeory, in megabytes.
     * - parameter diskCapacity: The size to allocate for the cache in memory, in megabytes.
     * - parameter defaultCachingDuration: The duration for which images should be cached, if
     * the server did not mark them as cachable. You can pass `nil` if you only want to cache
     * explicitly cachable images.
     * - parameter sessionType: The type of session to use.
     */

    init(downloadHandler: ResourceDownloadHandler, session: DataTaskSession) {
        self.downloadHandler = downloadHandler
        self.session = session
    }

    /**
     * A shared image cache.
     *
     * It holds up to 100MB of images in memory, and up to 200MB on disk. It keeps images in the cache for
     * 2 hours, unless the URL specifies a different value.
     */

    static let shared: ImageDownloadCache = {

        let downloadHandler = ResourceDownloadHandler(defaultCachingDuration: 7200)

        let cache = URLCache(memoryCapacity: 100 * 1024 * 1024,
                             diskCapacity: 200 * 1024 * 1024, diskPath: nil)

        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.urlCache = cache

        let networkQueue = OperationQueue()
        let session = URLSession(configuration: sessionConfiguration, delegate: downloadHandler, delegateQueue: networkQueue)

        return ImageDownloadCache(downloadHandler: downloadHandler, session: session)

    }()

    // MARK: - Image Fetching

    /**
     * Requests to get the image at the specified URL.
     *
     * Once the data was received from the server, the image will be decoded in the
     * background, and passed to the main thread through the completion handler.
     *
     * - parameter url: The URL of the image to download.
     * - parameter completionHandler: The block of code that will be executed on the
     * main thread with the retrieved image.
     * - parameter image: The image downloaded from the specified URL, or `nil` if no
     * image was available at this URL.
     */

    func fetchImage(at url: URL, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {

        let downloadTask = session.makeDataTask(with: url)

        let resultHandler: (UIImage?, Error?) -> Void = { image, error in
            OperationQueue.main.addOperation {
                completionHandler(image, error)
            }
        }

        // Attempts decoding an image as local,

        downloadHandler.schedule(downloadTask) { data, response, error in

            if let error = error {
                resultHandler(nil, error)
                return
            }

            guard let responseCode = response?.statusCode else {
                resultHandler(nil, ImageDownloadCacheError.invalidResponse)
                return
            }

            guard let responseData = data else {
                resultHandler(nil, ImageDownloadCacheError.invalidResponse)
                return
            }

            guard (200 ..< 300).contains(responseCode) else {
                resultHandler(nil, ImageDownloadCacheError.invalidResponseCode(responseCode))
                return
            }

            self.decodeImage(with: responseData) {
                resultHandler($0, nil)
            }

        }

    }

    /**
     * Schedules an attempt to decode the image from the given data.
     */

    private func decodeImage(with data: Data, resultHandler: @escaping (UIImage?) -> Void) {

        let decodingOperation = DecodeImageOperation(imageData: data)

        decodingOperation.completionBlock = {
            resultHandler(decodingOperation.decodedImage)
        }

        imageDecodingQueue.addOperation(decodingOperation)

    }

}
