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
 * An object that can execute authentication actions.
 */

protocol AuthenticationActioner: class {

    /**
     * Executes the list of actions, in the order they are stored.
     * - parameter actions: The actions to execute.
     */

    func executeActions(_ actions: [AuthenticationCoordinatorAction])
}

extension AuthenticationActioner {

    /**
     * Executes a single action.
     * - parameter action: The action to execute.
     */

    func executeAction(_ action: AuthenticationCoordinatorAction) {
        self.executeActions([action])
    }

    /**
     * Repeats the last action if possible.
     */

    func repeatAction() {
        self.executeAction(.repeatAction)
    }
}

/**
 * An object that can trigger authentication actions.
 */

protocol AuthenticationActionable: class {

    /**
     * The actioner to use to execute the actions. This variable will be set by another
     * object that owns it. It should be stored as `weak` in implementations.
     */

    var actioner: AuthenticationActioner? { get set }
}
