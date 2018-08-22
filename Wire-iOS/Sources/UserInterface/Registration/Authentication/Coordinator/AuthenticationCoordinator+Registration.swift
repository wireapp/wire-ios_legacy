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

extension AuthenticationCoordinator: RegistrationStatusDelegate {

    /// Called when the user is registered.
    func userRegistered() {
        // no-op
    }

    /// Called when registration fails.
    func userRegistrationFailed(with error: Error) {
        eventHandlingManager.handleEvent(ofType: .registrationError(error as NSError))
    }

    /// Called when the validation code for the registered credential was sent.
    func activationCodeSent() {
        eventHandlingManager.handleEvent(ofType: .registrationStepSuccess)
    }

    /// Called when the validation code for the registered phone number was sent.
    func activationCodeSendingFailed(with error: Error) {
        eventHandlingManager.handleEvent(ofType: .registrationError(error as NSError))
    }

    /// Called when the phone number verification succeeds.
    func activationCodeValidated() {
        eventHandlingManager.handleEvent(ofType: .registrationStepSuccess)
    }

    /// Called when the phone verification fails.
    func activationCodeValidationFailed(with error: Error) {
        eventHandlingManager.handleEvent(ofType: .registrationError(error as NSError))
    }

    func teamRegistered() {
        // no-op
    }

    func teamRegistrationFailed(with error: Error) {
        // no-op
    }

}
