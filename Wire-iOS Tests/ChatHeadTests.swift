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

import XCTest
import Cartography
@testable import Wire

class ChatHeadTests: CoreDataSnapshotTestCase {
    
    var account: Account!
    var message: MockMessage!
    
    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
        
        account = Account(
            userName: selfUser.name,
            userIdentifier: selfUser.remoteIdentifier!,
            teamName: "Wire",
            imageData: nil,
            unreadConversationCount: 0)
        
        message = MockMessageFactory.textMessage(withText: "Hey! How are you?")!
        message.sender = otherUser
        message.conversation = otherUserConversation!
    }
    
    override func tearDown() {
        account = nil
        message = nil
        super.tearDown()
    }
    
    // MARK: - Label Format Tests
    
    func test_ActiveAccount_Team_OneOnOne() {
        
        let titleText = ChatHeadTextFormatter.titleText(
            conversation: message.conversation!,
            teamName: account.teamName,
            isAccountActive: true
        )
        
        let content = ChatHeadTextFormatter.text(for: message, isAccountActive: true)
        
        let sut = ChatHeadView(
            title: titleText,
            content: content,
            sender: otherUser,
            conversation: message.conversation!,
            account: account
        )
        
        verify(view: sut.prepareForSnapshots())
    }
    
    func test_ActiveAccount_Team_Group() {
        
        message.conversation!.conversationType = .group
        message.conversation!.userDefinedName = "Italy Trip"
        
        let titleText = ChatHeadTextFormatter.titleText(
            conversation: message.conversation!,
            teamName: account.teamName,
            isAccountActive: true
        )
        let content = ChatHeadTextFormatter.text(for: message, isAccountActive: true)
        
        let sut = ChatHeadView(
            title: titleText,
            content: content,
            sender: otherUser,
            conversation: message.conversation!,
            account: account
        )
        
        verify(view: sut.prepareForSnapshots())
    }

    func test_ActiveAccount_NonTeam_OneOnOne() {
        
        account.teamName = nil
        
        let titleText = ChatHeadTextFormatter.titleText(
            conversation: message.conversation!,
            teamName: account.teamName,
            isAccountActive: true
        )
        let content = ChatHeadTextFormatter.text(for: message, isAccountActive: true)
        
        let sut = ChatHeadView(
            title: titleText,
            content: content,
            sender: otherUser,
            conversation: message.conversation!,
            account: account
        )
        
        verify(view: sut.prepareForSnapshots())
    }

    func test_ActiveAccount_NonTeam_Group() {
        
        account.teamName = nil
        message.conversation!.conversationType = .group
        message.conversation!.userDefinedName = "Italy Trip"
        
        let titleText = ChatHeadTextFormatter.titleText(
            conversation: message.conversation!,
            teamName: account.teamName,
            isAccountActive: true
        )
        
        let content = ChatHeadTextFormatter.text(for: message, isAccountActive: true)
        
        let sut = ChatHeadView(
            title: titleText,
            content: content,
            sender: otherUser,
            conversation: message.conversation!,
            account: account
        )
        
        verify(view: sut.prepareForSnapshots())
    }
    
    func test_InactiveAccount_Team_OneOnOne() {
        
        let titleText = ChatHeadTextFormatter.titleText(
            conversation: message.conversation!,
            teamName: account.teamName,
            isAccountActive: false
        )
        
        let content = ChatHeadTextFormatter.text(for: message, isAccountActive: false)
        
        let sut = ChatHeadView(
            title: titleText,
            content: content,
            sender: otherUser,
            conversation: message.conversation!,
            account: account
        )
        
        verify(view: sut.prepareForSnapshots())
    }
    
    func test_InactiveAccount_Team_Group() {
        
        message.conversation!.conversationType = .group
        message.conversation!.userDefinedName = "Italy Trip"
        
        let titleText = ChatHeadTextFormatter.titleText(
            conversation: message.conversation!,
            teamName: account.teamName,
            isAccountActive: false
        )
        
        let content = ChatHeadTextFormatter.text(for: message, isAccountActive: false)
        
        let sut = ChatHeadView(
            title: titleText,
            content: content,
            sender: otherUser,
            conversation: message.conversation!,
            account: account
        )
        
        verify(view: sut.prepareForSnapshots())
    }

    func test_InactiveAccount_NonTeam_OneOnOne() {
        
        account.teamName = nil
        
        let titleText = ChatHeadTextFormatter.titleText(
            conversation: message.conversation!,
            teamName: account.teamName,
            isAccountActive: false
        )
        
        let content = ChatHeadTextFormatter.text(for: message, isAccountActive: false)
        
        let sut = ChatHeadView(
            title: titleText,
            content: content,
            sender: otherUser,
            conversation: message.conversation!,
            account: account
        )
        
        verify(view: sut.prepareForSnapshots())
    }
    
    func test_InactiveAccount_NonTeam_Group() {
        
        account.teamName = nil
        message.conversation!.conversationType = .group
        message.conversation!.userDefinedName = "Italy Trip"
        
        let titleText = ChatHeadTextFormatter.titleText(
            conversation: message.conversation!,
            teamName: account.teamName,
            isAccountActive: false
        )
        
        let content = ChatHeadTextFormatter.text(for: message, isAccountActive: false)
        
        let sut = ChatHeadView(
            title: titleText,
            content: content,
            sender: otherUser,
            conversation: message.conversation!,
            account: account
        )
        
        verify(view: sut.prepareForSnapshots())
    }

    // MARK: Misc
    
    func test_Long_Message() {
        
        message = MockMessageFactory.textMessage(withText: String(repeating: "Hello! ", count: 20))!
        message.sender = otherUser
        message.conversation = otherUserConversation!
        
        let titleText = ChatHeadTextFormatter.titleText(
            conversation: message.conversation!,
            teamName: account.teamName,
            isAccountActive: true
        )
        
        let content = ChatHeadTextFormatter.text(for: message, isAccountActive: true)
        
        let sut = ChatHeadView(
            title: titleText,
            content: content,
            sender: otherUser,
            conversation: message.conversation!,
            account: account
        )
        
        verify(view: sut.prepareForSnapshots())
    }
    
    func test_Ephemeral() {
        
        message.isEphemeral = true
        
        let titleText = ChatHeadTextFormatter.titleText(
            conversation: message.conversation!,
            teamName: account.teamName,
            isAccountActive: true
        )
        
        let content = ChatHeadTextFormatter.text(for: message, isAccountActive: true)
        
        let sut = ChatHeadView(
            title: titleText,
            content: content,
            sender: otherUser,
            conversation: message.conversation!,
            account: account
        )
        
        verify(view: sut.prepareForSnapshots())
    }
}

fileprivate extension UIView {
    
    func prepareForSnapshots() -> UIView {
        let container = UIView()
        container.addSubview(self)
        
        constrain(container, self) { container, view in
            container.height == 100
            container.width == 375
            view.leading == container.leading + 16
            view.trailing <= container.trailing - 16
            view.centerY == container.centerY
        }
        
        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }
}
