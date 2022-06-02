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

private let zmLog = ZMSLog(tag: "Network")

enum ConsentType: Int {
    case marketing = 2
}

enum ConsentRequestError: Error {
    case unknown
}

extension ZMUser {
    public typealias CompletionFetch = (Result<Bool>) -> Void

    public func fetchMarketingConsent(in userSession: ZMUserSession,
                                      completion: @escaping CompletionFetch) {
        fetchConsent(for: .marketing, on: userSession.transportSession, completion: completion)
    }

    static func parse(consentPayload: ZMTransportData) -> [ConsentType: Bool] {
        guard let payloadDict = consentPayload.asDictionary(),
            let resultArray = payloadDict["results"] as? [[String: Any]] else {
                return [:]
        }

        var result: [ConsentType: Bool] = [:]

        resultArray.forEach {
            guard let type = $0["type"] as? Int,
                let value = $0["value"] as? Int,
                let consentType = ConsentType(rawValue: type) else {
                    return
            }

            let valueBool = (value == 1)
            result[consentType] = valueBool
        }

        return result
    }

    func fetchConsent(for consentType: ConsentType,
                      on transportSession: TransportSessionType,
                      completion: @escaping CompletionFetch) {

        guard let apiVersion = APIVersion.current else {
            return completion(.failure(ConsentRequestError.unknown))
        }

        let request = ConsentRequestFactory.fetchConsentRequest(apiVersion: apiVersion)

        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in

            guard 200 ... 299 ~= response.httpStatus,
                  let payload = response.payload
            else {
                let error = response.transportSessionError ?? ConsentRequestError.unknown
                zmLog.debug("Error fetching consent status: \(error)")
                completion(.failure(error))
                return
            }

            let parsedPayload = ZMUser.parse(consentPayload: payload)
            let status: Bool = parsedPayload[consentType] ?? false
            completion(.success(status))
        })

        transportSession.enqueueOneTime(request)
    }

    public typealias CompletionSet   = (VoidResult) -> Void
    public func setMarketingConsent(to value: Bool,
                                    in userSession: ZMUserSession,
                                    completion: @escaping CompletionSet) {
        setConsent(to: value, for: .marketing, on: userSession.transportSession, completion: completion)
    }

    func setConsent(to value: Bool,
                    for consentType: ConsentType,
                    on transportSession: TransportSessionType,
                    completion: @escaping CompletionSet) {

        guard let apiVersion = APIVersion.current else {
            return completion(.failure(ConsentRequestError.unknown))
        }

        let request = ConsentRequestFactory.setConsentRequest(for: consentType, value: value, apiVersion: apiVersion)

        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in

            guard 200 ... 299 ~= response.httpStatus
                else {
                    let error = response.transportSessionError ?? ConsentRequestError.unknown
                    zmLog.debug("Error setting consent status: \(error)")
                    completion(.failure(error))
                    return
            }

            completion(.success)
        })

        transportSession.enqueueOneTime(request)
    }
}

struct ConsentRequestFactory {
    static let consentPath = "/self/consent"

    static func fetchConsentRequest(apiVersion: APIVersion) -> ZMTransportRequest {
        return .init(getFromPath: consentPath, apiVersion: apiVersion.rawValue)
    }

    static var sourceString: String {
        return "iOS " + Bundle.main.version
    }

    static func setConsentRequest(for consentType: ConsentType, value: Bool, apiVersion: APIVersion) -> ZMTransportRequest {
        let payload: [String: Any] = [
            "type": consentType.rawValue,
            "value": value ? 1:0,
            "source": sourceString
        ]
        return .init(path: consentPath,
                     method: .methodPUT,
                     payload: payload as ZMTransportData,
                     apiVersion: apiVersion.rawValue)
    }
}
