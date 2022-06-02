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

private let zmLog = ZMSLog(tag: "ConversationLink")

public enum SetAllowGuestsError: Error {
    case unknown
}

public enum SetAllowServicesError: Error {
    case unknown
    case invalidOperation
}

fileprivate extension ZMConversation {
    struct TransportKey {
        static let data = "data"
        static let uri = "uri"
    }
}

public enum WirelessLinkError: Error {
    case noCode
    case invalidResponse
    case invalidOperation
    case guestLinksDisabled
    case noConversation
    case unknown

    init?(response: ZMTransportResponse) {
        switch (response.httpStatus, response.payloadLabel()) {
        case (403, "invalid-op"?): self = .invalidOperation
        case (404, "no-conversation-code"?): self = .noCode
        case (404, "no-conversation"?): self = .noConversation
        case (409, "guest-links-disabled"?): self = .guestLinksDisabled
        case (400..<499, _): self = .unknown
        default: return nil
        }
    }
}

extension ZMConversation {

    /// Fetches the link to access the conversation.
    /// @param completion called when the operation is ended. Called with .success and the link fetched. If the link
    ///        was not generated yet, it is called with .success(nil).
    public func fetchWirelessLink(in userSession: ZMUserSession, _ completion: @escaping (Result<String?>) -> Void) {
        guard canManageAccess else {
            return completion(.failure(WirelessLinkError.invalidOperation))
        }

        guard let apiVersion = APIVersion.current else {
            return completion(.failure(WirelessLinkError.unknown))
        }

        let request = WirelessRequestFactory.fetchLinkRequest(for: self, apiVersion: apiVersion)
        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in
            if response.httpStatus == 200,
               let uri = response.payload?.asDictionary()?[ZMConversation.TransportKey.uri] as? String {
                completion(.success(uri))
            } else if response.httpStatus == 404 {
                completion(.success(nil))
            } else {
                let error = WirelessLinkError(response: response) ?? .unknown
                zmLog.debug("Error fetching wireless link: \(error)")
                completion(.failure(error))
            }
        })

        userSession.transportSession.enqueueOneTime(request)
    }

    var isLegacyAccessMode: Bool {
        return self.accessMode == [.invite]
    }

    /// Updates the conversation access mode if necessary and creates the link to access the conversation.
    public func updateAccessAndCreateWirelessLink(in userSession: ZMUserSession, _ completion: @escaping (Result<String>) -> Void) {
        // Legacy access mode: access and access_mode have to be updated in order to create the link.
        if isLegacyAccessMode {
            setAllowGuests(true, in: userSession) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success:
                    self.createWirelessLink(in: userSession, completion)
                }
            }
        } else {
            createWirelessLink(in: userSession, completion)
        }
    }

    func createWirelessLink(in userSession: ZMUserSession, _ completion: @escaping (Result<String>) -> Void) {
        guard canManageAccess else {
            return completion(.failure(WirelessLinkError.invalidOperation))
        }

        guard let apiVersion = APIVersion.current else {
            return completion(.failure(WirelessLinkError.unknown))
        }

        let request = WirelessRequestFactory.createLinkRequest(for: self, apiVersion: apiVersion)
        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in
            if response.httpStatus == 201,
               let payload = response.payload,
               let data = payload.asDictionary()?[ZMConversation.TransportKey.data] as? [String: Any],
               let uri = data[ZMConversation.TransportKey.uri] as? String {

                completion(.success(uri))

                if let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil) {
                    // Process `conversation.code-update` event
                    userSession.syncManagedObjectContext.performGroupedBlock {
                        userSession.updateEventProcessor?.storeAndProcessUpdateEvents([event], ignoreBuffer: true)
                    }
                }
            } else if response.httpStatus == 200,
                      let payload = response.payload?.asDictionary(),
                      let uri = payload[ZMConversation.TransportKey.uri] as? String {
                completion(.success(uri))
            } else {
                let error = WirelessLinkError(response: response) ?? .unknown
                zmLog.error("Error creating wireless link: \(error)")
                completion(.failure(error))
            }
        })

        userSession.transportSession.enqueueOneTime(request)
    }

    /// Checks if a guest link can be generated or not
    public func canGenerateGuestLink(in userSession: ZMUserSession, _ completion: @escaping (Result<Bool>) -> Void) {
        guard let apiVersion = APIVersion.current else {
            return completion(.failure(WirelessLinkError.unknown))
        }

        let request = WirelessRequestFactory.guestLinkFeatureStatusRequest(for: self, apiVersion: apiVersion)

        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in
            switch response.httpStatus {
            case 200:
                guard
                    let payload = response.payload?.asDictionary(),
                    let data = payload["status"] as? String
                else {
                    return completion(.failure(WirelessLinkError.invalidResponse))
                }

                return completion(.success(data == "enabled"))

            case 404:
                let error = WirelessLinkError(response: response) ?? .unknown
                zmLog.error("Could not check guest link status: \(error)")
                completion(.failure(error))
            default:
                completion(.failure(WirelessLinkError.unknown))
            }
        })

        userSession.transportSession.enqueueOneTime(request)

    }

    /// Deletes the existing wireless link.
    public func deleteWirelessLink(in userSession: ZMUserSession, _ completion: @escaping (VoidResult) -> Void) {
        guard canManageAccess else {
            return completion(.failure(WirelessLinkError.invalidOperation))
        }

        guard let apiVersion = APIVersion.current else {
            return completion(.failure(WirelessLinkError.unknown))
        }

        let request = WirelessRequestFactory.deleteLinkRequest(for: self, apiVersion: apiVersion)

        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in
            if response.httpStatus == 200 {
                completion(.success)
            } else {
                let error = WirelessLinkError(response: response) ?? .unknown
                zmLog.debug("Error creating wireless link: \(error)")
                completion(.failure(error))
            }
        })

        userSession.transportSession.enqueueOneTime(request)
    }

    /// Changes the conversation access mode to allow guests.
    public func setAllowGuests(_ allowGuests: Bool, in userSession: ZMUserSession, _ completion: @escaping (VoidResult) -> Void) {
        guard canManageAccess else {
            return completion(.failure(WirelessLinkError.invalidOperation))
        }

        guard let apiVersion = APIVersion.current else {
            return completion(.failure(WirelessLinkError.unknown))
        }

        setAllowGuestsAndServices(allowGuests: allowGuests, allowServices: self.allowServices, in: userSession, apiVersion: apiVersion, completion)
    }

    /// Changes the conversation access mode to allow services.
    public func setAllowServices(_ allowServices: Bool, in userSession: ZMUserSession, _ completion: @escaping (VoidResult) -> Void) {
        guard canManageAccess else {
            return completion(.failure(SetAllowServicesError.invalidOperation))
        }

        guard let apiVersion = APIVersion.current else {
            return completion(.failure(SetAllowServicesError.unknown))
        }

        setAllowGuestsAndServices(allowGuests: self.allowGuests, allowServices: allowServices, in: userSession, apiVersion: apiVersion, completion)

    }

    /// Changes the conversation access mode to allow services.
    private func setAllowGuestsAndServices(allowGuests: Bool, allowServices: Bool, in userSession: ZMUserSession, apiVersion: APIVersion, _ completion: @escaping (VoidResult) -> Void) {
        let request = WirelessRequestFactory.setAccessRoles(allowGuests: allowGuests, allowServices: allowServices, for: self, apiVersion: apiVersion)

        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in
            if let payload = response.payload,
               let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil) {
                self.allowGuests = allowGuests
                self.allowServices = allowServices
                // Process `conversation.access-update` event
                userSession.syncManagedObjectContext.performGroupedBlock {
                    userSession.updateEventProcessor?.storeAndProcessUpdateEvents([event], ignoreBuffer: true)
                }
                completion(.success)
            } else {
                zmLog.debug("Error setting access role:  \(response)")
                completion(.failure(SetAllowServicesError.unknown))
            }
        })

        userSession.transportSession.enqueueOneTime(request)
    }

    public var canManageAccess: Bool {
        guard let moc = self.managedObjectContext else { return false }
        let selfUser = ZMUser.selfUser(in: moc)
        return selfUser.canModifyAccessControlSettings(in: self)
    }
}

