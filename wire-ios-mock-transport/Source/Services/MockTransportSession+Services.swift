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

extension MockTransportSession {

    func fetchWhitelistedServicesForTeam(with identifier: String?, query: [String : Any], apiVersion: APIVersion) -> ZMTransportResponse? {
        var predicate: NSPredicate? = nil
        if let prefix = query["prefix"] as? String {
            predicate = NSPredicate(format: "%K beginswith[c] %@", #keyPath(MockService.name), prefix)
        }

        let services: [MockService] = MockService.fetchAll(in: managedObjectContext, withPredicate: predicate)

        let payload: [String : Any] = [
            "services" : services.map { $0.payload },
            "has_more" : false
        ]
        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
    
    @objc(processServicesProvidersRequest:)
    public func processServicesProvidersRequest(_ request: ZMTransportRequest) -> ZMTransportResponse {
        guard
            let providerId = request.RESTComponents(index: 1),
            let apiVersion = APIVersion(rawValue: request.apiVersion)
        else {
            return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil, apiVersion: request.apiVersion)
        }
        
        if let serviceId = request.RESTComponents(index: 3) {
            return self.processServiceByIdRequest(provider: providerId, service: serviceId, apiVersion: apiVersion)
        }
        else {
            return self.processProviderByIdRequest(provider: providerId, apiVersion: apiVersion)
        }
    }
    
    func processServiceByIdRequest(provider: String, service: String, apiVersion: APIVersion) -> ZMTransportResponse {
        
        let predicate = NSPredicate(format: "%K = %@ AND %K = %@",
                                    #keyPath(MockService.identifier), service,
                                    #keyPath(MockService.provider), provider)
        
        let services: [MockService] = MockService.fetchAll(in: managedObjectContext, withPredicate: predicate)
        
        if let service = services.last {
            let payload = service.payload
            return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        }
        else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        }
    }
    
    func processProviderByIdRequest(provider: String, apiVersion: APIVersion) -> ZMTransportResponse {

        let predicate = NSPredicate(format: "%K = %@",
                                    #keyPath(MockService.provider), provider)
        
        let services: [MockService] = MockService.fetchAll(in: managedObjectContext, withPredicate: predicate)
        
        if let service = services.last {
            let payload = ["id": service.provider,
                           "name": service.providerName,
                           "email": service.providerEmail,
                           "url": service.providerURL,
                           "description": service.providerDescription]
            
            return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        }
        else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        }
    }
    
    @objc(processServiceRequest:)
    public func processServiceRequest(_ request: ZMTransportRequest) -> ZMTransportResponse {
        guard let payload = request.payload as? [String: Any?],
              let serviceId = payload["service"] as? String,
              let providerId = payload["provider"] as? String,
              let conversationId = request.RESTComponents(index: 1) else {
                  return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil, apiVersion: request.apiVersion)
        }
        
        // Fetch conversation
        guard let conversation = MockConversation.existingConversation(with: conversationId, managedObjectContext: managedObjectContext) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: request.apiVersion)
        }
        
        guard let service = MockService.existingService(with: serviceId, provider: providerId, managedObjectContext: managedObjectContext) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: request.apiVersion)
        }
        
        var newServiceUser: MockUser!
        
        self.performRemoteChanges { change in
            newServiceUser = change.insertUser(withName: service.name)
            change.addV3ProfilePicture(to: newServiceUser)
            newServiceUser.accentID = Int16(service.accentID)
            newServiceUser.serviceIdentifier = service.identifier
            newServiceUser.providerIdentifier = service.provider
        }
        
        conversation.addUsers(by: selfUser, addedUsers: [newServiceUser!])
        
        let responsePayload: [String: Any?] = [
            "id": newServiceUser.identifier,
            "client": (newServiceUser.clients.anyObject() as! MockUserClient).identifier!,
            "name": newServiceUser.name!,
            "accent_id": newServiceUser.accentID,
            "assets": newServiceUser.assetData,
            "event": [
                "type": "conversation.member-join",
                "conversation": conversation.identifier,
                "from": selfUser.identifier,
                "time": Date().transportString(),
                "data": ["user_ids": [newServiceUser.identifier]]
            ],
            "service": [
                "provider": newServiceUser.providerIdentifier,
                "id": newServiceUser.serviceIdentifier
            ]
        ]
        
        return ZMTransportResponse(payload: responsePayload as ZMTransportData, httpStatus: 201, transportSessionError: nil, apiVersion: request.apiVersion)
    }
    

    @objc(processDeleteBotRequest:)
    public func processDeleteBotRequest(_ request: ZMTransportRequest) -> ZMTransportResponse {
        guard let conversationId = request.RESTComponents(index: 1),
              let botId = request.RESTComponents(index: 3) else {
                return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil, apiVersion: request.apiVersion)
        }
        
        // Fetch conversation
        guard let conversation = MockConversation.existingConversation(with: conversationId, managedObjectContext: managedObjectContext) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: request.apiVersion)
        }
        
        let predicate = NSPredicate(format: "%K == %@", #keyPath(MockConversation.identifier), botId)
        
        guard let botUser = conversation.activeUsers.filtered(using: predicate).firstObject as? MockUser else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: request.apiVersion)
        }
        
        self.performRemoteChanges { change in
            conversation.removeUsers(by: self.selfUser, removedUser: botUser)
        }
        
        return ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: request.apiVersion)
    }

    @objc(insertServiceWithName:identifier:provider:)
    public func insertService(name: String, identifier: String, provider: String) -> MockService {
        let mockService: MockService = MockService.insert(in: managedObjectContext)
        mockService.name = name
        mockService.handle = ""
        mockService.accentID = 5
        mockService.identifier = identifier
        mockService.provider = provider
        mockService.assets = Set()
        mockService.providerName = ""
        mockService.providerEmail = ""
        mockService.providerDescription = ""
        mockService.providerURL = ""
        try? managedObjectContext.save()
        return mockService
    }
}
