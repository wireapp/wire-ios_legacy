//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

/// An EntityActionHandler is responsible for performing actions requested by an EntityAction.
///
public protocol EntityActionHandler {
    associatedtype Action

    /// Perform the action represented by Action
    ///
    /// When the action is complete or has failed the EntityActionHandler should
    /// call `notifyResult()` on the action. The EntityActionHandler is expected to
    /// retain the action until this method has been called.
    ///
    func performAction(_ action: Action)
}

/// Represents an action which an entity can request to be performed.
///
public protocol EntityAction {
    associatedtype Result
    associatedtype Failure: Error

    var resultHandler: ResultHandler? { get set }
}

public extension EntityAction {

    typealias ResultHandler = (Swift.Result<Result, Failure>) -> Void

    static var notificationName: Notification.Name {
        return Notification.Name(String(describing: Self.Type.self))
    }

    static var userInfoKey: String {
        return "action"
    }

    /// Request the action to be performed
    func send(in context: NotificationContext) {
        NotificationInContext(name: Self.notificationName,
                              context: context,
                              object: nil,
                              userInfo: [Self.userInfoKey: self]).post()
    }

    /// Called by an `EntityActionHandler` when the action has been performed.
    mutating func notifyResult(_ result: Swift.Result<Result, Failure>) {
        let resultHandler = self.resultHandler
        self.resultHandler = nil

        DispatchQueue.main.async {
            resultHandler?(result)
        }
    }

    /// Register a result handler which will be called when the action has been performed.
    mutating func onResult(resultHandler: @escaping ResultHandler) {
        self.resultHandler = resultHandler
    }

    /// Register an action handler
    ///
    /// - parameters:
    ///   - handler: action handler
    ///   - context: context in which to listen for actions
    ///   - queue: queue on which the `performAction()` will be called
    static func registerHandler<Handler: EntityActionHandler>(_ handler: Handler,
                                                              context: NotificationContext,
                                                              queue: OperationQueue? = nil) -> Any where Handler.Action == Self {
        return NotificationInContext.addObserver(name: notificationName,
                                          context: context,
                                          object: nil,
                                          queue: queue) { (note) in

            guard let action = note.userInfo[userInfoKey] as? Handler.Action else {
                return
            }

            handler.performAction(action)
        }
    }

}

public extension EntityAction {

    /// Notify a success result.
    ///
    /// - Parameter result: The successful result.

    mutating func succeed(with result: Result) {
        notifyResult(.success(result))
    }

    /// Notify a failed result.
    ///
    /// - Parameter failure: The reason the action failured.

    mutating func fail(with failure: Failure) {
        notifyResult(.failure(failure))
    }

}

public extension EntityAction where Result == Void {

    /// Notify a success result.

    mutating func succeed() {
        notifyResult(.success(()))
    }

}
