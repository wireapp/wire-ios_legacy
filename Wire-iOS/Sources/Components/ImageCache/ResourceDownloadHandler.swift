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

/**
 * An object that handles the reception of data and errors for data tasks.
 */

class ResourceDownloadHandler: NSObject {

    /**
     * A block of code called with the result of a network data task.
     *
     * - parameter data: The data received by the user.
     * - parameter response: The object describing the HTTP response.
     * - parameter error: The error that prevented the system from starting the request.
     */

    typealias TaskCompletionHandler = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void

    // MARK: - Initialization

    /// In case the resource does not specify a caching duration, this
    /// value will be used instead, to force caching.
    let defaultCachingDuration: Int?

    /**
     * Creates a download handler, with the optional possibility to rewrite requests
     * to force caching.
     *
     * - parameter defaultCachingDuration: If you set this value to `nil`, the handler
     * will only cache requests that were marked as cachable by the server. However, if you
     * want to force caching all requests (for example if a server you're using did not set up
     * caching), you can provide the default caching duration to use in the case of requests
     * without the `Cache-Control` header.
     */

    init(defaultCachingDuration: Int?) {
        self.defaultCachingDuration = defaultCachingDuration
    }

    // MARK: - Scheduling Tasks

    private var completionHandlers: [URLSessionTask: TaskCompletionHandler] = [:]
    private var downloadBuffer: [URLSessionTask: NSMutableData] = [:]

    /**
     * Schedules the task on its parent session, with the given completion handler to
     * call on completion.
     *
     * - parameter task: The network task to execute.
     * - completionHandler: The block of code to execute when the task has completed.
     */

    func schedule(_ task: URLSessionTask, completionHandler: @escaping TaskCompletionHandler) {
        completionHandlers[task] = completionHandler
        task.resume()
    }

}

// MARK: - Session Delegate

extension ResourceDownloadHandler: URLSessionDataDelegate, URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let data = downloadBuffer[task] as Data?
        let completionHandler: TaskCompletionHandler? = completionHandlers[task]
        completionHandler?(data, task.response, error)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let taskBuffer = downloadBuffer[dataTask] else {
            downloadBuffer[dataTask] = NSMutableData(data: data)
            return
        }
        taskBuffer.append(data)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {

        guard let maxAge = defaultCachingDuration else {
            completionHandler(proposedResponse)
            return
        }

        // Validate the request to see if it's eligible for rewrite

        guard let httpResponse = proposedResponse.response as? HTTPURLResponse,
            !httpResponse.allHeaderFields.keys.contains("Cache-Control"),
            (200 ... 226).contains(httpResponse.statusCode) else {
            completionHandler(proposedResponse)
            return
        }

        // Add the cache duration header if it is missing

        var headers = httpResponse.allHeaderFields as! [String:String]
        headers["Cache-Control"] = "max-age=\(maxAge)"

        let updatedResponse = HTTPURLResponse(url: httpResponse.url!,
                                              statusCode: httpResponse.statusCode,
                                              httpVersion: nil,
                                              headerFields: headers)!

        let cachedResponse = CachedURLResponse(response: updatedResponse,
                                               data: proposedResponse.data,
                                               userInfo: proposedResponse.userInfo,
                                               storagePolicy: proposedResponse.storagePolicy)

        completionHandler(cachedResponse)

    }

}
