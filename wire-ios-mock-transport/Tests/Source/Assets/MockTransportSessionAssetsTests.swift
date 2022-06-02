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

class MockTransportSessionAssetsTests : MockTransportSessionTests {
    
    func testThatInsertingAnAssetCreatesOne() {
        // given
        let id = UUID.create()
        let token = UUID.create()
        let data = self.verySmallJPEGData()
        let contentType = "application/octet-stream"
        let domain = UUID.create().transportString()
        
        // when
        var asset: MockAsset?
        sut.performRemoteChanges { session in
            asset = session.insertAsset(with: id, domain: domain, assetToken: token, assetData: data, contentType: contentType)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(asset?.identifier, id.transportString())
        XCTAssertEqual(asset?.token, token.transportString())
        XCTAssertEqual(asset?.data, data)
        XCTAssertEqual(asset?.contentType, contentType)
        XCTAssertEqual(asset?.domain, domain)
    }
    
    func testUploadingAssetRequestV3() {
        // given
        let data = self.verySmallJPEGData()
        
        // when
        let response = self.response(forAssetData: data, contentType: "application/octet-stream", path: "/assets/v3", apiVersion: .v0)
        XCTAssertNotNil(response)
        
        // then
        let payload = response?.payload?.asDictionary()
        let key = payload?["key"] as? String
        let token = payload?["token"] as? String
        XCTAssertNotNil(key)
        XCTAssertNotNil(token)
    
        let asset = MockAsset(in: sut.managedObjectContext, forID: key!)
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.token, token)
    }
    
    func testDownloadingNonexistingAssetRequestV3() {
        // when
        let response = self.response(forPayload: nil, path: "/assets/v3/12345", method: .methodGET, apiVersion: .v0)
        
        // then
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 404)
    }
    
    func testDownloadingExistingAssetRequestV3() {
        // given
        let data = self.verySmallJPEGData()
        let contentType = "application/octet-stream"
        var asset: MockAsset?
        sut.performRemoteChanges { session in
            asset = session.insertAsset(with: NSUUID.create(), assetToken: NSUUID.create(), assetData: data, contentType: contentType)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(asset)

        // when
        let response = self.response(forPayload: nil, path: "/assets/v3/\(asset!.identifier)", method: .methodGET, apiVersion: .v0)
        
        // then
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.rawData, data)
    }
    
    func testDeletingNonexistingAssetRequestV3() {
        // when
        let response = self.response(forPayload: nil, path: "/assets/v3/12345", method: .methodDELETE, apiVersion: .v0)
        
        // then
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 404)
    }
    
    func testDeletingExistingAssetRequestV3() {
        // given
        let contentType = "application/octet-stream"
        var asset: MockAsset?
        sut.performRemoteChanges { session in
            asset = session.insertAsset(with: NSUUID.create(), assetToken: NSUUID.create(), assetData: "data".data(using: .utf8)!, contentType: contentType)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(asset)
        
        // when
        let response = self.response(forPayload: nil, path: "/assets/v3/\(asset!.identifier)", method: .methodDELETE, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 200)

        // then
        XCTAssertNil(MockAsset(in: sut.managedObjectContext, forID: asset!.identifier))
    }

    func testUploadingAssetRequestV4() {
        // given
        let data = self.verySmallJPEGData()

        // when
        let domain = UUID.create().transportString()
        let response = self.response(forAssetData: data, contentType: "application/octet-stream", path: "/assets/v4/\(domain)", apiVersion: .v0)
        XCTAssertNotNil(response)

        // then
        let payload = response?.payload?.asDictionary()
        let key = payload?["key"] as? String
        let responseDomain = payload?["domain"] as? String
        let token = payload?["token"] as? String
        XCTAssertNotNil(key)
        XCTAssertNotNil(payload)

        let asset = MockAsset(in: sut.managedObjectContext, forID: key!, domain: responseDomain!)
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.token, token)
    }

    func testDownloadingNonexistingAssetRequestV4() {
        // when
        let key = UUID.create().transportString()
        let domain = UUID.create().transportString()
        let response = self.response(forPayload: nil, path: "/assets/v4/\(domain)/\(key)", method: .methodGET, apiVersion: .v0)

        // then
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 404)
    }

    func testDownloadingExistingAssetRequestV4() {
        // given
        let data = self.verySmallJPEGData()
        let contentType = "application/octet-stream"
        var asset: MockAsset?
        sut.performRemoteChanges { session in
            asset = session.insertAsset(with: NSUUID.create(), domain: UUID.create().transportString(), assetToken: NSUUID.create(), assetData: data, contentType: contentType)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(asset)

        // when
        let response = self.response(forPayload: nil, path: "/assets/v4/\(asset!.domain!)/\(asset!.identifier)", method: .methodGET, apiVersion: .v0)

        // then
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.rawData, data)
    }

    func testDeletingNonexistingAssetRequestV4() {
        // when
        let key = UUID.create().transportString()
        let domain = UUID.create().transportString()
        let response = self.response(forPayload: nil, path: "/assets/v4/\(domain)/\(key)", method: .methodDELETE, apiVersion: .v0)

        // then
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 404)
    }

    func testDeletingExistingAssetRequestV4() {
        // given
        let contentType = "application/octet-stream"
        var asset: MockAsset?
        sut.performRemoteChanges { session in
            asset = session.insertAsset(with: NSUUID.create(), domain: UUID.create().transportString(), assetToken: NSUUID.create(), assetData: "data".data(using: .utf8)!, contentType: contentType)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(asset)

        // when
        let response = self.response(forPayload: nil, path: "/assets/v4/\(asset!.domain!)/\(asset!.identifier)", method: .methodDELETE, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 200)

        // then
        XCTAssertNil(MockAsset(in: sut.managedObjectContext, forID: asset!.identifier))
    }
}
