
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
 * Actions that can be performed by the view controllers when authentication fails.
 */

enum AuthenticationErrorFeedbackAction : Int {
    /// The view should display a guidance dot to indicate user input is invalid.
    case showGuidanceDot
    /// The view should clear the input fields.
    case clearInputFields
}

/// A view controller that is managed by an authentication coordinator.
protocol AuthenticationCoordinatedViewController: class {
    /// The object that coordinates authentication.
    var authenticationCoordinator: AuthenticationCoordinator? { get set }
    
    /// The view controller should execute the action to indicate authentication failure.
    ///
    /// - Parameter feedbackAction: The action to execute to provide feedback to the user.
    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction)
    
    /// The view controller should display information about the specified error.
    ///
    /// - Parameter error: The error to present to the user.
    func displayError(_ error: Error)
}
