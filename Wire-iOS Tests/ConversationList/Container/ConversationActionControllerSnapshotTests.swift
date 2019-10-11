
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

import XCTest
@testable import Wire
import SnapshotTesting

final class ConversationActionControllerSnapshotTests: XCTestCase {
    var viewModel: ConversationListViewController.ViewModel!
    fileprivate var mockViewController: MockConversationListContainer!

    override func setUp() {
        super.setUp()

        let account = Account.mockAccount(imageData: Data())
        viewModel = ConversationListViewController.ViewModel(account: account, selfUser: MockUser.mockSelf())

        mockViewController = MockConversationListContainer(viewModel: viewModel)

        viewModel.viewController = mockViewController
    }

    override func tearDown() {
        viewModel = nil
        mockViewController = nil

        super.tearDown()
    }


    func testForActionMenu_removeFolder() {
        let mockConversation = SwiftMockConversation()
        viewModel.showActionMenu(for: mockConversation, from: mockViewController.view)

        let sut = (viewModel?.actionsController)!
        let alert = sut.alertController!

        verify(matching: alert)
    }
}

final class SwiftMockConversation: ConversationInterface {
    var conversationType: ZMConversationType = .group

    var teamRemoteIdentifier: UUID?

    var connectedUser: ZMUser?

    var displayName: String = "Mock Conversation"

    var isArchived: Bool = false

    var isReadOnly: Bool = false

    var isFavorite: Bool = false

    var mutedMessageTypes: MutedMessageTypes = .none

    var activeParticipants: Set<ZMUser> = []

    var folder: LabelType? = MockLabelType()

    var unreadMessages: [ZMConversationMessage] = []

    func canMarkAsUnread() -> Bool {
        return true
    }

    var sortedActiveParticipantUsers: [UserType] = []

    var voiceChannel: VoiceChannel?

    var isConversationEligibleForVideoCalls: Bool = false

    func verifyLegalHoldSubjects() {}

    final class MockLabelType: NSObject, LabelType {
        var remoteIdentifier: UUID?

        var kind: Label.Kind = .folder

        var name: String? = "Test Folder"
    }
}

extension SwiftMockConversation {
    static func groupConversation() -> SwiftMockConversation {
        let selfUser = (MockUser.mockSelf() as Any) as! ZMUser
        let otherUser = MockUser.mockUsers().first!
        let mockConversation = SwiftMockConversation()
        mockConversation.conversationType = .group
        mockConversation.displayName = otherUser.displayName
        mockConversation.sortedActiveParticipantUsers = [selfUser, otherUser]
        mockConversation.isConversationEligibleForVideoCalls = true

        return mockConversation
    }

}
