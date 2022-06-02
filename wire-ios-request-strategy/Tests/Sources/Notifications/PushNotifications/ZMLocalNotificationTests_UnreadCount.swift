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
@testable import WireRequestStrategy

class ZMLocalNotificationTests_UnreadCount: ZMLocalNotificationTests {

    func testThatUnreadCountIsIncreased_ForContentTypes() {
        let contentTypes: [LocalNotificationContentType] = [.image,
                                                            .audio,
                                                            .video,
                                                            .fileUpload,
                                                            .ephemeral(isMention: false, isReply: false),
                                                            .hidden,
                                                            .knock,
                                                            .location,
                                                            .text("Hello World", isMention: false, isReply: false)]

        contentTypes.forEach { contentType in
            XCTAssertTrue(LocalNotificationType.message(contentType).shouldIncreaseUnreadCount)
        }
    }

    func testThatUnreadMentionCountIsIncreased_WhenSelfUserIsMentioned() {
        let contentTypes: [LocalNotificationContentType] = [.ephemeral(isMention: true, isReply: false),
                                                            .text("Hello World", isMention: true, isReply: false)]

        contentTypes.forEach { contentType in
            XCTAssertTrue(LocalNotificationType.message(contentType).shouldIncreaseUnreadMentionCount)
        }
    }

    func testThatUnreadSelfReplyCountIsIncreased_WhenSelfUserIsReplied() {
        let contentTypes: [LocalNotificationContentType] = [.ephemeral(isMention: false, isReply: true),
                                                            .text("Hello World", isMention: false, isReply: true)]

        contentTypes.forEach { contentType in
            XCTAssertTrue(LocalNotificationType.message(contentType).shouldIncreaseUnreadReplyCount)
        }
    }

    func testThatUnreadCountIsntIncreased_ForContentTypesWithoutUserGeneratedContent() {
        let contentTypes: [LocalNotificationContentType] = [.messageTimerUpdate(nil),
                                                            .participantsAdded,
                                                            .participantsRemoved(reason: .none),
                                                            .reaction(emoji: "❤️")]

        contentTypes.forEach { contentType in
            XCTAssertFalse(LocalNotificationType.message(contentType).shouldIncreaseUnreadCount)
        }
    }

}
