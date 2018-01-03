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

    /// "Saturday, February 14, 2009 at 12:20:30 AM Central European Standard Time"
    static let dummyServerTimestamp = Date(timeIntervalSince1970: 1234567230)

    var layoutProperties: ConversationCellLayoutProperties {
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        return layoutProperties
    }

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = ColorScheme.default().color(withName: ColorSchemeColorConversationBackground)
        accentColor = .strongBlue
        sut = TextMessageCell(style: .default, reuseIdentifier: name!)
        sut.layer.speed = 0

        resetDayFormatter()

        [Message.shortVersionDateFormatter(), Message.longVersionTimeFormatter()].forEach {
            $0.locale = Locale(identifier: "en_US")
            $0.timeZone = TimeZone(abbreviation: "CET")
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
        let text = "".padding(toLength: 71, withPad: "Hello ", startingAt: 0)
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
        sut.setSelected(true, animated: false)
        sut.configure(for: mockMessage(), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersMessageWithBurstTimestamp() {
        let props = layoutProperties
        props.showBurstTimestamp = true
        sut.configure(for: mockMessage(state: .sent), layoutProperties: props)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersMessageWithBurstTimestamp_Unread() {
        let props = layoutProperties
        props.showBurstTimestamp = true
        props.showUnreadMarker = true
        sut.configure(for: mockMessage(state: .sent), layoutProperties: props)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersMessageWithDayTimestamp() {
        let props = layoutProperties
        props.showDayBurstTimestamp = true
        sut.configure(for: mockMessage(state: .sent), layoutProperties: props)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersMessageWithDayTimestamp_Unread() {
        let props = layoutProperties
        props.showDayBurstTimestamp = true
        props.showUnreadMarker = true
        sut.configure(for: mockMessage(state: .sent), layoutProperties: props)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersMessageWithDayTimestampWithDELocale() {
        setDayFormatterLocale(identifier: "de_DE", date: TextMessageCellTests.dummyServerTimestamp)

        let props = layoutProperties
        props.showDayBurstTimestamp = true
        sut.configure(for: mockMessage(state: .sent), layoutProperties: props)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersMessageWithDayTimestampWithHKLocale() {
        setDayFormatterLocale(identifier: "zh_HK", date: TextMessageCellTests.dummyServerTimestamp)

        let props = layoutProperties
        props.showDayBurstTimestamp = true
        sut.configure(for: mockMessage(state: .sent), layoutProperties: props)
        verify(view: sut.prepareForSnapshot())
    }

    // MARK: - Helper

    func mockMessage(_ text: String? = "Hello World", edited: Bool = false, state: ZMDeliveryState = .delivered, obfuscated: Bool = false, date: Date = TextMessageCellTests.dummyServerTimestamp) -> MockMessage {
        let message = MockMessageFactory.textMessage(withText: text)
        message?.deliveryState = state
        message?.isObfuscated = obfuscated
        message?.serverTimestamp = date
        message?.updatedAt = edited ? Date(timeIntervalSince1970: 0) : nil
        return message!
    }

    var selfUser: ZMUser {
        return (MockUser.mockSelf() as AnyObject) as! ZMUser
    }

    var otherUsers: [ZMUser] {
        return MockUser.mockUsers().map { $0 }
    }

    func resetDayFormatter() {
        let locale = Locale(identifier: "en_US")
        WRDateFormatter.thisYearFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEEdMMMM", options: 0, locale: locale)
        WRDateFormatter.otherYearFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEEdMMMMYYYY", options: 0, locale: locale)
    }

    /// change the locale of the DateFormatter for snapshot
    ///
    /// - Parameters:
    ///   - identifier: locale identifier
    ///   - date: date to determine in with or without yera component
    func setDayFormatterLocale(identifier: String, date: Date) {
        let dayFormatter = Message.dayFormatter(date: date)

        /// overwrite dayFormatter's locale and update the date format string
        let locale = Locale(identifier: identifier)
        let formatString = DateFormatter.dateFormat(fromTemplate: dayFormatter.dateFormat, options: 0, locale: locale)

        dayFormatter.dateFormat = formatString
    }

}

private extension TextMessageCell {

    func prepareForSnapshot() -> UIView {
        self.backgroundColor = .clear
        return self.wrapInTableView()
    }

}

extension Date {

    /// Return first day of the current year at 8am
    ///
    /// - Returns: a Date at ThisYear/1/1 8am
    func startOfYear() -> Date {
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: self)
        components.month = 1
        components.day = 1
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components)!
    }
}
