//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

final class RegistationCredentialVerificationStrategy: NSObject {
    let registrationStatus: RegistrationStatusProtocol
    var codeSendingSync: ZMSingleRequestSync!

    init(groupQueue: ZMSGroupQueue, status: RegistrationStatusProtocol) {
        registrationStatus = status
        super.init()
        codeSendingSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: groupQueue)
    }
}

extension RegistationCredentialVerificationStrategy: ZMSingleRequestTranscoder {
    func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        let currentStatus = registrationStatus
        var payload: [String: Any]
        var path: String

        switch currentStatus.phase {
        case let .sendActivationCode(credentials):
            path = "/activate/send"
            payload = [credentials.type: credentials.rawValue,
                       "locale": NSLocale.formattedLocaleIdentifier()!]
        case let .checkActivationCode(credentials, code):
            path = "/activate"
            payload = [credentials.type: credentials.rawValue,
                       "code": code,
                       "dryrun": true]
        default:
            fatal("Generating request for invalid phase: \(currentStatus.phase)")
        }

        return ZMTransportRequest(path: path, method: .methodPOST, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
    }

    func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        if response.result == .success {
            registrationStatus.success()
        } else {
            let error: NSError

            switch registrationStatus.phase {
            case .sendActivationCode(let credentials):
                let decodedError: NSError?
                switch credentials {
                case .email:
                    decodedError = NSError.domainBlocked(with: response) ??
                    NSError.blacklistedEmail(with: response) ??
                    NSError.emailAddressInUse(with: response) ??
                    NSError.invalidEmail(with: response)

                case .phone:
                    decodedError = NSError.phoneNumberIsAlreadyRegisteredError(with: response) ??
                    NSError.invalidPhoneNumber(withReponse: response)
                }

                error = decodedError ?? NSError(code: .unknownError, userInfo: [:])
            case .checkActivationCode:
                error = NSError.invalidActivationCode(with: response) ??
                    NSError(code: .unknownError, userInfo: [:])
            default:
                fatal("Error occurs for invalid phase: \(registrationStatus.phase)")
            }
            registrationStatus.handleError(error)
        }
    }

}

extension RegistationCredentialVerificationStrategy: RequestStrategy {
    func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        switch registrationStatus.phase {
        case .sendActivationCode, .checkActivationCode:
            codeSendingSync.readyForNextRequestIfNotBusy()
            return codeSendingSync.nextRequest(for: apiVersion)
        default:
            return nil
        }
    }
}
