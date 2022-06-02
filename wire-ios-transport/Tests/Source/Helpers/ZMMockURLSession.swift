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

import WireTransport

@objc class ZMMockURLSession: ZMURLSession {

    @objc var cancellationHandler: (() -> Void)? = nil

    @objc static func createMockSession() -> ZMMockURLSession {
        return ZMMockURLSession(configuration: .ephemeral, trustProvider: MockEnvironment(), delegate: ZMMockURLSessionDelegate(), delegateQueue: OperationQueue(), identifier: "ZMMockURLSession", userAgent: "Test UserAgent")
    }

    @objc(createMockSessionWithDelegate:)
    static func createMockSession(delegate: ZMURLSessionDelegate) -> ZMMockURLSession {
        return ZMMockURLSession(configuration: .ephemeral, trustProvider: MockEnvironment(), delegate: delegate, delegateQueue: OperationQueue(), identifier: "ZMMockURLSession", userAgent: "Test UserAgent")
    }

    override func cancelAllTasks(completionHandler handler: @escaping () -> Void) {
        super.cancelAllTasks {
            handler()
            self.cancellationHandler?()
        }
    }

}

// MARK: - Delegate

@objc class ZMMockURLSessionDelegate: NSObject, ZMURLSessionDelegate {

    func urlSession(_ URLSession: ZMURLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // no-op
    }

    func urlSessionDidReceiveData(_ URLSession: ZMURLSession) {
        // no-op
    }
    
    func urlSession(_ URLSession: ZMURLSession, didDetectUnsafeConnectionToHost host: String) {
        // no-op
    }

    func urlSession(_ URLSession: ZMURLSession, taskDidComplete task: URLSessionTask, transportRequest: ZMTransportRequest, responseData: Data) {
        // no-op
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession URLSession: ZMURLSession) {
        // no-op
    }

}
