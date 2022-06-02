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
@testable import WireSyncEngine

class TestUserProfileUpdateObserver: NSObject, UserProfileUpdateObserver {

    var invokedCallbacks: [WireSyncEngine.UserProfileUpdateNotificationType] = []

    func passwordUpdateRequestDidFail() {
        invokedCallbacks.append(.passwordUpdateDidFail)
    }

    func emailUpdateDidFail(_ error: Error!) {
        invokedCallbacks.append(.emailUpdateDidFail(error: error))
    }

    func didSendVerificationEmail() {
        invokedCallbacks.append(.emailDidSendVerification)
    }

    func phoneNumberVerificationCodeRequestDidFail(_ error: Error!) {
        invokedCallbacks.append(.phoneNumberVerificationCodeRequestDidFail(error: error))
    }

    func phoneNumberVerificationCodeRequestDidSucceed() {
        invokedCallbacks.append(.phoneNumberVerificationCodeRequestDidSucceed)
    }

    func phoneNumberChangeDidFail(_ error: Error!) {
        invokedCallbacks.append(.phoneNumberChangeDidFail(error: error))
    }

    func didCheckAvailiabilityOfHandle(handle: String, available: Bool) {
        invokedCallbacks.append(.didCheckAvailabilityOfHandle(handle: handle, available: available))
    }

    func didFailToCheckAvailabilityOfHandle(handle: String) {
        invokedCallbacks.append(.didFailToCheckAvailabilityOfHandle(handle: handle))
    }

    func didFailToSetHandleBecauseExisting() {
        invokedCallbacks.append(.didFailToSetHandleBecauseExisting)
    }

    func didFailToSetHandle() {
        invokedCallbacks.append(.didFailToSetHandle)
    }

    func didSetHandle() {
        invokedCallbacks.append(.didSetHandle)
    }

    func didFindHandleSuggestion(handle: String) {
        invokedCallbacks.append(.didFindHandleSuggestion(handle: handle))
    }

    func clearReceivedCallbacks() {
        self.invokedCallbacks = []
    }

}
