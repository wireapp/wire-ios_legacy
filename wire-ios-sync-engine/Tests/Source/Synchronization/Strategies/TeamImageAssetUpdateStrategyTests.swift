//
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
import XCTest
@testable import WireSyncEngine

final class TeamImageAssetUpdateStrategyTests: MessagingTest {

    var sut: TeamImageAssetUpdateStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    let pictureAssetId = "blah"

    override func setUp() {
        super.setUp()

        self.mockApplicationStatus = MockApplicationStatus()
        self.mockApplicationStatus.mockSynchronizationState = .online

        sut = TeamImageAssetUpdateStrategy(withManagedObjectContext: uiMOC, applicationStatus: mockApplicationStatus)
    }

    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil

        super.tearDown()
    }

    private func createTeamWithImage() -> Team {
        let team = Team(context: uiMOC)
        team.pictureAssetId = pictureAssetId
        team.remoteIdentifier = UUID()
        uiMOC.saveOrRollback()

        return team
    }

    func testThatItDoesNotCreateRequestForTeamImageAsset_BeforeRequestingImage() {
        // GIVEN
        _ = createTeamWithImage()

        // THEN
        let request = sut.nextRequest(for: .v0)
        XCTAssertNil(request)
    }

    func testThatItCreatesRequestForTeamImageAsset_AfterRequestingImage() {
        // GIVEN
        let team = createTeamWithImage()

        // WHEN
        team.requestImage()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        let request = sut.nextRequest(for: .v0)
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.path, "/assets/v3/\(pictureAssetId)")
        XCTAssertEqual(request?.method, .methodGET)
    }

    func testThatItStoresTeamImageAsset_OnSuccessfulResponse() {
        // GIVEN
        let team = createTeamWithImage()
        let imageData = "image".data(using: .utf8)!

        team.requestImage()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        guard let request = sut.nextRequest(for: .v0) else { return XCTFail("nil request generated") }

        // WHEN
        request.complete(with: ZMTransportResponse(imageData: imageData, httpStatus: 200, transportSessionError: nil, headers: nil, apiVersion: APIVersion.v0.rawValue))
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(team.imageData, imageData)
    }

    func testThatItDeletesTeamAssetIdentifier_OnPermanentError() {
        // GIVEN
        let team = createTeamWithImage()
        team.requestImage()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        guard let request = sut.nextRequest(for: .v0) else { return XCTFail("nil request generated") }

        // WHEN
        request.complete(with: ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertNil(team.pictureAssetId)
    }
}
