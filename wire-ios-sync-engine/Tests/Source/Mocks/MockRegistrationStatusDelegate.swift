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

class MockRegistrationStatusDelegate: RegistrationStatusDelegate {

    var activationCodeSentCalled = 0
    func activationCodeSent() {
        activationCodeSentCalled += 1
    }

    var activationCodeSendingFailedCalled = 0
    var activationCodeSendingFailedError: Error?
    func activationCodeSendingFailed(with error: Error) {
        activationCodeSendingFailedCalled += 1
        activationCodeSendingFailedError = error
    }

    var activationCodeValidatedCalled = 0
    func activationCodeValidated() {
        activationCodeValidatedCalled += 1
    }

    var activationCodeValidationFailedCalled = 0
    var activationCodeValidationFailedError: Error?
    func activationCodeValidationFailed(with error: Error) {
        activationCodeValidationFailedCalled += 1
        activationCodeValidationFailedError = error
    }

    var teamRegisteredCalled = 0
    func teamRegistered() {
        teamRegisteredCalled += 1
    }

    var userRegisteredCalled = 0
    func userRegistered() {
        userRegisteredCalled += 1
    }

    var teamRegistrationFailedCalled = 0
    var teamRegistrationFailedError: Error?
    func teamRegistrationFailed(with error: Error) {
        teamRegistrationFailedCalled += 1
        teamRegistrationFailedError = error
    }

    var userRegistrationFailedCalled = 0
    var userRegistrationError: Error?
    func userRegistrationFailed(with error: Error) {
        userRegistrationFailedCalled += 1
        userRegistrationError = error
    }
}
