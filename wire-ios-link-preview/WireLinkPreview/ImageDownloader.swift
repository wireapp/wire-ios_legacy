//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

protocol ImageDownloaderType {
    func downloadImage(fromURL url: URL, completion: @escaping (Data?) -> Void)
    func downloadImages(fromURLs urls: [URL], completion: @escaping ([URL: Data]) -> Void)
}

final class ImageDownloader: NSObject, ImageDownloaderType {

    typealias ImageData = Data

    let workerQueue: OperationQueue
    let resultsQueue: OperationQueue
    let session: URLSessionType

    init(resultsQueue: OperationQueue,
         workerQueue: OperationQueue = OperationQueue(),
         session: URLSessionType? = nil) {
        self.resultsQueue = resultsQueue
        self.workerQueue = workerQueue
        self.workerQueue.name = String(describing: type(of: self)) + "Queue"
        workerQueue.maxConcurrentOperationCount = 3
        workerQueue.qualityOfService = .default
        self.session = session ?? URLSession(configuration: .ephemeral)
        super.init()
    }

    func downloadImage(fromURL url: URL, completion: @escaping (Data?) -> Void) {
        downloadImages(fromURLs: [url]) { imagesByURL in
            completion(imagesByURL.values.first)
        }
    }

    func downloadImages(fromURLs urls: [URL], completion: @escaping ([URL: ImageData]) -> Void) {
        workerQueue.addOperation { [weak self] in
            guard let `self` = self else { return }
            var result = [URL: ImageData]()
            let group = DispatchGroup()

            urls.forEach { url in
                group.enter()
                self.session.dataTaskWithURL(url) { data, response, _ in
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.contentTypeImage {
                        result[url] = data
                    }
                    group.leave()
                }.resume()
            }

            _ = group.wait(timeout: DispatchTime.distantFuture)
            self.resultsQueue.addOperation {
                completion(result)
            }
        }
    }

}

extension HTTPURLResponse {

    var contentTypeImage: Bool {
        let contentTypeKey = HeaderKey.contentType.rawValue
        guard let contentType = allHeaderFields[contentTypeKey] as? String ?? allHeaderFields[contentTypeKey.lowercased()] as? String else { return false }

        // we don't consider svg a valid image type b/c UIImage doesn't directly
        // support it
        return contentType.contains("image") && !contentType.contains("svg")
    }

}
