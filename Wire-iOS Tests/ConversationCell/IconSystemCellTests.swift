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
    
    var sut: IconSystemCell!
    
    override func setUp() {
        super.setUp()
        sut = IconSystemCell()

        self.snapshotBackgroundColor = .white
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    class func systemMessageTypeToClass() -> [ZMSystemMessageType : IconSystemCell.Type]? {
        return [.newClient: ConversationNewDeviceCell.self,
                .ignoredClient: ConversationIgnoredDeviceCell.self,
                .conversationIsSecure: ConversationVerifiedCell.self,
                .potentialGap: MissingMessagesCell.self,
                .decryptionFailed: CannotDecryptCell.self,
                .reactivatedDevice: MissingMessagesCell.self]
    }

    class func wrappedCell(for type: ZMSystemMessageType,
                           users usersCount: Int,
                           clients clientsCount: Int,
                           config: ((MockMessage) -> ())?) -> UITableView? {

        let systemMessage = MockMessageFactory.systemMessage(with: type, users: usersCount, clients: clientsCount)

        config?(systemMessage!)

        let cell: IconSystemCell? = IconSystemCellTests.systemMessageTypeToClass()![type]!.init(style: .default, reuseIdentifier: "test") as IconSystemCell

        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = false
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false

        cell?.prepareForReuse()
        cell?.bounds = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 9999)
        cell?.contentView.bounds = CGRect(x: 0.0, y: 0.0, width: 320, height: 9999)
        cell?.layoutMargins = UIView.directionAwareConversationLayoutMargins
        cell?.configure(for: systemMessage, layoutProperties: layoutProperties)
        cell?.layoutIfNeeded()
        let size = cell?.systemLayoutSizeFitting(CGSize(width: 320.0, height: 0.0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        cell?.bounds = CGRect(x: 0.0, y: 0.0, width: (size?.width)!, height: (size?.height)!)
        return cell?.wrapInTableView()
    }


    func testCannotDecryptMessage() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .decryptionFailed, users: 0, clients: 0, config: nil)
        verify(view: wrappedCell!)
    }

    func testNewClient_oneUser_oneClient() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .newClient, users: 1, clients: 1, config: nil)
        verify(view: wrappedCell!)
    }

    func testNewClient_selfUser_oneClient() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .newClient, users: 1, clients: 1, config: { message in
            let mockMessageData = message.systemMessageData as? MockSystemMessageData
            mockMessageData?.users = Set<AnyHashable>([MockUser.mockSelf()]) as? Set<ZMUser>
        })
        verify(view: wrappedCell!)
    }

    func testNewClient_selfUser_manyClients() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .newClient, users: 1, clients: 2, config: { message in
            let mockMessageData = message.systemMessageData as? MockSystemMessageData
            mockMessageData?.users = Set<AnyHashable>([MockUser.mockSelf()]) as? Set<ZMUser>
        })
        verify(view: wrappedCell!)
    }

    func testNewClient_oneUser_manyClient() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .newClient, users: 1, clients: 3, config: nil)
        verify(view: wrappedCell!)
    }

    func testNewClient_manyUsers_manyClient() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .newClient, users: 3, clients: 4, config: nil)
        verify(view: wrappedCell!)
    }

    func testIgnoredClient_oneUser_oneClient() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .ignoredClient, users: 1, clients: 1, config: nil)
        verify(view: wrappedCell!)
    }

    func testIgnoredClient_selfUser_oneClient() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .ignoredClient, users: 1, clients: 1, config: { message in
            let mockMessageData = message.systemMessageData as? MockSystemMessageData
            mockMessageData?.users = Set<AnyHashable>([MockUser.mockSelf()]) as? Set<ZMUser>
        })
        verify(view: wrappedCell!)
    }

    func testIgnoredClient_selfUser_manyClients() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .ignoredClient, users: 1, clients: 2, config: { message in
            let mockMessageData = message.systemMessageData as? MockSystemMessageData
            mockMessageData?.users = Set<AnyHashable>([MockUser.mockSelf()]) as? Set<ZMUser>
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

    func testDecryptionFailed() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .decryptionFailed, users: 0, clients: 0, config: nil)
        verify(view: wrappedCell!)
    }

    func testStartedusingANewDevice() {
        let wrappedCell: UITableView? = IconSystemCellTests.wrappedCell(for: .reactivatedDevice, users: 0, clients: 0, config: nil)
        verify(view: wrappedCell!)
    }

}
