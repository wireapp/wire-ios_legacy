//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@testable import WireLinkPreview

class MockURLSessionDataTask: URLSessionDataTaskType {

    var taskIdentifier = 0
    var resumeCallCount = 0
    var cancelCallCount = 0
    var mockOriginalRequest: URLRequest?
    var state: URLSessionTask.State = .completed

    var originalRequest: URLRequest? {
        return mockOriginalRequest
    }

    func resume() {
        resumeCallCount += 1
        state = .running
    }

    func cancel() {
        cancelCallCount += 1
        state = .canceling
    }
}

class MockURLSession: URLSessionType {

    var dataTaskWithURLCallCount = 0
    var dataTaskWithURLParameters = [URLRequest]()
    var dataTaskWithURLClosureCallCount = 0
    var dataTaskWithURLClosureCompletions = [DataTaskCompletion]()
    var mockDataTask: MockURLSessionDataTask?
    var dataTaskGenerator: ((URL, DataTaskCompletion) -> URLSessionDataTaskType)?

    func dataTask(with request: URLRequest) -> URLSessionDataTaskType {
        dataTaskWithURLCallCount += 1
        dataTaskWithURLParameters.append(request)
        return mockDataTask!
    }

    func dataTaskWithURL(_ url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskType {
        dataTaskWithURLClosureCallCount += 1
        dataTaskWithURLClosureCompletions.append(completionHandler)
        if let generator = dataTaskGenerator {
            return generator(url, completionHandler)
        } else {
            completionHandler(nil, nil, nil)
            return mockDataTask!
        }
    }

    var invalidated = false
    func invalidateAndCancel() {
        invalidated = true
    }
}
