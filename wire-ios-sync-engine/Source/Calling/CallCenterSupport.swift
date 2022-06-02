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

/// An opaque OTR calling message.

public typealias WireCallMessageToken = UnsafeMutableRawPointer

/// The possible types of call.

public enum AVSCallType: Int32 {

    case normal = 0
    case video = 1
    case audioOnly = 2

}

/// Possible types of conversation in which calls can be initiated.

public enum AVSConversationType: Int32 {

    case oneToOne = 0
    case group = 1
    case conference = 2

}

 /// An object that represents a calling event.

public struct CallEvent {

    let data: Data
    let currentTimestamp: Date
    let serverTimestamp: Date
    let conversationId: AVSIdentifier
    let userId: AVSIdentifier
    let clientId: String

}

// MARK: - Call center transport

/// A block of code executed when the config request finishes.

public typealias CallConfigRequestCompletion = (String?, Int) -> Void

/// An object that can perform requests on behalf of the call center.

public protocol WireCallCenterTransport: AnyObject {

    /// Sends a calling message.
    ///
    /// - Parameters:
    ///     - data: The message payload.
    ///     - conversationId: The conversation in which the message is sent.
    ///     - targets: Exact recipients of the message. If `nil`, all conversation participants are recipients.
    ///     - completionHandler: A handler when the network request completes with http status code.

    func send(data: Data, conversationId: AVSIdentifier, targets: [AVSClient]?, completionHandler: @escaping ((_ status: Int) -> Void))

    /// Send a calling message to the SFT server (for conference calling).
    ///
    /// - Parameters:
    ///     - data: The message payload.
    ///     - url: The url of the server.
    ///     - completionHandler: A handler when the network request completes with the response payload.

    func sendSFT(data: Data, url: URL, completionHandler: @escaping ((Result<Data>) -> Void))

    /// Request the call configuration from the backend.
    ///
    /// - Parameters:
    ///     - completionHandler: A handler when the network request completes with the response payload.

    func requestCallConfig(completionHandler: @escaping CallConfigRequestCompletion)

    /// Request the client list for a conversation.
    ///
    /// - Parameters:
    ///     - conversationId: A conversation from which the client list is queried.
    ///     - completionHandler: A handler when the network request completes with the list of clients.

    func requestClientsList(conversationId: AVSIdentifier, completionHandler: @escaping ([AVSClient]) -> Void)

}
