////
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class MockTransportSessionUsersTests_Swift: MockTransportSessionTests {
    
    private func assertDictionaryHasKeys(a1: NSDictionary, a2: NSArray) {
        let _k1: NSArray = (a1.allKeys as NSArray).sortedArray(using: NSSelectorFromString("compare:")) as NSArray
        let _k2: NSArray = a2.sortedArray(using: NSSelectorFromString("compare:")) as NSArray
        if _k1 != _k2 {
            let expectedKeys = (_k2 as? [String])?.joined(separator: "\", \"") ?? ""
            let actualKeys = String(describing: (_k1 as? [String])?.joined(separator: "\", \""))
            XCTFail("'\(a1)' should have keys \"\(expectedKeys)\", has \"\(actualKeys)\"")
        }
    }
    
    func testThatItReturnsUserClientsKeys() {
        var selfUser: MockUser!
        var otherUser: MockUser!
        var thirdUser: MockUser!
        var selfClient: MockUserClient!
        var otherUserClient: MockUserClient!
        var secondOtherUserClient: MockUserClient!
        
        sut.performRemoteChanges({ session in
            selfUser = session.insertSelfUser(withName: "foo")
            otherUser = session.insertUser(withName: "bar")
            thirdUser = session.insertUser(withName: "foobar")
            selfClient = session.registerClient(for: selfUser!, label: "self1", type: "permanent", deviceClass: "phone")
            otherUserClient = session.registerClient(for: otherUser!, label: "other1", type: "permanent", deviceClass: "phone")
            secondOtherUserClient = session.registerClient(for: otherUser!, label: "other2", type: "permanent", deviceClass: "phone")
        })
        
        let redunduntClientId = NSString.createAlphanumerical() as String
        let payload: ZMTransportData = [
            selfUser.identifier: [selfClient.identifier!, redunduntClientId],
            otherUser.identifier: [otherUserClient.identifier!, secondOtherUserClient.identifier!],
            thirdUser.identifier: [redunduntClientId]] as ZMTransportData
        
        let response: ZMTransportResponse = self.response(forPayload: payload, path: "/users/prekeys", method: .methodPOST, apiVersion: .v0)
        XCTAssertEqual(response.httpStatus, 200)
        
        let expectedUsers: NSArray = [selfUser.identifier, otherUser.identifier, thirdUser.identifier]
        
        let dict = response.payload!.asDictionary()! as NSDictionary
        assertDictionaryHasKeys(a1: dict, a2: expectedUsers)

        if let identifier = selfUser?.identifier {
            let expectedClients = [selfClient.identifier!, redunduntClientId]
            assertDictionaryHasKeys(a1: response.payload?.asDictionary()?[identifier] as! NSDictionary, a2: expectedClients as NSArray)
        }

        if let identifier = otherUser?.identifier {
            let expectedClients = [otherUserClient?.identifier, secondOtherUserClient?.identifier]
            assertDictionaryHasKeys(a1: response.payload?.asDictionary()?[identifier] as! NSDictionary, a2: expectedClients as NSArray)
        }

        if let identifier = thirdUser?.identifier {
            let expectedClients = [redunduntClientId]
            assertDictionaryHasKeys(a1: response.payload?.asDictionary()?[identifier] as! NSDictionary, a2: expectedClients as NSArray)
        }
    }
    
    func testThatItReturnsRichInfo_404_whenUserDoesNotExist() {
        //given
        let userId = "1234"
        
        // when
        let response = self.response(forPayload: nil, path: "/users/\(userId)/rich-info", method: .methodGET, apiVersion: .v0)
        
        // then
        XCTAssertEqual(response?.httpStatus, 404)
    }
    
    func testThatItReturnsRichInfo_EmptyWhenUserDoesNotHaveAny() {
        //given
        let userId = "123456"
        sut.performRemoteChanges {
            let user = $0.insertUser(withName: "some")
            user.identifier = userId
        }
        
        // when
        guard let response = self.response(forPayload: nil, path: "/users/\(userId)/rich-info", method: .methodGET, apiVersion: .v0) else { XCTFail(); return }
        
        // then
        XCTAssertEqual(response.httpStatus, 200)
        XCTAssertEqual(response.payload as? NSDictionary, ["fields" : [] ])
    }
    
    func testThatItReturnsRichInfo_WhenUserHasIt() {
        //given
        let userId = "123456"
        let richProfile = [
            (type: "Department", value: "Sales & Marketing"),
            (type: "Favorite color", value: "Blue")
        ]
        sut.performRemoteChanges {
            let user = $0.insertUser(withName: "some")
            user.identifier = userId
            for field in richProfile {
                user.appendRichInfo(type: field.type, value: field.value)
            }
        }
        
        // when
        guard let response = self.response(forPayload: nil, path: "/users/\(userId)/rich-info", method: .methodGET, apiVersion: .v0) else { XCTFail(); return }
        
        // then
        XCTAssertEqual(response.httpStatus, 200)
        guard let payload = response.payload as? [String : [[String : String]]] else { XCTFail("Malformed response: \(String(describing: response.payload))"); return }
        
        guard let fields = payload["fields"] else { XCTFail("Malformed payload: \(payload)"); return }
        
        let values = richProfile.map { ["type" : $0.type, "value" : $0.value] }
        XCTAssertEqual(fields, values)
    }
    
    func testThatItReturnsRichInfo_403_WhenUserIsNotPartOfSameTeam() {
        //given
        let userId = "123456"
        let richProfile = [
            (type: "Department", value: "Sales & Marketing"),
            (type: "Favorite color", value: "Blue")
        ]
        sut.performRemoteChanges {
            let selfUser = $0.insertSelfUser(withName: "I am")
            _ = $0.insertTeam(withName: "Mine", isBound: true, users: [selfUser])
            let user = $0.insertUser(withName: "some")
            _ = $0.insertTeam(withName: "Other", isBound: false, users:[user])
            user.identifier = userId
            for field in richProfile {
                user.appendRichInfo(type: field.type, value: field.value)
            }
        }
        
        // when
        guard let response = self.response(forPayload: nil, path: "/users/\(userId)/rich-info", method: .methodGET, apiVersion: .v0) else { XCTFail(); return }
        
        // then
        XCTAssertEqual(response.httpStatus, 403)
    }
    
}
