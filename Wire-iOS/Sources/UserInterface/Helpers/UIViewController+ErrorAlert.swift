// 
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

import UIKit
import WireSyncEngine
import WireCommonComponents

extension UIViewController {

    func showAlert(for error: LocalizedError, handler: AlertActionHandler? = nil) {
        present(UIAlertController.alertWithOKButton(
                    title: error.errorDescription,
                    message: error.failureReason ?? L10n.Localizable.Error.User.unkownError,
                    okActionHandler: handler),
                    animated: true)

    }

    func showAlert(for error: Error, handler: AlertActionHandler? = nil) {
        let nsError: NSError = error as NSError
        var message = ""

        if nsError.domain == ZMObjectValidationErrorDomain,
            let code: ZMManagedObjectValidationErrorCode = ZMManagedObjectValidationErrorCode(rawValue: nsError.code) {
            switch code {
            case .tooLong:
                message = L10n.Localizable.Error.Input.tooLong
            case .tooShort:
                message = L10n.Localizable.Error.Input.tooShort
            case .emailAddressIsInvalid:
                message = L10n.Localizable.Error.Email.invalid
            case .phoneNumberContainsInvalidCharacters:
                message = L10n.Localizable.Error.Phone.invalid
            default:
                break
            }
        } else if nsError.domain == NSError.ZMUserSessionErrorDomain,
            let code: ZMUserSessionErrorCode = ZMUserSessionErrorCode(rawValue: UInt(nsError.code)) {
            switch code {
            case .noError:
                message = ""
            case .needsCredentials:
                message = L10n.Localizable.Error.User.needsCredentials
            case .domainBlocked:
                message = L10n.Localizable.Error.User.domainBlocked
            case .invalidCredentials:
                message = L10n.Localizable.Error.User.invalidCredentials
            case .accountIsPendingActivation:
                message = L10n.Localizable.Error.User.accountPendingActivation
            case .networkError:
                message = L10n.Localizable.Error.User.networkError
            case .emailIsAlreadyRegistered:
                message = L10n.Localizable.Error.User.emailIsTaken
            case .phoneNumberIsAlreadyRegistered:
                message = L10n.Localizable.Error.User.phoneIsTaken
            case .invalidPhoneNumberVerificationCode, .invalidEmailVerificationCode, .invalidActivationCode:
                message = L10n.Localizable.Error.User.phoneCodeInvalid
            case .registrationDidFailWithUnknownError:
                message = L10n.Localizable.Error.User.registrationUnknownError
            case .invalidPhoneNumber:
                message = L10n.Localizable.Error.Phone.invalid
            case .invalidEmail:
                message = L10n.Localizable.Error.Email.invalid
            case .codeRequestIsAlreadyPending:
                message = L10n.Localizable.Error.User.phoneCodeTooMany
            case .clientDeletedRemotely:
                message = L10n.Localizable.Error.User.deviceDeletedRemotely
            case .lastUserIdentityCantBeDeleted:
                message = L10n.Localizable.Error.User.lastIdentityCantBeDeleted
            case .accountSuspended:
                message = L10n.Localizable.Error.User.accountSuspended
            case .accountLimitReached:
                message = L10n.Localizable.Error.User.accountLimitReached
            case .unknownError:
                message = L10n.Localizable.Error.User.unkownError
            default:
                message = L10n.Localizable.Error.User.unkownError
            }
        } else {
            message = error.localizedDescription
        }

        let alert = UIAlertController.alertWithOKButton(message: message, okActionHandler: handler)
        present(alert, animated: true)
    }
}
