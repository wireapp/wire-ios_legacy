//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import XCTest
@testable import Wire

class TeamMetadataRefresherTests: XCTestCase {

    private var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()
        SelfUser.provider = self
        mockSelfUser = .createSelfUser(name: "Alice", inTeam: UUID())
    }

    override func tearDown() {
        SelfUser.provider = nil
        mockSelfUser = nil
    }

    func test_it_does_not_crash_if_no_self_user() throws {
        // Given
        let sut = TeamMetadataRefresher()
        SelfUser.provider = nil

        // When
        sut.triggerRefreshIfNeeded()

        // Then nothing
    }

    func test_it_refreshes_for_a_team_member() {
        // Given
        let sut = TeamMetadataRefresher()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 0)

        // When
        sut.triggerRefreshIfNeeded()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 1)
    }

    func test_it_does_not_refresh_for_non_team_member() {
        // Given
        let sut = TeamMetadataRefresher()
        mockSelfUser.teamIdentifier = nil

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 0)

        // When
        sut.triggerRefreshIfNeeded()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 0)
    }

    func test_it_refreshes_if_timeout_expired() {
        // Given
        let sut = TeamMetadataRefresher(refreshInterval: 0.5)

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 0)

        // When
        sut.triggerRefreshIfNeeded()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 1)

        // When
        let triggeredSecondRefresh = expectation(description: "triggered second refresh")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            sut.triggerRefreshIfNeeded()
            triggeredSecondRefresh.fulfill()
        }

        wait(for: [triggeredSecondRefresh], timeout: 2)

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 2)
    }

    func test_it_does_not_refresh_if_timeout_not_expired() {
        // Given
        let sut = TeamMetadataRefresher(refreshInterval: .oneMinute)

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 0)

        // When
        sut.triggerRefreshIfNeeded()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 1)

        // When
        sut.triggerRefreshIfNeeded()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 1)
    }

}

// MARK: - Self User Provider

extension TeamMetadataRefresherTests: SelfUserProvider {

    public var selfUser: UserType & ZMEditableUser {
        return mockSelfUser
    }

}
