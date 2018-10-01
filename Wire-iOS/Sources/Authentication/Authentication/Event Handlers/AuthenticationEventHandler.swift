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
 * A protocol for objects that handle an event from the authentication stack.
 *
 * Typically, a handler only handles one type of event. Objects conforming to this protocol expose
 * the context type they need to perform their action.
 *
 * The authentication coordinator will call the handlers in the order they were registered. If you return `nil`, the
 * next handler will be used. The first handler that returns a valid value will be used, and the call loop will be stopped.
 */

protocol AuthenticationEventHandler: class {

    /**
     * The type of context objects required to process the event.
     *
     * You can use `Void` if you don't need context to process the event.
     */

    associatedtype Context

    /// The object that provides information about the current status of authentication.
    var statusProvider: AuthenticationStatusProvider? { get set }

    /**
     * Called by the authentication coordinator when it detects an event supported by this object.
     *
     * Using the current step and the context object, use this method to determine if you can handle the event.
     * If you can handle the event, return the actions to execute. If you can't, return `nil`. Do not return an
     * empty array.
     *
     * When a handler cannot handle an event, the coordinator will try to use the next handler, until one provides a
     * valid list of actions.
     */

    func handleEvent(currentStep: AuthenticationFlowStep, context: Context) -> [AuthenticationCoordinatorAction]?

}
