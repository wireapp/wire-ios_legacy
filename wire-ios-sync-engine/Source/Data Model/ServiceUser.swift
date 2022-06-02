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

private let zmLog = ZMSLog(tag: "Services")

public struct ServiceUserData: Equatable {
    let provider: UUID
    let service: UUID

    public init(provider: UUID, service: UUID) {
        self.provider = provider
        self.service = service
    }
}

extension ServiceUser {
    var serviceUserData: ServiceUserData? {
        guard let providerIdentifier = self.providerIdentifier,
              let serviceIdentifier = self.serviceIdentifier,
              let provider = UUID(uuidString: providerIdentifier),
              let service = UUID(uuidString: serviceIdentifier)
        else {
            return nil
        }

        return ServiceUserData(provider: provider,
                               service: service)
    }
}

public final class ServiceProvider: NSObject {
    public let identifier: String

    public let name: String
    public let email: String
    public let url: String
    public let providerDescription: String

    init?(payload: [AnyHashable: Any]) {
        guard let identifier  = payload["id"] as? String,
              let name        = payload["name"] as? String,
              let email       = payload["email"] as? String,
              let url         = payload["url"] as? String,
              let description = payload["description"] as? String
        else {
            return nil
        }
        self.identifier  = identifier
        self.name        = name
        self.email       = email
        self.url         = url
        self.providerDescription = description

        super.init()
    }
}

public final class ServiceDetails: NSObject {
    public let serviceIdentifier: String
    public let providerIdentifier: String

    public let name: String
    public let serviceDescription: String
    public let assets: [[String: Any]]
    public let tags: [String]

    init?(payload: [AnyHashable: Any]) {
        guard let serviceIdentifier   = payload["id"] as? String,
              let providerIdentifier  = payload["provider"] as? String,
              let name                = payload["name"] as? String,
              let description         = payload["description"] as? String,
              let assets              = payload["assets"] as? [[String: Any]],
              let tags                = payload["tags"] as? [String]
        else {
            return nil
        }

        self.serviceIdentifier  = serviceIdentifier
        self.providerIdentifier = providerIdentifier
        self.name               = name
        self.serviceDescription = description
        self.assets             = assets
        self.tags               = tags

        super.init()
    }
}

public extension ServiceUserData {
    fileprivate func requestToAddService(to conversation: ZMConversation, apiVersion: APIVersion) -> ZMTransportRequest {
        guard let remoteIdentifier = conversation.remoteIdentifier
        else {
            fatal("conversation is not synced with the backend")
        }

        let path = "/conversations/\(remoteIdentifier.transportString())/bots"

        let payload: NSDictionary = ["provider": self.provider.transportString(),
                                     "service": self.service.transportString(),
                                     "locale": NSLocale.formattedLocaleIdentifier()!]

        return ZMTransportRequest(path: path, method: .methodPOST, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
    }

    fileprivate func requestToFetchProvider(apiVersion: APIVersion) -> ZMTransportRequest {
        let path = "/providers/\(provider.transportString())/"
        return ZMTransportRequest(path: path, method: .methodGET, payload: nil, apiVersion: apiVersion.rawValue)
    }

    fileprivate func requestToFetchDetails(apiVersion: APIVersion) -> ZMTransportRequest {
        let path = "/providers/\(provider.transportString())/services/\(service.transportString())"
        return ZMTransportRequest(path: path, method: .methodGET, payload: nil, apiVersion: apiVersion.rawValue)
    }
}

public extension ServiceUser {

    func fetchProvider(in userSession: ZMUserSession, completion: @escaping (ServiceProvider?) -> Void) {
        guard let serviceUserData = self.serviceUserData else {
            fatal("Not a service user")
        }

        guard let apiVersion = APIVersion.current else {
            return completion(nil)
        }

        let request = serviceUserData.requestToFetchProvider(apiVersion: apiVersion)

        request.add(ZMCompletionHandler(on: userSession.managedObjectContext, block: { (response) in

            guard response.httpStatus == 200,
                  let responseDictionary = response.payload?.asDictionary(),
                  let provider = ServiceProvider(payload: responseDictionary) else {
                      zmLog.error("Wrong response for fetching a provider: \(response)")
                      completion(nil)
                      return
                  }

            completion(provider)
        }))

        userSession.transportSession.enqueueOneTime(request)
    }

    func fetchDetails(in userSession: ZMUserSession, completion: @escaping (ServiceDetails?) -> Void) {
        guard let serviceUserData = self.serviceUserData else {
            fatal("Not a service user")
        }

        guard let apiVersion = APIVersion.current else {
            return completion(nil)
        }

        let request = serviceUserData.requestToFetchDetails(apiVersion: apiVersion)

        request.add(ZMCompletionHandler(on: userSession.managedObjectContext, block: { (response) in

            guard response.httpStatus == 200,
                  let responseDictionary = response.payload?.asDictionary(),
                  let serviceDetails = ServiceDetails(payload: responseDictionary) else {
                      zmLog.error("Wrong response for fetching a service: \(response)")
                      completion(nil)
                      return
                  }

            completion(serviceDetails)
        }))

        userSession.transportSession.enqueueOneTime(request)
    }

