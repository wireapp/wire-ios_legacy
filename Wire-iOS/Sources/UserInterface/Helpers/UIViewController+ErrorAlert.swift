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
        present(UIAlertController.alertWithOKButton(title: error.errorDescription,
                                                    message: error.failureReason ?? "error.user.unkown_error".localized,
                                                    okActionHandler: handler), animated: true)

    }

    func showAlert(for error: Error, handler: AlertActionHandler? = nil) {
        let nsError: NSError = error as NSError
        var message = ""

        if nsError.domain == ZMObjectValidationErrorDomain,
            let code: ZMManagedObjectValidationErrorCode = ZMManagedObjectValidationErrorCode(rawValue: nsError.code) {
            switch code {
            case .tooLong:
                message = "error.input.too_long".localized
            case .tooShort:
                message = "error.input.too_short".localized
            case .emailAddressIsInvalid:
                message = "error.email.invalid".localized
            case .phoneNumberContainsInvalidCharacters:
                message = "error.phone.invalid".localized
            default:
                break
            }
        } else if nsError.domain == NSError.ZMUserSessionErrorDomain,
            let code: ZMUserSessionErrorCode = ZMUserSessionErrorCode(rawValue: UInt(nsError.code)) {
            switch code {
            case .noError:
                message = ""
            case .needsCredentials:
                message = "error.user.needs_credentials".localized
            case .domainBlocked:
                message = "error.user.domain_blocked".localized
            case .invalidCredentials:
                message = "error.user.invalid_credentials".localized
            case .accountIsPendingActivation:
                message = "error.user.account_pending_activation".localized
            case .networkError:
                message = "error.user.network_error".localized
            case .emailIsAlreadyRegistered:
                message = "error.user.email_is_taken".localized
            case .phoneNumberIsAlreadyRegistered:
                message = "error.user.phone_is_taken".localized
            case .invalidPhoneNumberVerificationCode, .invalidEmailVerificationCode, .invalidActivationCode:
                message = "error.user.phone_code_invalid".localized
            case .registrationDidFailWithUnknownError:
                message = "error.user.registration_unknown_error".localized
            case .invalidPhoneNumber:
                message = "error.phone.invalid".localized
            case .invalidEmail:
                message = "error.email.invalid".localized
            case .codeRequestIsAlreadyPending:
                message = "error.user.phone_code_too_many".localized
            case .clientDeletedRemotely:
                message = "error.user.device_deleted_remotely".localized
            case .lastUserIdentityCantBeDeleted:
                message = "error.user.last_identity_cant_be_deleted".localized
            case .accountSuspended:
                message = "error.user.account_suspended".localized
            case .accountLimitReached:
                message = "error.user.account_limit_reached".localized
            case .unknownError:
                message = "error.user.unkown_error".localized
            default:
                message = "error.user.unkown_error".localized
            }
        } else {
            message = error.localizedDescription
        }

        let alert = UIAlertController.alertWithOKButton(message: message, okActionHandler: handler)
        present(alert, animated: true)
    }
}
