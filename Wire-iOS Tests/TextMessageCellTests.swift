//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


@testable import Wire

class TextMessageCellTests: ZMSnapshotTestCase {

    var sut: TextMessageCell!

    var layoutProperties: ConversationCellLayoutProperties {
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        return layoutProperties
    }

    override func setUp() {
        super.setUp()
        Settings.shared().likeTutorialCompleted = true
        snapshotBackgroundColor = UIColor.white
        accentColor = .strongBlue
        sut = TextMessageCell(style: .default, reuseIdentifier: name!)
        sut.layer.speed = 0
        [Message.shortVersionDateFormatter(), Message.longVersionTimeFormatter()].forEach {
            $0.locale = NSLocale(localeIdentifier: "en_US") as Locale!
            $0.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone!
        }
    }
    
    func testThatItRendersATextMessage_Sent() {
        sut.setSelected(true, animated: false)
        sut.configure(for: mockMessage(state: .sent), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_Obfuscated() {
        sut.configure(for: mockMessage(state: .sent, obfuscated: true), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_Delivered() {
        sut.setSelected(true, animated: false)
        sut.configure(for: mockMessage(state: .delivered), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_Expired() {
        sut.configure(for: mockMessage(state: .failedToSend), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_Selected() {
        sut.setSelected(true, animated: false)
        sut.configure(for: mockMessage(), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_Pending_Selected() {
        sut.setSelected(true, animated: false)
        sut.configure(for: mockMessage(state: .pending), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_LongText() {
        let text = "".padding(toLength: 71,  withPad: "Hello ", startingAt: 0)
        sut.configure(for: mockMessage(text), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersEditedTimestampCorrectly_Selected() {
        sut.setSelected(true, animated: false)
        sut.configure(for: mockMessage(edited: true), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersEditedTimestampCorrectly_Selected_LongText() {
        let text = "".padding(toLength: 70, withPad: "Hello ", startingAt: 0)
        sut.setSelected(true, animated: false)
        sut.configure(for: mockMessage(text, edited: true), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersEditedTimestampCorrectly_Selected_LongText_Pending() {
        let text = "".padding(toLength: 70, withPad: "Hello ", startingAt: 0)
        sut.setSelected(true, animated: false)
        sut.configure(for: mockMessage(text, edited: true, state: .pending), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatRenderLastSentMessageWithoutLikeIcon() {
        let layoutProperties = self.layoutProperties
        layoutProperties.alwaysShowDeliveryState = true
        sut.configure(for: mockMessage(state: .sent), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatRenderLastSentMessageWithLikeIcon_whenSelected() {
        let layoutProperties = self.layoutProperties
        layoutProperties.alwaysShowDeliveryState = true
        sut.setSelected(true, animated: false)
        sut.configure(for: mockMessage(state: .sent), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_LikedReceiver() {
        let message = mockMessage(state: .sent)
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [otherUsers.first!]]
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_LikedSender() {
        let message = mockMessage(state: .sent)
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_LikedSelected() {
        let message = mockMessage(state: .sent)
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]
        sut.setSelected(true, animated: false)
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_LikedByTwoPeople() {
        let message = mockMessage(state: .sent)
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: Array(otherUsers[0..<2])]
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_LikedByTwoPeopleIncludingSelf() {
        let message = mockMessage(state: .sent)
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser] + [otherUsers.first!]]
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_LikedByALotOfPeople() {
        let message = mockMessage(state: .sent)
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser] + otherUsers]
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_LikeTooltipNotShownForSelf() {
        Settings.shared().likeTutorialCompleted = false
        
        sut.setSelected(true, animated: false)
        sut.configure(for: mockMessage(), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_LikeTooltipShownForOther() {
        Settings.shared().likeTutorialCompleted = false
        
        let message = mockMessage()
        message.sender = self.otherUsers.first
        
        sut.setSelected(true, animated: false)
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersMessageWithBurstTimestamp() {
        let props = layoutProperties
        props.showBurstTimestamp = true
        sut.configure(for: mockMessage(state: .sent), layoutProperties: props)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersMessageWithDayTimestamp() {
        let props = layoutProperties
        props.showDayBurstTimestamp = true
        sut.configure(for: mockMessage(state: .sent), layoutProperties: props)
        verify(view: sut.prepareForSnapshot())
    }
    
    // MARK: - Helper
    
    func mockMessage(_ text: String? = "Hello World", edited: Bool = false, state: ZMDeliveryState = .delivered, obfuscated: Bool = false) -> MockMessage {
        let message = MockMessageFactory.textMessage(withText: text)
        message?.deliveryState = state
        message?.isObfuscated = obfuscated
        message?.serverTimestamp = Date(timeIntervalSince1970: 1234567230)
        message?.updatedAt = edited ? Date(timeIntervalSince1970: 0) : nil
        return message!
    }
    
    var selfUser: ZMUser {
        return (MockUser.mockSelf() as AnyObject) as! ZMUser
    }

    var otherUsers: [ZMUser] {
        return MockUser.mockUsers().map { $0 }
    }

}

private extension TextMessageCell {

    func prepareForSnapshot() -> UIView {
        self.backgroundColor = .clear
        return self.wrapInTableView()
    }

}