    func createConversation(in userSession: ZMUserSession, completionHandler: @escaping (Result<ZMConversation>) -> Void) {

        createConversation(transportSession: userSession.transportSession,
                           eventProcessor: userSession.updateEventProcessor!,
                           contextProvider: userSession,
                           completionHandler: completionHandler)
    }

    internal func createConversation(transportSession: TransportSessionType,
                                     eventProcessor: UpdateEventProcessor,
                                     contextProvider: ContextProvider,
                                     completionHandler: @escaping (Result<ZMConversation>) -> Void) {

        guard transportSession.reachability.mayBeReachable else {
            completionHandler(.failure(AddBotError.offline))
            return
        }

        guard let serviceUserData = serviceUserData else {
            completionHandler(.failure(AddBotError.general))
            return
        }

        let selfUser = ZMUser.selfUser(in: contextProvider.viewContext)
        let conversation = ZMConversation.insertNewObject(in: contextProvider.viewContext)

        conversation.lastModifiedDate = Date()
        conversation.conversationType = .group
        conversation.creator = selfUser
        conversation.team = selfUser.team
        conversation.allowServices = true

        var onCreatedRemotelyToken: NSObjectProtocol?
        _ = onCreatedRemotelyToken // remove warning

        onCreatedRemotelyToken = conversation.onCreatedRemotely { [weak contextProvider] in
            guard let contextProvider = contextProvider else {
                completionHandler(.failure(AddBotError.general))
                return
            }

            conversation.add(serviceUser: serviceUserData,
                             transportSession: transportSession,
                             eventProcessor: eventProcessor,
                             contextProvider: contextProvider,
                             completionHandler: { (result) in
                switch result {
                case .success:
                    completionHandler(.success(conversation))
                case .failure(let error):
                    completionHandler(.failure(error))
                }

                onCreatedRemotelyToken = nil
            })
        }

        contextProvider.viewContext.saveOrRollback()
    }
}

public enum AddBotError: Int, Error {
    case offline
    case general
    /// In case the conversation is already full, the backend is going to refuse to add the bot to the conversation.
    case tooManyParticipants
    /// The bot service is not responding to wire backend.
    case botNotResponding
    /// The bot rejected to be added to the conversation.
    case botRejected
    case missingAPIVersion
}

public enum AddBotResult {
    case success(conversation: ZMConversation)
    case failure(error: AddBotError)
}

extension AddBotError {
    init(response: ZMTransportResponse) {
        switch response.httpStatus {
        case 403:
            self = .tooManyParticipants
        case 419:
            self = .botRejected
        case 502:
            self = .botNotResponding
        default:
            self = .general
        }
    }
}

public extension ZMConversation {

    func add(serviceUser: ServiceUser, in userSession: ZMUserSession, completionHandler: @escaping (VoidResult) -> Void) {
        guard let serviceUserData = serviceUser.serviceUserData else {
            fatal("Not a service user")
        }

        add(serviceUser: serviceUserData, in: userSession, completionHandler: completionHandler)
    }

    func add(serviceUser serviceUserData: ServiceUserData, in userSession: ZMUserSession, completionHandler: @escaping (VoidResult) -> Void) {
        add(serviceUser: serviceUserData,
            transportSession: userSession.transportSession,
            eventProcessor: userSession.updateEventProcessor!,
            contextProvider: userSession.coreDataStack,
            completionHandler: completionHandler)
    }

    internal func add(serviceUser serviceUserData: ServiceUserData,
                      transportSession: TransportSessionType,
                      eventProcessor: UpdateEventProcessor,
                      contextProvider: ContextProvider,
                      completionHandler: @escaping (VoidResult) -> Void) {

        guard transportSession.reachability.mayBeReachable else {
            completionHandler(.failure(AddBotError.offline))
            return
        }

        guard let apiVersion = APIVersion.current else {
            return completionHandler(.failure(AddBotError.missingAPIVersion))
        }

        let request = serviceUserData.requestToAddService(to: self, apiVersion: apiVersion)

        request.add(ZMCompletionHandler(on: contextProvider.viewContext, block: { [weak contextProvider] (response) in

            guard response.httpStatus == 201,
                  let responseDictionary = response.payload?.asDictionary(),
                  let userAddEventPayload = responseDictionary["event"] as? ZMTransportData,
                  let event = ZMUpdateEvent(fromEventStreamPayload: userAddEventPayload, uuid: nil) else {
                      completionHandler(.failure(AddBotError(response: response)))
                      return
                  }

            completionHandler(.success)

            contextProvider?.syncContext.performGroupedBlock {
                eventProcessor.storeAndProcessUpdateEvents([event], ignoreBuffer: true)
            }
        }))

        transportSession.enqueueOneTime(request)
    }
}
