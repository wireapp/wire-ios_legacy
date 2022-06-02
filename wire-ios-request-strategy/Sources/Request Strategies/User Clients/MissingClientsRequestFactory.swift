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
import WireDataModel

extension Collection where Element == UserClient {

    var clientListByUserID: Payload.ClientListByUserID {

        let initial: Payload.ClientListByUserID = [:]

        return self.reduce(into: initial) { (result, client) in
            guard let userID = client.user?.remoteIdentifier.transportString(),
                  let clientID = client.remoteIdentifier
            else {
                return
            }

            result[userID, default: []].append(clientID)
        }
    }

    var clientListByDomain: Payload.ClientListByQualifiedUserID {
        let initial: Payload.ClientListByQualifiedUserID = [:]

        return self.reduce(into: initial) { (result, client) in
            guard let userID = client.user?.remoteIdentifier.transportString(),
                  let clientID = client.remoteIdentifier,
                  let domain = client.user?.domain ?? APIVersion.domain
            else {
                return
            }

            result[domain, default: Payload.ClientListByUserID()][userID, default: []].append(clientID)
        }
    }

}

public final class MissingClientsRequestFactory {

    let pageSize: Int
    let defaultEncoder = JSONEncoder.defaultEncoder

    public init(pageSize: Int = 128) {
        self.pageSize = pageSize
    }

    public func fetchPrekeys(for missingClients: Set<UserClient>, apiVersion: APIVersion) -> ZMUpstreamRequest? {
        guard
            apiVersion == .v0,
            let payloadData = missingClients.prefix(pageSize).clientListByUserID.payloadData(encoder: defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        let request = ZMTransportRequest(path: "/users/prekeys",
                                         method: .methodPOST,
                                         payload: payloadAsString as ZMTransportData?,
                                         apiVersion: apiVersion.rawValue)
        let userClientMissingKeySet: Set<String> = [ZMUserClientMissingKey]
        return ZMUpstreamRequest(keys: userClientMissingKeySet,
                                 transportRequest: request,
                                 userInfo: nil)
    }

    public func fetchPrekeysFederated(for missingClients: Set<UserClient>, apiVersion: APIVersion) -> ZMUpstreamRequest? {
        guard
            apiVersion > .v0,
            let payloadData = missingClients.prefix(pageSize).clientListByDomain.payloadData(encoder: defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        let request = ZMTransportRequest(path: "/users/list-prekeys",
                                         method: .methodPOST,
                                         payload: payloadAsString as ZMTransportData?,
                                         apiVersion: apiVersion.rawValue)
        let userClientMissingKeySet: Set<String> = [ZMUserClientMissingKey]
        return ZMUpstreamRequest(keys: userClientMissingKeySet,
                                 transportRequest: request,
                                 userInfo: nil)
    }

}

public func identity<T>(value: T) -> T {
    return value
}
