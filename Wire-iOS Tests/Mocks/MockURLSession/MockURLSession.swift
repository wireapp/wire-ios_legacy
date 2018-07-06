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
@testable import Wire

enum MockURLResponse {
    case success(Data, URLResponse)
    case error(Error)
}

enum MockURLSessionError: Error {
    case noNetwork
}

/**
 * An object that provides the behavior of a URL session for testing purposes.
 *
 * You provide responses for given URLs by calling `scheduleResponseForURL`.
 */

class MockURLSession: DataTaskSession {

    enum SessionError: Swift.Error {
        case noRequest, noScheduledResponse
    }

    // MARK: - State

    private var cache: URLCache?
    private var delegateQueue: OperationQueue
    private weak var delegate: DataTaskSessionDelegate?

    private var tasks: [MockDataTask] = []
    private var scheduledResponses: [URL: MockURLResponse] = [:]

    // MARK: - Initialization

    init(delegate: DataTaskSessionDelegate, cache: URLCache?, delegateQueue: OperationQueue) {
        self.delegate = delegate
        self.cache = cache
        self.delegateQueue = delegateQueue
    }

    func makeDataTask(with url: URL) -> DataTask {
        let task = MockDataTask(session: self, taskIdentifier: tasks.count)
        task.currentRequest = URLRequest(url: url)
        tasks.append(task)
        return task
    }

    // MARK: - Request/Response Management

    func scheduleResponse(_ response: MockURLResponse, for url: URL) {
        scheduledResponses[url] = response
    }

    func resume(dataTask: DataTask) {

        guard let mockTask = tasks.first(where: { $0.taskIdentifier == dataTask.taskIdentifier }) else {
            return
        }

        guard let requestURL = mockTask.currentRequest?.url else {
            failTask(mockTask, with: SessionError.noRequest)
            return
        }

        // Check the cache for a response

        if let cachedResponse = cache?.cachedResponse(for: URLRequest(url: requestURL)) {
            respondToTask(mockTask, with: cachedResponse.data, response: cachedResponse.response)
        }

        // Check the scheduled response for a response

        guard let scheduledResponse = scheduledResponses[requestURL] else {
            failTask(mockTask, with: SessionError.noScheduledResponse)
            return
        }

        switch scheduledResponse {
        case .success(let data, let response):
            respondToTask(mockTask, with: data, response: response)

        case .error(let error):
            failTask(mockTask, with: error)
        }

    }

    // MARK: - Response

    private func respondToTask(_ task: MockDataTask, with data: Data, response: URLResponse) {

        delegateQueue.addOperation {

            if data.count >= 2 {
                let packetStep = data.count / 2
                let packet1 = data.prefix(upTo: packetStep)
                let packet2 = data.suffix(from: packetStep)
                self.delegate?.dataTaskSession(self, dataTask: task, didReceive: packet1)
                self.delegate?.dataTaskSession(self, dataTask: task, didReceive: packet2)
            } else {
                self.delegate?.dataTaskSession(self, dataTask: task, didReceive: data)
            }

            let cachingCompletionHandler = {
                task.response = response
                self.delegate?.dataTaskSession(self, dataTask: task, didCompleteWithError: nil)
            }

            if let cache = self.cache {
                self.startCaching(data: data, for: response, task: task, in: cache,
                                  completionHandler: cachingCompletionHandler)
            } else {
                cachingCompletionHandler()
            }

        }

    }

    private func startCaching(data: Data, for response: URLResponse, task: DataTask, in cache: URLCache, completionHandler: @escaping () -> Void) {

        let proposedCacheResponse = CachedURLResponse(response: response, data: data)

        self.delegate?.dataTaskSession(self, dataTask: task, willCacheResponse: proposedCacheResponse) { updatedCacheResponse in

            guard let cachedResponse = updatedCacheResponse else {
                completionHandler()
                return
            }

            cache.storeCachedResponse(cachedResponse, for: task.currentRequest!)
            completionHandler()

        }

    }

    private func failTask(_ task: MockDataTask, with error: Error) {
        delegateQueue.addOperation {
            self.delegate?.dataTaskSession(self, dataTask: task, didCompleteWithError: error)
        }
    }

}
