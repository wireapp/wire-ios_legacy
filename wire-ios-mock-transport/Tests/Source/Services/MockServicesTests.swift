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
@testable import WireMockTransport

class MockServicesTests: MockTransportSessionTests {
    func testThatInsertedServiceCanBeQueried() {
        // given
        let teamID = UUID()
        let service1 = sut.insertService(name: "Normal Service", identifier: UUID().transportString(), provider: UUID().transportString())
        let _ = sut.insertService(name: "Other Service", identifier: UUID().transportString(), provider: UUID().transportString())

        // when

        let response = sut.processTeamsRequest(ZMTransportRequest(path: "/teams/\(teamID.transportString())/services/whitelisted?prefix=Normal", method: .methodGET, payload: nil, apiVersion: APIVersion.v0.rawValue))
        // then
        XCTAssertEqual(response.httpStatus, 200)
        XCTAssertNotNil(response.payload?.asDictionary()?["services"])
        let services: [[String: AnyHashable]] = response.payload!.asDictionary()!["services"] as! [[String: AnyHashable]]
        XCTAssertEqual(services.count, 1)
        XCTAssertEqual(services[0]["name"], "Normal Service")
        XCTAssertEqual(services[0]["accent_id"], 5)
        XCTAssertEqual(services[0]["id"], service1.identifier)
        XCTAssertEqual(services[0]["provider"], service1.provider)
    }

    func testThatServiceUserDataHasServiceKVPs() {
        // given
        let serviceUser = sut.insertSelfUser(withName: "Mock Service")
        serviceUser.serviceIdentifier = "mock serviceIdentifier"
        serviceUser.providerIdentifier = "mock providerIdentifier"

        // when
        let data = serviceUser.data

        /// then
        if let service: [String: String] = data["service"] as? [String: String] {
            XCTAssertEqual(service["provider"], serviceUser.providerIdentifier)
            XCTAssertEqual(service["id"], serviceUser.serviceIdentifier)
        } else {
            XCTFail("service is nil!")
        }
    }

    func testThatItUserDataHasNotServiceKVPs() {
        // given
        let mackUser = sut.insertSelfUser(withName: "Mock User")

        // when
        let data: [String: Any?] = mackUser.data

        /// then
        if let _ = data["service"] {
            XCTFail("service should be nil!")
        }
    }

    func testThatItCanAddServiceToTheConversation() {
        // given
        let _ = sut.insertSelfUser(withName: "Antonio")
        let service = sut.insertService(name: "Normal Service", identifier: UUID().transportString(), provider: UUID().transportString())

        let conversation = sut.insertConversation(withCreator: sut.selfUser, otherUsers: [], type: .group)

        XCTAssertEqual(conversation.activeUsers.count, 1)
        // when
        let payload = ["service": service.identifier,
                       "provider": service.provider]
        let response = sut.processServiceRequest(ZMTransportRequest(path: "/conversations/\(conversation.identifier)/bots", method: .methodPOST, payload: payload as ZMTransportData, apiVersion: APIVersion.v0.rawValue))

        // then
        XCTAssertEqual(response.httpStatus, 201)
        XCTAssertNotNil(response.payload?.asDictionary())
        XCTAssertEqual(conversation.activeUsers.count, 2)

        let conversationUser = conversation.activeUsers.firstObject as! MockUser
        XCTAssertNil(conversationUser.serviceIdentifier)
        XCTAssertNil(conversationUser.providerIdentifier)

        let serviceUser = conversation.activeUsers.lastObject as! MockUser

        XCTAssertEqual(serviceUser.serviceIdentifier, service.identifier)
        XCTAssertEqual(serviceUser.providerIdentifier, service.provider)
    }
    
    func testThatItCanFetchServiceById() {
        // given
        let serviceId = UUID().transportString()
        let providerId = UUID().transportString()
        let _ = sut.insertService(name: "Normal Service",
                                  identifier: serviceId,
                                  provider: providerId)
        // when
        let request = ZMTransportRequest(getFromPath: "/providers/\(providerId)/services/\(serviceId)", apiVersion: APIVersion.v0.rawValue)
        let response = sut.processServicesProvidersRequest(request)
        
        // then
        XCTAssertEqual(response.httpStatus, 200)
        XCTAssertNotNil(response.payload)
        let payload = response.payload as! [String: AnyHashable]
        XCTAssertEqual(payload["name"], "Normal Service")
        XCTAssertEqual(payload["id"], serviceId)
        XCTAssertEqual(payload["provider"], providerId)
    }
    
    func testThatItCanFetchProviderById() {
        // given
        let serviceId = UUID().transportString()
        let providerId = UUID().transportString()
        let service = sut.insertService(name: "Normal Service",
                                  identifier: serviceId,
                                  provider: providerId)
        
        service.providerName = "Provider"
        service.providerEmail = "provider@provider.org"
        service.providerDescription = "Testing Provider Description"
        service.providerURL = "http://provider.org"
        // when
        let request = ZMTransportRequest(getFromPath: "/providers/\(providerId)", apiVersion: APIVersion.v0.rawValue)
        let response = sut.processServicesProvidersRequest(request)
        
        // then
        XCTAssertEqual(response.httpStatus, 200)
        XCTAssertNotNil(response.payload)
        let payload = response.payload as! [String: AnyHashable]
        XCTAssertEqual(payload["name"], "Provider")
        XCTAssertEqual(payload["id"], providerId)
        XCTAssertEqual(payload["email"], "provider@provider.org")
    }
    
    func testThatItCanDeleteBotFromConversation() {
        // given
        let _ = sut.insertSelfUser(withName: "Antonio")
        let service = sut.insertService(name: "Normal Service", identifier: UUID().transportString(), provider: UUID().transportString())
        let conversation = sut.insertConversation(withCreator: sut.selfUser, otherUsers: [], type: .group)
        
        XCTAssertEqual(conversation.activeUsers.count, 1)
        let payload = ["service": service.identifier,
                       "provider": service.provider]
        let _ = sut.processServiceRequest(ZMTransportRequest(path: "/conversations/\(conversation.identifier)/bots", method: .methodPOST, payload: payload as ZMTransportData, apiVersion: APIVersion.v0.rawValue))
        
        let predicate = NSPredicate(format: "%K == %@", #keyPath(MockUser.serviceIdentifier), service.identifier)
        
        guard let botUser = conversation.activeUsers.filtered(using: predicate).firstObject as? MockUser else {
            XCTFail("User is not created")
            return
        }
        
        // when
        let request = ZMTransportRequest(path: "/conversations/\(conversation.identifier)/bots/\(botUser.identifier)", method: .methodDELETE, payload: nil, apiVersion: APIVersion.v0.rawValue)
        let response = sut.processDeleteBotRequest(request)
        
        // then
        XCTAssertEqual(response.httpStatus, 200)
        XCTAssertEqual(conversation.activeUsers.count, 1)
    }
}
