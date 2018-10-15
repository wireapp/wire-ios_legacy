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

protocol AuthenticationStateControllerDelegate: class {
    func stateDidChange(_ newState: AuthenticationFlowStep, withReset resetStack: Bool)
}

/**
 * An object that controls the state of authentication. Provides advancement
 * and unwinding functionality.
 */

class AuthenticationStateController {

    /// The handle to the OS log for authentication.
    let log = ZMSLog(tag: "Authentication")

    /// The object that receives update about the current state and provides visual response.
    weak var delegate: AuthenticationStateControllerDelegate?

    /// The current step in the stack.
    private(set) var currentStep: AuthenticationFlowStep

    /// The stack of all previously executed actions. The last element is the current step.
    private(set) var stack: [AuthenticationFlowStep]

    // MARK: - Initialization

    init() {
        currentStep = .start
        stack = [currentStep]
    }

    // MARK: - Transitions

    /**
     * Replaces the current step with another step.
     * This is useful for cases where the user can switch between flows using a tab bar.
     * - parameter newStep: The new step of the authentication.
     * - warning: This is not recommended, as we should have a unique UI for each state.
     */

    func replaceCurrentStep(with newStep: AuthenticationFlowStep) {
        log.warn("Replacing the step directly for \(newStep). This is not recommended and will be removed in a future version.")
        currentStep = newStep
        stack[stack.endIndex - 1] = newStep
    }

    /**
     * Transitions to the next step in the stack.
     *
     * This method changes the current step, asks the delegate to generates a new
     * interface if needed, and changes the stack (either appends the new step to the
     * list of previous steps, or resets the stack if you request it).
     *
     * - parameter step: The step to transition to.
     * - parameter resetStack: Whether transitioning to this step resets the previous stack
     * of view controllers in the navigation controller. You should pass `true` if your step
     * is at the beginning of a new "logical flow" (ex: deleting clients). Defaults to `false`.
     */

    func transition(to step: AuthenticationFlowStep, resetStack: Bool = false) {
        currentStep = step

        if resetStack {
            stack = [step]
        } else {
            stack.append(step)
        }

        delegate?.stateDidChange(currentStep, withReset: resetStack)
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
