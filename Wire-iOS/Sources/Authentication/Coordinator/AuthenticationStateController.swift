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
import WireSystem

private let log = ZMSLog(tag: "Authentication")

/**
 * A type of object that observes changes from an authentication state controller.
 */

protocol AuthenticationStateControllerDelegate: class {

    /**
     * Called when the current state changes in the state controller.
     * - parameter newState: The new state held by the state controller
     * - parameter mode: The kind of change that occured in the state. This
     * influences the way we display the new state.
     */

    func stateDidChange(_ newState: AuthenticationFlowStep, mode: AuthenticationStateController.StateChangeMode)
}

/**
 * An object that controls the state of authentication. Provides advancement
 * and unwinding functionality.
 */

class AuthenticationStateController {

    /**
     * The type of change that occured.
     */

    enum StateChangeMode {
        /**
         * The state was reset to the new value. All the previous states are invalidated.
         * You need to push the new interface to the stack and disable the back button.
         */

        case reset

        /**
         * The state was replaced to the new value. Only the top level state is invalidated,
         * the stack remains available for unwinding. You need to replace the top view controller,
         * and enable the back button.
         */

        case replace

        /**
         * The state was pushed onto the stack. You can enable the back button, if there are previous
         * states in the stack.
         */

        case normal
    }

    /// The object that receives update about the current state and provides visual response.
    weak var delegate: AuthenticationStateControllerDelegate?

    /// The current step in the stack.
    private(set) var currentStep: AuthenticationFlowStep

    /// The stack of all previously executed actions. The last element is the current step.
    private(set) var stack: [AuthenticationFlowStep]

    // MARK: - Initialization

    /// Creates a new state controller with the first state.
    init() {
        currentStep = .start
        stack = [currentStep]
    }

    // MARK: - Transitions

    /**
     * Transitions to the next step in the stack.
     *
     * This method changes the current step, asks the delegate to generates a new
     * interface if needed, and changes the stack, depending on the mode you provide
     * to perform that operation.
     *
     * - parameter step: The step to transition to.
     * - parameter mode: How we should perform the stack transition. See the documentation
     * of `StateChangeMode` for more information. Defaults to `StateChangeMode.normal`.
     */

    func transition(to step: AuthenticationFlowStep, mode: StateChangeMode = .normal) {
        currentStep = step

        switch mode {
        case .normal:
            stack.append(step)
        case .reset:
            stack = [step]
        case .replace:
            stack[stack.endIndex - 1] = step
        }

        delegate?.stateDidChange(currentStep, mode: mode)
    }

    /**
     * Reverts to the previous valid state.
     *
     * You typically call this method after user interface changes to go back to the last
     * valid user state.
     */

    func unwindState() {
        repeat {
            guard stack.count >= 2 else {
                break
            }

            stack.removeLast()
            currentStep = stack.last!
        } while !currentStep.needsInterface
    }

}
