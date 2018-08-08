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
 * next handler will be used. The first handler that returns a valid value will be used, and the call loop will be s
 */

protocol AuthenticationEventHandler: class {
    associatedtype Context
    var contextProvider: AuthenticationContextProvider? { get set }
    func handleEvent(currentStep: AuthenticationFlowStep, context: Context) -> [AuthenticationEventResponseAction]?
}

