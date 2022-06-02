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

import UIKit

/**
 * An object that detects company login request wihtin the pasteboard.
 *
 * A session request is a string formatted as `wire-[UUID]`.
 */

public final class CompanyLoginRequestDetector: NSObject {

    /**
     * A struct that describes the result of a login code detection operation..
     */

    public struct DetectorResult: Equatable {
        public let code: String // The detected shared identity login code.
        public let isNew: Bool  // Weather or not the code changed since the last check.
    }

    /// An enum describing the parsing result of a presumed SSO code / email
    ///
    /// - ssoCode: SSO code
    /// - domain: Domain extracted from the email
    /// - unknown: Not matching an email or SSO code
    public enum ParserResult {
        case ssoCode(UUID)
        case domain(String)
        case unknown
    }

    private let pasteboard: Pasteboard
    private let processQueue = DispatchQueue(label: "WireSyncEngine.SharedIdentitySessionRequestDetector")
    private var previouslyDetectedSSOCode: String?

    // MARK: - Initialization

    /// Returns the detector that uses the system pasteboard to detect session requests.
    public static let shared = CompanyLoginRequestDetector(pasteboard: UIPasteboard.general)

    /// Creates a detector that uses the specified pasteboard to detect session requests.
    public init(pasteboard: Pasteboard) {
        self.pasteboard = pasteboard
    }

    // MARK: - Detection

    /**
     * Tries to extract the session request code from the current pasteboard.
     *
     * The processing will be done on a background queue, and the completion
     * handler will be called on the main thread with the result.
     */

    public func detectCopiedRequestCode(_ completionHandler: @escaping (DetectorResult?) -> Void) {
        func complete(_ result: DetectorResult?) {
            previouslyDetectedSSOCode = result?.code
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }

        processQueue.async { [pasteboard, previouslyDetectedSSOCode] in
            guard let text = pasteboard.text else { return complete(nil) }
            guard let code = CompanyLoginRequestDetector.requestCode(in: text) else { return complete(nil) }

            let validSSOCode = "wire-" + code.uuidString
            let isNew = validSSOCode != previouslyDetectedSSOCode
            complete(.init(code: validSSOCode, isNew: isNew))
        }
    }

    /// Parses the input and returns its type (.ssoCode, .domain or .unknown)
    ///
    /// - Parameter input: to be parsed
    /// - Returns: type of input with its eventual associated value
    public static func parse(input: String) -> ParserResult {
        if let domain = domain(from: input) {
            return .domain(domain)
        } else if let code = requestCode(in: input) {
            return .ssoCode(code)
        } else {
            return .unknown
        }
    }

    /// Tries to extract the domain from a given email
    ///
    /// - Parameter email: the email to extract the domain from. e.g. bob@domain.com
    /// - Returns: domain. e.g. domain.com
    private static func domain(from email: String) -> String? {
        guard ZMEmailAddressValidator.isValidEmailAddress(email) else { return nil }
        return email.components(separatedBy: "@").last
    }

    /**
     * Tries to extract the request ID from the contents of the text.
     */

    public static func requestCode(in string: String) -> UUID? {
        guard let prefixRange = string.range(of: "wire-") else {
            return nil
        }

        guard let endIndex = string.index(prefixRange.upperBound, offsetBy: 36, limitedBy: string.endIndex) else {
            return nil
        }

        let codeString = string[prefixRange.upperBound ..< endIndex]
        return UUID(uuidString: String(codeString))
    }

    /**
     * Validates the session request code from the user input.
     */

    public static func isValidRequestCode(in string: String) -> Bool {
        return requestCode(in: string) != nil
    }

}
