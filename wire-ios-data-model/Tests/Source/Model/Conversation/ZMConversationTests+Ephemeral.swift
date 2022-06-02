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

import Foundation
@testable import WireDataModel

final class MessageDestructionTimeoutValueTests: XCTestCase {

    func testThatItReturnsTheCorrectTimeouts() {
        XCTAssertEqual(MessageDestructionTimeoutValue.none.rawValue, 0)
        XCTAssertEqual(MessageDestructionTimeoutValue.tenSeconds.rawValue, 10)
        XCTAssertEqual(MessageDestructionTimeoutValue.fiveMinutes.rawValue, 300)
        XCTAssertEqual(MessageDestructionTimeoutValue.oneHour.rawValue, 3600)
        XCTAssertEqual(MessageDestructionTimeoutValue.oneDay.rawValue, 86400)
        XCTAssertEqual(MessageDestructionTimeoutValue.oneWeek.rawValue, 604800)
        XCTAssertEqual(MessageDestructionTimeoutValue.fourWeeks.rawValue, 2419200)
    }

    func testThatItCreatesAValidTimeOut() {
        XCTAssertEqual(MessageDestructionTimeoutValue(rawValue: -2), .custom(-2))
        XCTAssertEqual(MessageDestructionTimeoutValue(rawValue: 0), .none)
        XCTAssertEqual(MessageDestructionTimeoutValue(rawValue: 10), .tenSeconds)
        XCTAssertEqual(MessageDestructionTimeoutValue(rawValue: 300), .fiveMinutes)
        XCTAssertEqual(MessageDestructionTimeoutValue(rawValue: 3600), .oneHour)
        XCTAssertEqual(MessageDestructionTimeoutValue(rawValue: 86400), .oneDay)
        XCTAssertEqual(MessageDestructionTimeoutValue(rawValue: 604800), .oneWeek)
        XCTAssertEqual(MessageDestructionTimeoutValue(rawValue: 690000), .custom(690000))
        XCTAssertEqual(MessageDestructionTimeoutValue(rawValue: 2419200), .fourWeeks)
        XCTAssertEqual(MessageDestructionTimeoutValue(rawValue: 1234567890), .custom(1234567890))
    }

}

// Tests for displayString of MessageDestructionTimeoutValue
extension MessageDestructionTimeoutValueTests {

    func testThatItReturnsTheCorrectShortDisplayString() {
        XCTAssertEqual(MessageDestructionTimeoutValue.none.displayString, NSLocalizedString("input.ephemeral.timeout.none", comment: ""))
        XCTAssertEqual(MessageDestructionTimeoutValue.tenSeconds.shortDisplayString, "10")
        XCTAssertEqual(MessageDestructionTimeoutValue.fiveMinutes.shortDisplayString, "5")
        XCTAssertEqual(MessageDestructionTimeoutValue.oneDay.shortDisplayString, "1")
        XCTAssertEqual(MessageDestructionTimeoutValue.oneWeek.shortDisplayString, "1")
        XCTAssertEqual(MessageDestructionTimeoutValue.fourWeeks.shortDisplayString, "4")
    }

    func testThatItReturnsTheCorrectFormattedString() {
        XCTAssertEqual(MessageDestructionTimeoutValue.none.displayString, NSLocalizedString("input.ephemeral.timeout.none", comment: ""))
        XCTAssertEqual(MessageDestructionTimeoutValue.tenSeconds.displayString, "10 seconds")
        XCTAssertEqual(MessageDestructionTimeoutValue.fiveMinutes.displayString, "5 minutes")
        XCTAssertEqual(MessageDestructionTimeoutValue.oneDay.displayString, "1 day")
        XCTAssertEqual(MessageDestructionTimeoutValue.oneWeek.displayString, "1 week")
        XCTAssertEqual(MessageDestructionTimeoutValue.fourWeeks.displayString, "4 weeks")
    }

}

class ZMConversationTests_Ephemeral: BaseZMMessageTests {

    func testThatItAllowsSettingTimeoutsOnGroupConversations() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        // when
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)

        // then
        XCTAssertEqual(conversation.activeMessageDestructionTimeoutType, .selfUser)
        XCTAssertEqual(conversation.activeMessageDestructionTimeoutValue, .tenSeconds)
    }

    func testThatItAllowsSettingSyncedTimeoutsOnGroupConversations() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        // when
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .groupConversation)

        // then
        XCTAssertEqual(conversation.activeMessageDestructionTimeoutType, .groupConversation)
        XCTAssertEqual(conversation.activeMessageDestructionTimeoutValue, .tenSeconds)
    }

    func testThatItAllowsSettingTimeoutsOnOneOnOneConversations() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne

        // when
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)

        // then
        XCTAssertEqual(conversation.activeMessageDestructionTimeoutType, .selfUser)
        XCTAssertEqual(conversation.activeMessageDestructionTimeoutValue, .tenSeconds)
    }

    func testThatItHasDestructionTimeout() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        XCTAssertFalse(conversation.hasSyncedMessageDestructionTimeout)
        XCTAssertFalse(conversation.hasLocalMessageDestructionTimeout)

        // when
        conversation.setMessageDestructionTimeoutValue(.fiveMinutes, for: .selfUser)

        // then
        XCTAssertTrue(conversation.hasLocalMessageDestructionTimeout)
        XCTAssertFalse(conversation.hasSyncedMessageDestructionTimeout)

        // and when
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .groupConversation)

        // then both timeouts exist, but synced timeout dominates
        XCTAssertTrue(conversation.hasSyncedMessageDestructionTimeout)
        XCTAssertTrue(conversation.hasLocalMessageDestructionTimeout)
        XCTAssertEqual(conversation.activeMessageDestructionTimeoutType, .groupConversation)

        // and when
        conversation.setMessageDestructionTimeoutValue(.none, for: .groupConversation)

        // then local timeout persists
        XCTAssertFalse(conversation.hasSyncedMessageDestructionTimeout)
        XCTAssertTrue(conversation.hasLocalMessageDestructionTimeout)
        XCTAssertEqual(conversation.activeMessageDestructionTimeoutType, .selfUser)
    }

    func testThatItReturnsCorrectValueWhenForcedOff() {
        // Given
        let featureService = FeatureService(context: self.syncMOC)

        syncMOC.performGroupedBlockAndWait {
            featureService.storeSelfDeletingMessages(.init(status: .disabled, config: .init()))
        }

        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(featureService.fetchSelfDeletingMesssages().status, .disabled)
        }

        syncMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .groupConversation)

            // Then
            XCTAssertEqual(conversation.activeMessageDestructionTimeoutType, .team)
            XCTAssertEqual(conversation.activeMessageDestructionTimeoutValue, MessageDestructionTimeoutValue.none)
        }
    }

    func testThatItReturnsCorrectValueWhenForcedOn() {
        // Given
        let featureService = FeatureService(context: self.syncMOC)

        syncMOC.performGroupedBlockAndWait {
            featureService.storeSelfDeletingMessages(.init(status: .enabled, config: .init(enforcedTimeoutSeconds: 300)))
        }

        syncMOC.performGroupedBlockAndWait {
            let feature = featureService.fetchSelfDeletingMesssages()
            XCTAssertEqual(feature.status, .enabled)
            XCTAssertEqual(feature.config.enforcedTimeoutSeconds, 300)

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .groupConversation)

            // Then
            XCTAssertEqual(conversation.activeMessageDestructionTimeoutType, .team)
            XCTAssertEqual(conversation.activeMessageDestructionTimeoutValue, .fiveMinutes)
        }
    }

}
