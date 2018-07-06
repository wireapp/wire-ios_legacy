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

// MARK: Protocols

/**
 * A network session task that downloads data.
 */

protocol DataTask: class {

    /// The unique identifier of the task within its session.
    var taskIdentifier: Int { get }

    /// The current request performed by the session.
    var currentRequest: URLRequest? { get }

    /// The response of the session, available if it completed without error.
    var response: URLResponse? { get }

    /// Starts the task.
    func resume()

}

/**
 * An object that schedules and manages data tasks.
 */

protocol DataTaskSession: class {

    /// Creates a data request task for the given URL.
    func makeDataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> DataTask

}

// MARK: - Conformance

extension URLSessionDataTask: DataTask {}

extension URLSession: DataTaskSession {

    func makeDataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> DataTask {
        return dataTask(with: url, completionHandler: completionHandler)
    }

}
