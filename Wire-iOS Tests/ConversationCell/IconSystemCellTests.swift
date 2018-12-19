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

final class IconSystemCellTests: ZMSnapshotTestCase {

    override func setUp() {
        super.setUp()
        ColorScheme.default.variant = .light
        snapshotBackgroundColor = .white
    }

    class func wrappedCell(for type: ZMSystemMessageType,
                           users usersCount: Int,
                           clients clientsCount: Int,
                           config: ((MockMessage) -> ())?) -> UITableView? {

        let factoryTableView = UITableView()
        let systemMessage = MockMessageFactory.systemMessage(with: type, users: usersCount, clients: clientsCount)
        config?(systemMessage!)

        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = false
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false

        let cellDescription = ConversationSystemMessageCellDescription.cells(for: systemMessage!, layoutProperties: layoutProperties).first!
        cellDescription.register(in: factoryTableView)

        let cell = cellDescription.makeCell(for: factoryTableView, at: IndexPath())
        cell.layoutIfNeeded()

        let size = cell.systemLayoutSizeFitting(CGSize(width: 320.0, height: 0.0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        cell.bounds = CGRect(origin: .zero, size: size)
        return cell.wrapInTableView()
    }

    func testIgnoredClient_oneUser_oneClient() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .ignoredClient, users: 1, clients: 1, config: nil)
        verify(view: wrappedCell!)
    }

    func testIgnoredClient_selfUser_oneClient() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .ignoredClient, users: 1, clients: 1, config: { message in
            let mockMessageData = message.systemMessageData as? MockSystemMessageData
            mockMessageData?.users = Set<AnyHashable>([MockUser.mockSelf()]) as! Set<ZMUser>
        })
        verify(view: wrappedCell!)
    }

    func testIgnoredClient_selfUser_manyClients() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .ignoredClient, users: 1, clients: 2, config: { message in
            let mockMessageData = message.systemMessageData as? MockSystemMessageData
            mockMessageData?.users = Set<AnyHashable>([MockUser.mockSelf()]) as! Set<ZMUser>
        })
        verify(view: wrappedCell!)
    }

    func testIgnoredClient_oneUser_manyClient() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .ignoredClient, users: 1, clients: 3, config: nil)
        verify(view: wrappedCell!)
    }

    func testConversationIsSecure() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .conversationIsSecure, users: 0, clients: 0, config: nil)
        verify(view: wrappedCell!)
    }

    func testPotentialGap() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .potentialGap, users: 0, clients: 0, config: nil)
        verify(view: wrappedCell!)
    }

    func testStartedusingANewDevice() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .reactivatedDevice, users: 0, clients: 0, config: nil)
        verify(view: wrappedCell!)
    }
}
