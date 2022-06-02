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
@testable import WireDataModel

class LabelTests: ZMBaseManagedObjectTest {

    func testThatFetchOrCreateFavoriteLabel_ReturnsLabelOfKindFavorite() {
        // given
        let favoriteLabel = Label.fetchOrCreateFavoriteLabel(in: uiMOC, create: true)

        // then
        XCTAssertEqual(favoriteLabel.kind, .favorite)
    }

    func testThatFetchOrCreateFavoriteLabel_ReturnsTheSameObject_WhenCalledTwice() {
        // given
        let favoriteLabel = Label.fetchOrCreateFavoriteLabel(in: uiMOC, create: true)

        // then
        XCTAssertEqual(Label.fetchOrCreateFavoriteLabel(in: uiMOC, create: true), favoriteLabel)
    }

    func testThatFetchOrCreate_ReturnsANewLabel_WhenCreateIsTrue() {
        // given
        var created = false

        // when
        let label = Label.fetchOrCreate(remoteIdentifier: UUID(), create: true, in: uiMOC, created: &created)

        // then
        XCTAssertTrue(created)
        XCTAssertNotNil(label)
    }

    func testThatFetchOrCreate_ReturnsNil_WhenCreateIsFalse() {
        // given
        var created = false

        // when
        let label = Label.fetchOrCreate(remoteIdentifier: UUID(), create: false, in: uiMOC, created: &created)

        // then
        XCTAssertFalse(created)
        XCTAssertNil(label)
    }

    func testThatFetchOrCreate_FetchesAnExistingLabel() {
        // given
        var created = false
        let label = Label.fetchOrCreate(remoteIdentifier: UUID(), create: true, in: uiMOC, created: &created)

        // when
        let fetchedLabel = Label.fetchOrCreate(remoteIdentifier: label!.remoteIdentifier!, create: false, in: uiMOC, created: &created)

        // then
        XCTAssertFalse(created)
        XCTAssertEqual(label, fetchedLabel)
    }

}
