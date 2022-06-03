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

import Foundation

private let userAgent = "Wire LinkPreview Bot"

protocol PreviewDownloaderType {
    func requestOpenGraphData(fromURL url: URL, completion: @escaping (OpenGraphData?) -> Void)
    func tearDown()
}

enum HeaderKey: String {
    case userAgent = "User-Agent"
    case contentType = "Content-Type"
}

final class PreviewDownloader: NSObject, URLSessionDataDelegate, PreviewDownloaderType {

    typealias DownloadCompletion = (OpenGraphData?) -> Void

    var containerByTaskID = [Int: MetaStreamContainer]()
    var completionByURL = [URL: DownloadCompletion]()
    var cancelledTaskIDs = Set<Int>()
    var session: URLSessionType! = nil
    let resultsQueue: OperationQueue
    let parsingQueue: OperationQueue

    init(resultsQueue: OperationQueue, parsingQueue: OperationQueue? = nil, urlSession: URLSessionType? = nil) {
        self.resultsQueue = resultsQueue
        self.parsingQueue = parsingQueue ?? OperationQueue()
        self.parsingQueue.name = String(describing: type(of: self)) + "Queue"
        super.init()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 20
        configuration.httpShouldSetCookies = false
        configuration.isDiscretionary = false
        session = urlSession ?? Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: parsingQueue)
    }

    func requestOpenGraphData(fromURL url: URL, completion: @escaping DownloadCompletion) {
        completionByURL[url] = completion
        var request = URLRequest(url: url)
        // Override the user agent to not get served mobile pages
        request.allHTTPHeaderFields = [HeaderKey.userAgent.rawValue: userAgent]
        session.dataTask(with: request).resume()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        processReceivedData(data, forTask: dataTask as URLSessionDataTaskType, withIdentifier: dataTask.taskIdentifier)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        urlSession(session as URLSessionType, task: task as URLSessionDataTaskType, didCompleteWithError: error as NSError?)
    }

    func urlSession(_ session: URLSessionType, task: URLSessionDataTaskType, didCompleteWithError error: NSError?) {
        guard let url = task.originalRequest?.url, let completion = completionByURL[url] else { return }

        // We do not want to call the completion handler when we cancelled the task,
        // as we cancel it when we received enough data to generate the link preview and will call the completion handler
        // once we parsde the data.
        if !cancelledTaskIDs.contains(task.taskIdentifier) && error != nil {
            completeAndCleanUp(completion, result: nil, url: url, taskIdentifier: task.taskIdentifier)
        }

        // In case the `MetaStreamContainer` fails to produce a string to parse, we need to ensure that we still
        // call the completion handler.
        if let container = containerByTaskID[task.taskIdentifier], !container.reachedEndOfHead && nil == error {
            return completeAndCleanUp(completion, result: nil, url: url, taskIdentifier: task.taskIdentifier)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        urlSession(session as URLSessionType, dataTask: dataTask as URLSessionDataTaskType, didReceiveHTTPResponse: httpResponse, completionHandler: completionHandler)
    }

    func processReceivedData(_ data: Data, forTask task: URLSessionDataTaskType, withIdentifier identifier: Int) {
        let container = containerByTaskID[identifier] ?? MetaStreamContainer()
        container.addData(data)
        containerByTaskID[identifier] = container

        guard let url = task.originalRequest?.url,
            let completion = completionByURL[url] else { return }

        switch task.state {
        case .running:
            guard container.reachedEndOfHead else { return }
            cancel(task: task)
        default:
            break
        }

        parseMetaHeader(container, url: url) { [weak self] result in
            guard let `self` = self else { return }
            self.completeAndCleanUp(completion, result: result, url: url, taskIdentifier: identifier)
        }
    }

    func cancel(task: URLSessionDataTaskType) {
        // When we manually cancel the task, `urlSession(session:task:didCompleteWithError:) will be called,
        // but we do not want to call the completion handler in that case.
        cancelledTaskIDs.insert(task.taskIdentifier)
        task.cancel()
    }

    func completeAndCleanUp(_ completion: DownloadCompletion, result: OpenGraphData?, url: URL, taskIdentifier: Int) {
        completion(result)
        self.containerByTaskID[taskIdentifier] = nil
        self.completionByURL[url] = nil
        self.cancelledTaskIDs.remove(taskIdentifier)
    }

    func parseMetaHeader(_ container: MetaStreamContainer, url: URL, completion: @escaping DownloadCompletion) {
        guard let xmlString = container.head else { return completion(nil) }
        let scanner = OpenGraphScanner(xmlString, url: url) { [weak self] result in
            self?.resultsQueue.addOperation {
                completion(result)
            }
        }

        scanner.parse()
    }

    func tearDown() {
        session.invalidateAndCancel()
    }

}

extension PreviewDownloader {

     /// This method needs to be in an extension to silence a compiler warning that it `nearly` matches
     /// > Instance method 'urlSession(_:dataTask:didReceiveHTTPResponse:completionHandler:)' nearly matches optional requirement 'urlSession(_:dataTask:willCacheResponse:completionHandler:)' of protocol 'URLSessionDataDelegate'
    func urlSession(_ session: URLSessionType, dataTask: URLSessionDataTaskType, didReceiveHTTPResponse response: HTTPURLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        guard let url = dataTask.originalRequest?.url, let completion = completionByURL[url] else { return }
        let (headers, contentTypeKey) = (response.allHeaderFields, HeaderKey.contentType.rawValue)
        let contentType = headers[contentTypeKey] as? String ?? headers[contentTypeKey.lowercased()] as? String
        if let contentType = contentType, !contentType.lowercased().contains("text/html") || !response.isSuccess {
            completeAndCleanUp(completion, result: nil, url: url, taskIdentifier: dataTask.taskIdentifier)
            return completionHandler(.cancel)
        }

        return completionHandler(.allow)
    }

}

extension HTTPURLResponse {

    /// Whether the response is a success.
    var isSuccess: Bool {
        return statusCode < 400
    }

}