internal struct WirelessRequestFactory {
    static func fetchLinkRequest(for conversation: ZMConversation, apiVersion: APIVersion) -> ZMTransportRequest {
        guard let identifier = conversation.remoteIdentifier?.transportString() else {
            fatal("conversation is not yet inserted on the backend")
        }
        return .init(getFromPath: "/conversations/\(identifier)/code", apiVersion: apiVersion.rawValue)
    }

    static func guestLinkFeatureStatusRequest(for conversation: ZMConversation, apiVersion: APIVersion) -> ZMTransportRequest {
        guard let identifier = conversation.remoteIdentifier?.transportString() else {
            fatal("conversation is not yet inserted on the backend")
        }
        return .init(getFromPath: "/conversations/\(identifier)/features/conversationGuestLinks", apiVersion: apiVersion.rawValue)
    }

    static func createLinkRequest(for conversation: ZMConversation, apiVersion: APIVersion) -> ZMTransportRequest {
        guard let identifier = conversation.remoteIdentifier?.transportString() else {
            fatal("conversation is not yet inserted on the backend")
        }
        return .init(path: "/conversations/\(identifier)/code", method: .methodPOST, payload: nil, apiVersion: apiVersion.rawValue)
    }

    static func deleteLinkRequest(for conversation: ZMConversation, apiVersion: APIVersion) -> ZMTransportRequest {
        guard let identifier = conversation.remoteIdentifier?.transportString() else {
            fatal("conversation is not yet inserted on the backend")
        }
        return .init(path: "/conversations/\(identifier)/code", method: .methodDELETE, payload: nil, apiVersion: apiVersion.rawValue)
    }

        static func setAccessRoles(allowGuests: Bool, allowServices: Bool, for conversation: ZMConversation, apiVersion: APIVersion) -> ZMTransportRequest {
        guard let identifier = conversation.remoteIdentifier?.transportString() else {
            fatal("conversation is not yet inserted on the backend")
        }

        var accessRoles = conversation.accessRoles

        if allowServices {
            accessRoles.insert(.service)
        } else {
            accessRoles.remove(.service)
        }

        if allowGuests {
            accessRoles.insert(.guest)
            accessRoles.insert(.nonTeamMember)
        } else {
            accessRoles.remove(.guest)
            accessRoles.remove(.nonTeamMember)
        }

        let payload = [
            "access": ConversationAccessMode.value(forAllowGuests: allowGuests).stringValue as Any,
            "access_role": ConversationAccessRole.fromAccessRoleV2(accessRoles).rawValue,
            "access_role_v2": accessRoles.map(\.rawValue)
        ]

        return .init(path: "/conversations/\(identifier)/access", method: .methodPUT, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
    }

}
