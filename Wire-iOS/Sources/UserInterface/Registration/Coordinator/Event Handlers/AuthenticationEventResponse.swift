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
 * Valid response actions for authentication events.
 */

enum AuthenticationEventResponseAction {
    case hideLoadingView
    case showLoadingView
    case completeLoginFlow
    case completeRegistrationFlow
    case startPostLoginFlow
    case transition(AuthenticationFlowStep, resetStack: Bool)
}

// MARK: - Ordering

extension Array where Element == AuthenticationEventResponseAction {

    /// Sorts the actions in the order they need to be executed.
    var ordered: [AuthenticationEventResponseAction] {
        return self.sorted { a, b in
            switch (a, b) {
            case (.showLoadingView, .hideLoadingView), (.hideLoadingView, .showLoadingView):
                fatalError("Mutually exclusive events were provided, the action set cannot be executed.")

            case (.completeLoginFlow, .completeRegistrationFlow), (.completeRegistrationFlow, .completeLoginFlow):
                fatalError("Mutually exclusive events were provided, the action set cannot be executed.")

            case (.completeLoginFlow, .transition), (.transition, .completeLoginFlow):
                fatalError("Mutually exclusive events were provided, the action set cannot be executed.")

            case (.completeRegistrationFlow, .transition), (.transition, .completeRegistrationFlow):
                fatalError("Mutually exclusive events were provided, the action set cannot be executed.")

            case (.showLoadingView, _), (.hideLoadingView, _):
                // Always show/hide the loading view before doing anything
                return true

            case (_, .showLoadingView), (_, .hideLoadingView):
                // Always show/hide the loading view before doing anything
                return false
                
            default:
                return true
            }

        }
    }


}
