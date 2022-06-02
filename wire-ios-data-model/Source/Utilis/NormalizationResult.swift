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
import WireUtilities

/**
 * The result of normalizing a value.
 */

public enum NormalizationResult<Value> {

    /// The value is valid, but was potentially changed during normalization. You should use the
    /// value provided as a side-effect here for any further usage.
    case valid(Value)

    /// The value is invalid, because of the given reason.
    case invalid(ZMManagedObjectValidationErrorCode)

    /// The value was not marked valid, but no reason was provided.
    case unknownError

    /// Returns whether the value is valid.
    public var isValid: Bool {
        if case .valid = self {
            return true
        }

        return false
    }

}

// MARK: - Bridging

extension NormalizationResult where Value: NSObjectProtocol {

    public init(_ result: ZMPropertyNormalizationResult<Value>) {
        if result.isValid {
            guard let normalizedValue = result.normalizedValue else {
                self = .unknownError
                return
            }

            self = .valid(normalizedValue)
            return
        } else {
            if let error = result.validationError as NSError?, let code = ZMManagedObjectValidationErrorCode(rawValue: error.code) {
                self = .invalid(code)
                return
            }

            self = .unknownError
        }
    }

}

extension NormalizationResult where Value == String {

    public init(_ bridgableResult: ZMPropertyNormalizationResult<NSString>) {
        let result = NormalizationResult<NSString>(bridgableResult)

        switch result {
        case .valid(let objcValue):
            self = .valid(objcValue as String)

        case .invalid(let errorCode):
            self = .invalid(errorCode)

        case .unknownError:
            self = .unknownError
        }
    }

}

public extension ZMUser {

    @objc static func normalizeName(_ name: String) -> ZMPropertyNormalizationResult<NSString> {
        var name: String? = name
        var outError: Error?
        var result: Bool = false

        do {
            result = try ZMUser.validate(name: &name)
        } catch let error {
            outError = error
        }

        return ZMPropertyNormalizationResult<NSString>(result: result, normalizedValue: name as NSString? ?? "", validationError: outError)
    }

    @objc static func normalizeEmailAddress(_ emailAddress: String) -> ZMPropertyNormalizationResult<NSString> {
        var emailAddress: String? = emailAddress
        var outError: Error?
        var result: Bool = false

        do {
            result = try ZMUser.validate(emailAddress: &emailAddress)
        } catch let error {
            outError = error
        }

        return ZMPropertyNormalizationResult<NSString>(result: result, normalizedValue: emailAddress as NSString? ?? "", validationError: outError)
    }

    @objc static func normalizePassword(_ password: String) -> ZMPropertyNormalizationResult<NSString> {
        var password: String? = password
        var outError: Error?
        var result: Bool = false

        do {
            result = try ZMUser.validate(password: &password)
        } catch let error {
            outError = error
        }

        return ZMPropertyNormalizationResult<NSString>(result: result, normalizedValue: password as NSString? ?? "", validationError: outError)
    }

    @objc static func normalizeVerificationCode(_ verificationCode: String) -> ZMPropertyNormalizationResult<NSString> {
        var verificationCode: String? = verificationCode
        var outError: Error?
        var result: Bool = false

        do {
            result = try ZMUser.validate(phoneVerificationCode: &verificationCode)
        } catch let error {
            outError = error
        }

        return ZMPropertyNormalizationResult<NSString>(result: result, normalizedValue: verificationCode as NSString? ?? "", validationError: outError)
    }

    @objc static func normalizePhoneNumber(_ phoneNumber: String) -> ZMPropertyNormalizationResult<NSString> {
        var phoneNumber: String? = phoneNumber
        var outError: Error?
        var result: Bool = false

        do {
            result = try ZMUser.validate(phoneNumber: &phoneNumber)
        } catch let error {
            outError = error
        }

        return ZMPropertyNormalizationResult<NSString>(result: result, normalizedValue: phoneNumber as NSString? ?? "", validationError: outError)
    }

}
