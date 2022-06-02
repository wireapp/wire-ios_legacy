//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

public class UserProfileUpdateRequestStrategy: AbstractRequestStrategy, ZMSingleRequestTranscoder {

    let userProfileUpdateStatus: UserProfileUpdateStatus

    fileprivate var phoneCodeRequestSync: ZMSingleRequestSync! = nil

    fileprivate var phoneUpdateSync: ZMSingleRequestSync! = nil

    fileprivate var phoneNumberDeleteSync: ZMSingleRequestSync! = nil

    fileprivate var passwordUpdateSync: ZMSingleRequestSync! = nil

    fileprivate var emailUpdateSync: ZMSingleRequestSync! = nil

    fileprivate var handleCheckSync: ZMSingleRequestSync! = nil

    fileprivate var handleSetSync: ZMSingleRequestSync! = nil

    fileprivate var handleSuggestionSearchSync: ZMSingleRequestSync! = nil

    @available (*, unavailable, message: "use `init(managedObjectContext:appStateDelegate:userProfileUpdateStatus)`instead")
    override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        fatalError()
    }

    public init(managedObjectContext: NSManagedObjectContext,
                applicationStatus: ApplicationStatus,
                userProfileUpdateStatus: UserProfileUpdateStatus) {
        self.userProfileUpdateStatus = userProfileUpdateStatus
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = [
            .allowsRequestsWhileUnauthenticated,
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringSlowSync,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsWhileWaitingForWebsocket
        ]

        self.phoneCodeRequestSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.phoneUpdateSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.phoneNumberDeleteSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.passwordUpdateSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.emailUpdateSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.handleCheckSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.handleSetSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.handleSuggestionSearchSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
    }

    @objc public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {

        if self.userProfileUpdateStatus.currentlyRequestingPhoneVerificationCode {
            self.phoneCodeRequestSync.readyForNextRequestIfNotBusy()
            return self.phoneCodeRequestSync.nextRequest(for: apiVersion)
        }

        if self.userProfileUpdateStatus.currentlySettingPhone {
            self.phoneUpdateSync.readyForNextRequestIfNotBusy()
            return self.phoneUpdateSync.nextRequest(for: apiVersion)
        }

        if self.userProfileUpdateStatus.currentlySettingEmail ||
            self.userProfileUpdateStatus.currentlyChangingEmail {
            self.emailUpdateSync.readyForNextRequestIfNotBusy()
            return self.emailUpdateSync.nextRequest(for: apiVersion)
        }

        if self.userProfileUpdateStatus.currentlyRemovingPhoneNumber {
            self.phoneNumberDeleteSync.readyForNextRequestIfNotBusy()
            return self.phoneNumberDeleteSync.nextRequest(for: apiVersion)
        }

        if self.userProfileUpdateStatus.currentlySettingPassword {
            self.passwordUpdateSync.readyForNextRequestIfNotBusy()
            return self.passwordUpdateSync.nextRequest(for: apiVersion)
        }

        if self.userProfileUpdateStatus.currentlyCheckingHandleAvailability {
            self.handleCheckSync.readyForNextRequestIfNotBusy()
            return self.handleCheckSync.nextRequest(for: apiVersion)
        }

        if self.userProfileUpdateStatus.currentlySettingHandle {
            self.handleSetSync.readyForNextRequestIfNotBusy()
            return self.handleSetSync.nextRequest(for: apiVersion)
        }

        if self.userProfileUpdateStatus.currentlyGeneratingHandleSuggestion {
            self.handleSuggestionSearchSync.readyForNextRequestIfNotBusy()
            return self.handleSuggestionSearchSync.nextRequest(for: apiVersion)
        }

        return nil
    }

    // MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch sync {

        case self.phoneCodeRequestSync:
            let payload: NSDictionary = [
                "phone": self.userProfileUpdateStatus.phoneNumberForWhichCodeIsRequested!
            ]
            return ZMTransportRequest(path: "/self/phone", method: .methodPUT, payload: payload, apiVersion: apiVersion.rawValue)

        case self.phoneUpdateSync:
            let payload: NSDictionary = [
                "phone": self.userProfileUpdateStatus.phoneNumberToSet!.phoneNumber!,
                "code": self.userProfileUpdateStatus.phoneNumberToSet!.phoneNumberVerificationCode!,
                "dryrun": false
            ]
            return ZMTransportRequest(path: "/activate", method: .methodPOST, payload: payload, apiVersion: apiVersion.rawValue)

        case self.phoneNumberDeleteSync:
            return ZMTransportRequest(path: "/self/phone", method: .methodDELETE, payload: nil, apiVersion: apiVersion.rawValue)

        case self.passwordUpdateSync:
            let payload: NSDictionary = [
                "new_password": self.userProfileUpdateStatus.passwordToSet!
            ]
            return ZMTransportRequest(path: "/self/password", method: .methodPUT, payload: payload, apiVersion: apiVersion.rawValue)

        case self.emailUpdateSync:
            let payload: NSDictionary = [
                "email": self.userProfileUpdateStatus.emailToSet!
            ]
            return ZMTransportRequest(path: "/access/self/email", method: .methodPUT, payload: payload, authentication: .needsCookieAndAccessToken, apiVersion: apiVersion.rawValue)

        case self.handleCheckSync:
            let handle = self.userProfileUpdateStatus.handleToCheck!
            return ZMTransportRequest(path: "/users/handles/\(handle)", method: .methodHEAD, payload: nil, apiVersion: apiVersion.rawValue)

        case self.handleSetSync:
            let payload: NSDictionary = ["handle": self.userProfileUpdateStatus.handleToSet!]
            return ZMTransportRequest(path: "/self/handle", method: .methodPUT, payload: payload, apiVersion: apiVersion.rawValue)

        case self.handleSuggestionSearchSync:
            guard let handlesToCheck = self.userProfileUpdateStatus.suggestedHandlesToCheck else {
                fatal("Tried to check handles availability, but no handle was available")
            }
            let payload = [
                    "handles": handlesToCheck,
                    "return": 1
                ] as NSDictionary
            return ZMTransportRequest(path: "/users/handles", method: .methodPOST, payload: payload, apiVersion: apiVersion.rawValue)

        default:
            return nil
        }
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        switch sync {

        case self.phoneCodeRequestSync:
            if response.result == .success {
                self.userProfileUpdateStatus.didRequestPhoneVerificationCodeSuccessfully()
            } else {
                let error: Error = NSError.phoneNumberIsAlreadyRegisteredError(with: response) ??
                    NSError.invalidPhoneNumber(withReponse: response) ??
                    NSError(code: .unknownError, userInfo: nil)
                self.userProfileUpdateStatus.didFailPhoneVerificationCodeRequest(error: error)
            }

        case self.phoneUpdateSync:
            if response.result == .success {
                self.userProfileUpdateStatus.didChangePhoneSuccesfully()
            } else {
                let error: Error = NSError.invalidPhoneVerificationCodeError(with: response) ??
                    NSError(code: .unknownError, userInfo: nil)
                self.userProfileUpdateStatus.didFailChangingPhone(error: error)
            }

        case self.passwordUpdateSync:
            if response.result == .success {
                self.userProfileUpdateStatus.didUpdatePasswordSuccessfully()
            } else if response.httpStatus == 403 && response.payloadLabel() == "invalid-credentials" {
                // if the credentials are invalid, we assume that there was a previous password.
                // We decide to ignore this case because there's nothing we can do
                // and since we don't allow to change the password on the client (only to set it once), 
                // this will only be fired in some edge cases
                self.userProfileUpdateStatus.didUpdatePasswordSuccessfully()
            } else {
                self.userProfileUpdateStatus.didFailPasswordUpdate()
            }

        case self.emailUpdateSync:
            if response.result == .success {
                self.userProfileUpdateStatus.didUpdateEmailSuccessfully()
            } else {
                let error: Error = NSError.invalidEmail(with: response) ??
                    NSError.keyExistsError(with: response) ??
                    NSError(code: .unknownError, userInfo: nil)
                self.userProfileUpdateStatus.didFailEmailUpdate(error: error)
            }

        case self.phoneNumberDeleteSync:
            if response.result == .success {
                ZMUser.selfUser(in: managedObjectContext).setValue(nil, forKey: #keyPath(ZMUser.phoneNumber)) // This is a horrible hack for Swift 3.1 not seeing Obj-c private headers
                self.userProfileUpdateStatus.didRemovePhoneNumberSuccessfully()
            } else {
                let error: Error = NSError.lastUserIdentityCantBeRemoved(with: response) ??
                    NSError(code: .unknownError, userInfo: nil)
                self.userProfileUpdateStatus.didFailPhoneNumberRemoval(error: error)
            }

        case self.handleCheckSync:
            let handle = response.rawResponse?.url?.lastPathComponent ?? ""
            if response.result == .success {
                self.userProfileUpdateStatus.didFetchHandle(handle: handle)
            } else {
                if response.httpStatus == 404 {
                    self.userProfileUpdateStatus.didNotFindHandle(handle: handle)
                } else {
                    self.userProfileUpdateStatus.didFailRequestToFetchHandle(handle: handle)
                }
            }

        case self.handleSetSync:
            if response.result == .success {
                self.userProfileUpdateStatus.didSetHandle()
            } else {
                if NSError.keyExistsError(with: response) != nil {
                    self.userProfileUpdateStatus.didFailToSetAlreadyExistingHandle()
                } else {
                    self.userProfileUpdateStatus.didFailToSetHandle()
                }
            }

        case self.handleSuggestionSearchSync:
            if response.result == .success {
                if let availableHandle = (response.payload as? [String])?.first {
                    self.userProfileUpdateStatus.didFindHandleSuggestion(handle: availableHandle)
                } else {
                    self.userProfileUpdateStatus.didNotFindAvailableHandleSuggestion()
                }
            } else {
                self.userProfileUpdateStatus.didFailToFindHandleSuggestion()
            }

        default:
            break
        }
    }

    /// Finds the handle that was searched for suggestion that is not in the given response
    private func findMissingHandleInResponse(response: ZMTransportResponse) -> String? {
        guard let usersPayload = response.payload as? [[String: AnyObject]] else {
            return nil
        }
        guard let possibleHandles = self.userProfileUpdateStatus.suggestedHandlesToCheck else {
            // this should not happen
            return nil
        }

        let existingHandles = Set(usersPayload.compactMap { $0["handle"] as? String })
        for handle in possibleHandles {
            if !existingHandles.contains(handle) {
                return handle
            }
        }
        return nil
    }

}
