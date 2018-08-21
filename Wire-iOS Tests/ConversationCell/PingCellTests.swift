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

import XCTest
@testable import Wire

final class PingCellTests: ZMSnapshotTestCase {

    var sut: PingCell!

    override func setUp() {

        super.setUp()

        sut = PingCell()

        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false

        sut.prepareForReuse()
        sut.bounds = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 9999)
        sut.contentView.bounds = CGRect(x: 0.0, y: 0.0, width: 320, height: 9999)
        sut.layoutMargins = UIView.directionAwareConversationLayoutMargins

        sut.configure(for: MockMessageFactory.pingMessage(), layoutProperties: layoutProperties)

        recordMode = true
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func test() {
        verify(view: sut.tableViewForSnapshot())
    }
}

