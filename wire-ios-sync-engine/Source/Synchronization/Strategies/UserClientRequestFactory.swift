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
import WireCryptobox

enum UserClientRequestError: Error {
    case noPreKeys
    case noLastPreKey
    case clientNotRegistered
}

// TODO: when we should update last pre key or signaling keys?

public final class UserClientRequestFactory {

    // This is needed to save ~3 seconds for every unit test run
    // as generating 100 keys is an expensive operation
    static var _test_overrideNumberOfKeys: UInt16?

    unowned var keyStore: UserClientKeysStore
    public let keyCount: UInt16

    public init(keysCount: UInt16 = 100,
                keysStore: UserClientKeysStore) {
        self.keyCount = (UserClientRequestFactory._test_overrideNumberOfKeys ?? keysCount)
        self.keyStore = keysStore
    }

    public func registerClientRequest(_ client: UserClient, credentials: ZMEmailCredentials?, cookieLabel: String, apiVersion: APIVersion) throws -> ZMUpstreamRequest {

        let (preKeysPayloadData, preKeysRangeMax) = try payloadForPreKeys(client)
        let (signalingKeysPayloadData, signalingKeys) = payloadForSignalingKeys()
        let lastPreKeyPayloadData = try payloadForLastPreKey(client)

        var payload: [String: Any] = [
            "type": client.type.rawValue,
            "label": (client.label ?? ""),
            "model": (client.model ?? ""),
            "class": (client.deviceClass?.rawValue ?? DeviceClass.phone.rawValue),
            "lastkey": lastPreKeyPayloadData,
            "prekeys": preKeysPayloadData,
            "sigkeys": signalingKeysPayloadData,
            "cookie": cookieLabel
        ]

        if let password = credentials?.password {
            payload["password"] = password
        }

        if let verificationCode = credentials?.emailVerificationCode {
            payload["verification_code"] = verificationCode
        }

        let request = ZMTransportRequest(path: "/clients", method: ZMTransportRequestMethod.methodPOST, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
        request.add(storeMaxRangeID(client, maxRangeID: preKeysRangeMax))
        request.add(storeAPSSignalingKeys(client, signalingKeys: signalingKeys))

        let upstreamRequest = ZMUpstreamRequest(transportRequest: request)
        return upstreamRequest!
    }

    func storeMaxRangeID(_ client: UserClient, maxRangeID: UInt16) -> ZMCompletionHandler {
        let completionHandler = ZMCompletionHandler(on: client.managedObjectContext!, block: { [weak client] response in
            guard let client = client else { return }
            if response.result == .success {
                client.preKeysRangeMax = Int64(maxRangeID)
            }
        })
        return completionHandler
    }

    func storeAPSSignalingKeys(_ client: UserClient, signalingKeys: SignalingKeys) -> ZMCompletionHandler {
        let completionHandler = ZMCompletionHandler(on: client.managedObjectContext!, block: { [weak client] response in
            guard let client = client else { return }
            if response.result == .success {
                client.apsDecryptionKey = signalingKeys.decryptionKey
                client.apsVerificationKey = signalingKeys.verificationKey
                client.needsToUploadSignalingKeys = false
            }
        })
        return completionHandler
    }

    func storeCapabilitiesHandler(_ client: UserClient) -> ZMCompletionHandler {
        let completionHandler = ZMCompletionHandler(on: client.managedObjectContext!, block: { [weak client] response in
            guard let client = client else { return }
            if response.result == .success {
                client.needsToUpdateCapabilities = false
            }
        })
        return completionHandler
    }

    internal func payloadForPreKeys(_ client: UserClient, startIndex: UInt16 = 0) throws -> (payload: [[String: Any]], maxRange: UInt16) {
        // we don't want to generate new prekeys if we already have them
        do {
            let preKeys = try keyStore.generateMoreKeys(keyCount, start: startIndex)
            guard preKeys.count > 0 else {
                throw UserClientRequestError.noPreKeys
            }
            let preKeysPayloadData: [[String: Any]] = preKeys.map {
                ["key": $0.prekey, "id": NSNumber(value: $0.id)]
            }
            return (preKeysPayloadData, preKeys.last!.id)
        } catch {
            throw UserClientRequestError.noPreKeys
        }
    }

    internal func payloadForLastPreKey(_ client: UserClient) throws -> [String: Any] {
        do {
            let lastKey = try keyStore.lastPreKey()
            let lastPreKeyString = lastKey
            let lastPreKeyPayloadData: [String: Any] = [
                "key": lastPreKeyString,
                "id": NSNumber(value: CBOX_LAST_PREKEY_ID)
            ]
            return lastPreKeyPayloadData
        } catch {
            throw UserClientRequestError.noLastPreKey
        }
    }

    internal func payloadForSignalingKeys() -> (payload: [String: String], signalingKeys: SignalingKeys) {
        let signalingKeys = APSSignalingKeysStore.createKeys()
        let payload = ["enckey": signalingKeys.decryptionKey.base64String(), "mackey": signalingKeys.verificationKey.base64String()]
        return (payload, signalingKeys)
    }

    public func updateClientPreKeysRequest(_ client: UserClient, apiVersion: APIVersion) throws -> ZMUpstreamRequest {
        if let remoteIdentifier = client.remoteIdentifier {
            let startIndex = UInt16(client.preKeysRangeMax)
            let (preKeysPayloadData, preKeysRangeMax) = try payloadForPreKeys(client, startIndex: startIndex)
            let payload: [String: Any] = [
                "prekeys": preKeysPayloadData
            ]
            let request = ZMTransportRequest(path: "/clients/\(remoteIdentifier)", method: ZMTransportRequestMethod.methodPUT, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
            request.add(storeMaxRangeID(client, maxRangeID: preKeysRangeMax))

            let userClientNumberOfKeysRemainingKeySet: Set<String> = [ZMUserClientNumberOfKeysRemainingKey]
            return ZMUpstreamRequest(keys: userClientNumberOfKeysRemainingKeySet, transportRequest: request, userInfo: nil)
        }
        throw UserClientRequestError.clientNotRegistered
    }

    public func updateClientSignalingKeysRequest(_ client: UserClient, apiVersion: APIVersion) throws -> ZMUpstreamRequest {
        if let remoteIdentifier = client.remoteIdentifier {
            let (signalingKeysPayloadData, signalingKeys) = payloadForSignalingKeys()
            let payload: [String: Any] = [
                "sigkeys": signalingKeysPayloadData,
                "prekeys": [] // NOTE backend always expects 'prekeys' to be present atm
            ]
            let request = ZMTransportRequest(path: "/clients/\(remoteIdentifier)", method: ZMTransportRequestMethod.methodPUT, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
            request.add(storeAPSSignalingKeys(client, signalingKeys: signalingKeys))

            let userClientNeedsToUpdateSignalingKeysKeySet: Set<String> = [ZMUserClientNeedsToUpdateSignalingKeysKey]
            return ZMUpstreamRequest(keys: userClientNeedsToUpdateSignalingKeysKeySet, transportRequest: request, userInfo: nil)
        }
        throw UserClientRequestError.clientNotRegistered
    }

    public func updateClientCapabilitiesRequest(_ client: UserClient, apiVersion: APIVersion) throws -> ZMUpstreamRequest? {
        guard let remoteIdentifier = client.remoteIdentifier else {
            throw UserClientRequestError.clientNotRegistered
        }
        let payload: [String: Any] = [
            "capabilities": ["legalhold-implicit-consent"]
        ]
        let request = ZMTransportRequest(path: "/clients/\(remoteIdentifier)", method: ZMTransportRequestMethod.methodPUT, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
        request.add(storeCapabilitiesHandler(client))

        let userClientNeedsToUpdateCapabilitiesKeySet: Set<String> = [ZMUserClientNeedsToUpdateCapabilitiesKey]
        return ZMUpstreamRequest(keys: userClientNeedsToUpdateCapabilitiesKeySet, transportRequest: request, userInfo: nil)
    }

    /// Password needs to be set
    public func deleteClientRequest(_ client: UserClient, credentials: ZMEmailCredentials?, apiVersion: APIVersion) -> ZMUpstreamRequest {
        let payload: [AnyHashable: Any]

        if let credentials = credentials,
            let email = credentials.email,
            let password = credentials.password {
            payload = [
                "email": email,
                "password": password
            ]
        } else {
            payload = [:]
        }

        let request =  ZMTransportRequest(path: "/clients/\(client.remoteIdentifier!)", method: ZMTransportRequestMethod.methodDELETE, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
        let userClientMarkedToDeleteKeySet: Set<String> = [ZMUserClientMarkedToDeleteKey]
        return ZMUpstreamRequest(keys: userClientMarkedToDeleteKeySet, transportRequest: request)
    }

    public func fetchClientsRequest(apiVersion: APIVersion) -> ZMTransportRequest! {
        return ZMTransportRequest(getFromPath: "/clients", apiVersion: apiVersion.rawValue)
    }

}
