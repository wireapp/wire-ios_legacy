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

final class ConversationObserverTests: NotificationDispatcherTestBase {

    func checkThatItNotifiesTheObserverOfAChange(_ conversation: ZMConversation,
                                                 modifier: (ZMConversation, ConversationObserver) -> Void,
                                                 expectedChangedField: String?,
                                                 expectedChangedKeys: Set<String>,
                                                 file: StaticString = #file,
                                                 line: UInt = #line) {

        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: modifier,
                                                     expectedChangedFields: expectedChangedField != nil ? [expectedChangedField!] : [],
                                                     expectedChangedKeys: expectedChangedKeys,
                                                     file: file,
                                                     line: line)
    }

    var conversationInfoKeys: Set<String> {
        return [
            "messagesChanged",
            "participantsChanged",
            "activeParticipantsChanged",
            "nameChanged",
            "lastModifiedDateChanged",
            "unreadCountChanged",
            "connectionStateChanged",
            "isArchivedChanged",
            "mutedMessageTypesChanged",
            "conversationListIndicatorChanged",
            "clearedChanged",
            "securityLevelChanged",
            "createdRemotelyChanged",
            "allowGuestsChanged",
            "allowServicesChanged",
            "destructionTimeoutChanged",
            "languageChanged",
            "hasReadReceiptsEnabledChanged",
            "externalParticipantsStateChanged",
            "legalHoldStatusChanged"
        ]
    }

    func checkThatItNotifiesTheObserverOfAChange(_ conversation: ZMConversation,
                                                 modifier: (ZMConversation, ConversationObserver) -> Void,
                                                 expectedChangedFields: Set<String>,
                                                 expectedChangedKeys: Set<String>,
                                                 file: StaticString = #file,
                                                 line: UInt = #line) {

        // given
        let observer = ConversationObserver()
        self.token = ConversationChangeInfo.add(observer: observer, for: conversation)

        // when
        modifier(conversation, observer)
        conversation.managedObjectContext!.saveOrRollback()

        // then
        let changeCount = observer.notifications.count
        if !expectedChangedFields.isEmpty {
            XCTAssertEqual(changeCount, 1, "Observer expected 1 notification, but received \(changeCount).", file: file, line: line)
        } else {
            XCTAssertEqual(changeCount, 0, "Observer was notified, but DID NOT expect a notification", file: file, line: line)
        }

        // and when
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(observer.notifications.count, changeCount, "Should have changed only once", file: file, line: line)

        if expectedChangedFields.isEmpty {
            return
        }

        guard let changes = observer.notifications.first else { return }
        changes.checkForExpectedChangeFields(userInfoKeys: conversationInfoKeys, expectedChangedFields: expectedChangedFields, file: file, line: line)
        XCTAssert(expectedChangedKeys.isSubset(of: changes.changedKeys), "failed: changes.changedKeys = \(changes.changedKeys)", file: file, line: line)
        self.token = nil
    }

    func testThatItNotifiesTheObserverOfANameChange() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        conversation.userDefinedName = "George"
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.userDefinedName = "Phil"},
                                                     expectedChangedField: "nameChanged",
                                                     expectedChangedKeys: ["displayName"]
        )

    }

    func notifyNameChange(_ user: ZMUser, name: String) {
        user.name = name
        self.uiMOC.saveOrRollback()
    }

    func testThatItNotifiesTheObserverOfANameChangeBecauseOfActiveParticipants() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        let otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        otherUser.name = "Foo"
        conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { _, _ in
                                                        self.notifyNameChange(otherUser, name: "Phil")
            },
                                                     expectedChangedField: "nameChanged",
                                                     expectedChangedKeys: ["displayName"]
        )

    }

    func testThatItNotifiesTheObserverOfANameChangeBecauseAnActiveParticipantWasAdded() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { _, _ in

                                                        let otherUser = ZMUser.insertNewObject(in: self.uiMOC)
                                                        otherUser.name = "Foo"
                                                        conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)
        },
                                                     expectedChangedFields: ["nameChanged",
                                                                             "participantsChanged",
                                                                             "activeParticipantsChanged"],
                                                     expectedChangedKeys: ["displayName", "localParticipantRoles"]
        )

    }

    func testThatItNotifiesTheObserverOfANameChangeBecauseOfActiveParticipantsMultipleTimes() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let observer = ConversationObserver()
        self.token = ConversationChangeInfo.add(observer: observer, for: conversation)

        // when
        user.name = "Boo"
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(observer.notifications.count, 1)

        // and when
        user.name = "Bar"
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(observer.notifications.count, 2)

        // and when
        self.uiMOC.saveOrRollback()
    }

    func testThatItDoesNotNotifyTheObserverBecauseAUsersAccentColorChanged() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        let otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        otherUser.accentColorValue = .brightOrange
        conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { _, _ in
                                                        otherUser.accentColorValue = ZMAccentColor.softPink
            },
                                                     expectedChangedField: nil,
                                                     expectedChangedKeys: []
        )
    }

    func testThatItNotifiesTheObserverOfANameChangeBecauseOfOtherUserNameChange() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .oneOnOne

        let otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        otherUser.name = "Foo"

        let connection = ZMConnection.insertNewObject(in: self.uiMOC)
        connection.to = otherUser
        connection.status = .accepted
        conversation.connection = connection

        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { _, _ in
                                                        self.notifyNameChange(otherUser, name: "Phil")
            },
                                                     expectedChangedField: "nameChanged",
                                                     expectedChangedKeys: ["displayName"]
        )

    }

    func testThatItNotifysTheObserverOfANameChangeBecauseAUserWasAddedLaterAndHisNameChanged() {
        // given
        let user1 = ZMUser.insertNewObject(in: self.uiMOC)
        user1.name = "Foo A"

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, observer in
                                                        conversation.addParticipantAndUpdateConversationState(user: user1, role: nil)
                                                        self.uiMOC.saveOrRollback()
                                                        observer.clearNotifications()
                                                        self.notifyNameChange(user1, name: "Bar")
        },
                                                     expectedChangedField: "nameChanged",
                                                     expectedChangedKeys: ["displayName"]
        )
    }

    func testThatItNotifiesTheObserverOfAnInsertedMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.lastReadServerTimeStamp = Date()
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in try! conversation.appendText(content: "foo")},
                                                     expectedChangedFields: ["messagesChanged", "lastModifiedDateChanged"],
                                                     expectedChangedKeys: ["allMessages", "lastModifiedDate"])
    }

    func testThatItNotifiesTheObserverOfAnAddedParticipant() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "Foo"
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.addParticipantAndUpdateConversationState(user: user, role: nil) },
                                                     expectedChangedFields: ["participantsChanged",
                                                                             "nameChanged",
                                                                             "activeParticipantsChanged"],
                                                     expectedChangedKeys: ["displayName", "localParticipantRoles"])

    }

    func testThatItNotifiesTheObserverOfARemovedParticipant() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "Foo"
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        uiMOC.saveOrRollback()
        guard let role = conversation.participantRoles.first else {
            return XCTFail()
        }

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            conversation,
            modifier: { conversation, _ in
                // This is simulating a backend removal. If I call `remove...` it will just mark as
                // logically deleted
                conversation.participantRoles.remove(role)
                self.uiMOC.delete(role)
            },
            expectedChangedFields: ["participantsChanged",
                                    "nameChanged",
                                    "activeParticipantsChanged"],
            expectedChangedKeys: ["displayName", "localParticipantRoles"]
        )

    }

    func testThatItNotifiesTheObserverOfAnRemovedParticipant() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        user.name = "bar"
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        checkThatItNotifiesTheObserverOfAChange(conversation,
                                                modifier: {conversation, _ in conversation.removeParticipantsAndUpdateConversationState(users: Set([user]), initiatingUser: selfUser) },
                                                expectedChangedFields: ["participantsChanged",
                                                                        "nameChanged",
                                                                        "activeParticipantsChanged"],
                                                expectedChangedKeys: ["displayName",
                                                                      "localParticipantRoles"])
    }

    func testThatItNotifiesTheObserverOfAParticipantRoleAdded() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "Foo"

        let newRole = Role.insertNewObject(in: self.uiMOC)
        newRole.name = "New Role"

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)

        uiMOC.saveOrRollback()

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let modifier: (ZMConversation, ZMConversationObserver) -> Void = { conversation, _ in
            conversation.participantRoles.forEach {
                $0.role = newRole
            }
        }

        // then
        checkThatItNotifiesTheObserverOfAChange(conversation,
                                                modifier: modifier,
                                                expectedChangedFields: ["participantsChanged"],
                                                expectedChangedKeys: ["localParticipantRoles"])

    }

    func testThatItNotifiesTheObserverOfAParticipantRoleChanged() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "Foo"

        let oldRole = Role.insertNewObject(in: self.uiMOC)
        oldRole.name = "Old Role"

        let newRole = Role.insertNewObject(in: self.uiMOC)
        newRole.name = "New Role"

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        conversation.addParticipantAndUpdateConversationState(user: user, role: oldRole)

        uiMOC.saveOrRollback()

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let modifier: (ZMConversation, ZMConversationObserver) -> Void = { conversation, _ in
            conversation.participantRoles.forEach {
                $0.role = newRole
            }
        }

        // then
        checkThatItNotifiesTheObserverOfAChange(conversation,
                                                modifier: modifier,
                                                expectedChangedFields: ["participantsChanged"],
                                                expectedChangedKeys: ["localParticipantRoles"])

    }

    func testThatItNotifiesTheObserverIfTheSelfUserIsAdded() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        conversation.removeParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: self.uiMOC))
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            conversation,

            modifier: {conversation, _ in
                conversation.addParticipantAndUpdateConversationState(
                    user: ZMUser.selfUser(in: self.uiMOC),
                    role: nil)
        },
            expectedChangedFields: [
                "participantsChanged",
                "activeParticipantsChanged",
                "nameChanged"],
            expectedChangedKeys: [
                "localParticipantRoles",
                "displayName",
                "localParticipants"
            ]
        )

    }

    func testThatItNotifiesTheObserverWhenTheUserLeavesTheConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        _ = ZMUser.insertNewObject(in: self.uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: self.uiMOC), role: nil)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            conversation,
            modifier: {conversation, _ in
                conversation.removeParticipantAndUpdateConversationState(
                    user: ZMUser.selfUser(in: self.uiMOC))
        },
            expectedChangedFields: [
                "participantsChanged",
                "activeParticipantsChanged",
                "nameChanged"
            ],
            expectedChangedKeys: [
                "localParticipantRoles",
                "displayName",
                "localParticipants"]
        )

    }

    func testThatItNotifiesTheObserverOfChangedLastModifiedDate() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.lastModifiedDate = Date() },
                                                     expectedChangedField: "lastModifiedDateChanged",
                                                     expectedChangedKeys: ["lastModifiedDate"])

    }

    func testThatItNotifiesTheObserverOfChangedUnreadCount() {
        // given
        let uiConversation: ZMConversation = ZMConversation.insertNewObject(in: self.uiMOC)
        uiConversation.lastReadServerTimeStamp = Date()
        uiConversation.userDefinedName = "foo"
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        var conversation: ZMConversation!
        var message: ZMMessage!
        self.syncMOC.performGroupedBlockAndWait {
            conversation = self.syncMOC.object(with: uiConversation.objectID) as? ZMConversation
            message = ZMMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            message.visibleInConversation = conversation
            message.serverTimestamp = conversation.lastReadServerTimeStamp?.addingTimeInterval(10)
            self.syncMOC.saveOrRollback()

            conversation.calculateLastUnreadMessages()
            self.syncMOC.saveOrRollback()
            XCTAssertEqual(conversation.estimatedUnreadCount, 1)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mergeLastChanges()

        let observer = ConversationObserver()
        self.token = ConversationChangeInfo.add(observer: observer, for: uiConversation)

        // when
        self.syncMOC.performGroupedBlockAndWait {
            conversation.lastReadServerTimeStamp = message.serverTimestamp
            conversation.calculateLastUnreadMessages()
            XCTAssertEqual(conversation.estimatedUnreadCount, 0)
            self.syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mergeLastChanges()

        // then
        let changeCount = observer.notifications.count
        XCTAssertEqual(changeCount, 1, "Observer expected 1 notification, but received \(changeCount).")

        guard let changes = observer.notifications.first else { return XCTFail() }
        changes.checkForExpectedChangeFields(userInfoKeys: conversationInfoKeys,
                                     expectedChangedFields: ["unreadCountChanged", "conversationListIndicatorChanged"])
        XCTAssertEqual(changes.changedKeys, Set(["estimatedUnreadCount", "conversationListIndicator"]))

    }

    func testThatItNotifiesTheObserverOfChangedDisplayName() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.userDefinedName = "Cacao" },
                                                     expectedChangedField: "nameChanged" ,
                                                     expectedChangedKeys: ["displayName"])

    }

    func testThatAccessModeChangeIsTriggeringObservation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.accessMode = .teamOnly },
                                                     expectedChangedField: "allowGuestsChanged",
                                                     expectedChangedKeys: [#keyPath(ZMConversation.accessModeStrings)])
    }

    func testThatSyncedDestructionTimeoutChangeIsTriggeringObservation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.setMessageDestructionTimeoutValue(.custom(1000), for: .groupConversation) },
                                                     expectedChangedField: "destructionTimeoutChanged",
                                                     expectedChangedKeys: [#keyPath(ZMConversation.syncedMessageDestructionTimeout)])
    }

    func createGroupConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        return conversation
    }

    func testThatLocalDestructionTimeoutChangeIsTriggeringObservation() {
        // given
        let conversation = createGroupConversation()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.setMessageDestructionTimeoutValue(.custom(1000), for: .selfUser) },
                                                     expectedChangedField: "destructionTimeoutChanged",
                                                     expectedChangedKeys: [#keyPath(ZMConversation.localMessageDestructionTimeout)])
    }

    func testThatLanguageChangeIsTriggeringObservation() {
        // given
        let conversation = createGroupConversation()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.language = "de-DE" },
                                                     expectedChangedField: "languageChanged",
                                                     expectedChangedKeys: [#keyPath(ZMConversation.language)])
    }

    func testThatAccessRoleChangeIsTriggeringObservation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.accessRole = .activated },
                                                     expectedChangedField: "allowGuestsChanged",
                                                     expectedChangedKeys: [#keyPath(ZMConversation.accessRoleString)])
    }

    func testThatAccessRoleV2ChangeIsTriggeringObservation() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.group
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.accessRoles = [.teamMember, .guest] },
                                                     expectedChangedFields: ["allowServicesChanged", "allowGuestsChanged"],
                                                     expectedChangedKeys: [#keyPath(ZMConversation.accessRoleStringsV2)])
    }

    func testThatItNotifiesTheObserverOfChangedConnectionStatusWhenInsertingAConnection() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.oneOnOne
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in
                                                        conversation.connection = ZMConnection.insertNewObject(in: self.uiMOC)
                                                        conversation.connection!.status = ZMConnectionStatus.pending
            },
                                                     expectedChangedFields: ["connectionStateChanged",
                                                                             "nameChanged"],
                                                     expectedChangedKeys: ["relatedConnectionState"])
    }

    func testThatItNotifiesTheObserverOfChangedConnectionStatusWhenUpdatingAConnection() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = ZMConversationType.oneOnOne
        conversation.connection = ZMConnection.insertNewObject(in: self.uiMOC)
        conversation.connection!.status = ZMConnectionStatus.pending
        conversation.connection!.to = ZMUser.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.connection!.status = ZMConnectionStatus.accepted },
                                                     expectedChangedFields: ["connectionStateChanged",
                                                                             "nameChanged"],
                                                     expectedChangedKeys: ["relatedConnectionState"])

    }

    func testThatItNotifiesTheObserverOfChangedArchivedStatus() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.isArchived = true },
                                                     expectedChangedField: "isArchivedChanged" ,
                                                     expectedChangedKeys: ["isArchived"])

    }

    func testThatItNotifiesTheObserverOfChangedSilencedStatus() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in conversation.mutedMessageTypes = .regular },
                                                     expectedChangedField: "mutedMessageTypesChanged" ,
                                                     expectedChangedKeys: ["mutedStatus"])

    }

    func addUnreadMissedCall(_ conversation: ZMConversation) {
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: conversation.managedObjectContext!)
        systemMessage.systemMessageType = .missedCall
        systemMessage.serverTimestamp = Date(timeIntervalSince1970: 1231234)
        systemMessage.visibleInConversation = conversation
        conversation.calculateLastUnreadMessages()
    }

    func testThatItNotifiesTheObserverOfAChangedListIndicatorBecauseOfAnUnreadMissedCall() {
        // given
        let uiConversation: ZMConversation = ZMConversation.insertNewObject(in: self.uiMOC)
        uiConversation.userDefinedName = "foo"
        uiMOC.saveOrRollback()

        var conversation: ZMConversation!
        self.syncMOC.performGroupedBlockAndWait {
            conversation = self.syncMOC.object(with: uiConversation.objectID) as? ZMConversation
            self.syncMOC.saveOrRollback()
        }

        let observer = ConversationObserver()
        self.token = ConversationChangeInfo.add(observer: observer, for: uiConversation)

        // when
        self.syncMOC.performGroupedBlockAndWait {
            self.addUnreadMissedCall(conversation)
            self.syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mergeLastChanges()

        // then
        let changeCount = observer.notifications.count
        XCTAssertEqual(changeCount, 1, "Observer expected 1 notification, but received \(changeCount).")

        guard let changes = observer.notifications.first else { return XCTFail() }
        changes.checkForExpectedChangeFields(userInfoKeys: conversationInfoKeys,
                                     expectedChangedFields: ["conversationListIndicatorChanged", "messagesChanged", "unreadCountChanged"])
        XCTAssertEqual(changes.changedKeys, Set(["allMessages", "conversationListIndicator", "estimatedUnreadCount"]))
    }

    func testThatItNotifiesTheObserverOfAChangedClearedTimeStamp() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in
                                                        conversation.clearedTimeStamp = Date()
            },
                                                     expectedChangedField: "clearedChanged" ,
                                                     expectedChangedKeys: ["clearedTimeStamp"])
    }

    func testThatItNotifiesTheObserverOfASecurityLevelChange() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in
                                                        conversation.securityLevel = .secure
            },
                                                     expectedChangedField: "securityLevelChanged" ,
                                                     expectedChangedKeys: ["securityLevel"])
    }

    func testThatItNotifiesAboutSecurityLevelChange_AddingParticipant() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        conversation.securityLevel = .secure
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in
                                                        let user = ZMUser.insertNewObject(in: self.uiMOC)
                                                        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        },
                                                     expectedChangedFields: ["securityLevelChanged", "messagesChanged", "nameChanged", "participantsChanged", "activeParticipantsChanged"],
                                                     expectedChangedKeys: ["displayName", "allMessages", "localParticipantRoles", "securityLevel"])

    }

    func testThatItNotifiesAboutSecurityLevelChange_AddingDevice() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let user = ZMUser.insertNewObject(in: self.uiMOC)

        conversation.conversationType = .group
        conversation.securityLevel = .secure
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in
                                                        let client = UserClient.insertNewObject(in: self.uiMOC)
                                                        client.remoteIdentifier = "aabbccdd"
                                                        client.user = user

                                                        conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [client], causedBy: nil)

        },
                                                     expectedChangedFields: ["securityLevelChanged", "messagesChanged"],
                                                     expectedChangedKeys: ["securityLevel", "allMessages"])

    }

    func testThatItNotifiesAboutSecurityLevelChange_SendingMessageToDegradedConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.securityLevel = .secureWithIgnored
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let observer = ConversationObserver()
        self.token = ConversationChangeInfo.add(observer: observer, for: conversation)

        // when
        try! conversation.appendText(content: "Foo")
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(observer.notifications.count, 2)

        guard let first = observer.notifications.first, let second = observer.notifications.last else { return }

        // We get two notifications - one for messages added and another for non-core data change
        let messagesNotification = first.messagesChanged ? first : second
        let securityNotification = first.securityLevelChanged ? first : second

        XCTAssertTrue(messagesNotification.messagesChanged)
        XCTAssertTrue(securityNotification.securityLevelChanged)
    }

    func testThatItNotifiesWhenConversationIsCreatedRemotely() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in
                                                        conversation.remoteIdentifier = UUID.create()
        },
                                                     expectedChangedFields: ["createdRemotelyChanged"],
                                                     expectedChangedKeys: ["remoteIdentifier"])

    }

    func testThatItStopsNotifyingAfterUnregisteringTheToken() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        let observer = ConversationObserver()
        _ = ConversationChangeInfo.add(observer: observer, for: conversation)

        // when
        conversation.userDefinedName = "Mario!"
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(observer.notifications.count, 0)
    }

    func testThatItSendsUpdateForReadReceiptsEnabled() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: { conversation, _ in
                                                        conversation.hasReadReceiptsEnabled = true
        },
                                                     expectedChangedFields: ["hasReadReceiptsEnabledChanged"],
                                                     expectedChangedKeys: ["hasReadReceiptsEnabled"])
    }

    func testThatItSendsUpdateForUpdatedServiceUser() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        let user = createUser(in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        uiMOC.saveOrRollback()

        // when
        checkThatItNotifiesTheObserverOfAChange(conversation,
                                                 modifier: { _, _ in
                                                    user.serviceIdentifier = UUID().uuidString
                                                    user.providerIdentifier = UUID().uuidString
                                                           },
                                                 expectedChangedFields: ["externalParticipantsStateChanged"],
                                                 expectedChangedKeys: ["externalParticipantsState"])
    }

    func testThatItNotifiesOfLegalHoldChanges_Enabled() {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        let user = createUser(in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)

        let legalHoldClient = UserClient.insertNewObject(in: uiMOC)
        legalHoldClient.type = .legalHold
        legalHoldClient.deviceClass = .legalHold

        uiMOC.saveOrRollback()

        let modifier: (ZMConversation, ConversationObserver) -> Void = { conversation, _ in
            self.performPretendingUiMocIsSyncMoc {
                legalHoldClient.user = user
                conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: [user])
            }
        }

        // Discovering a legal hold client should add a system message and change the legal hold value
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: modifier,
                                                     expectedChangedFields: [#keyPath(ConversationChangeInfo.legalHoldStatusChanged), #keyPath(ConversationChangeInfo.messagesChanged)],
                                                     expectedChangedKeys: [#keyPath(ZMConversation.legalHoldStatus), #keyPath(ZMConversation.allMessages)])
    }

    func testThatItNotifiesOfLegalHoldChanges_Disabled() {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        let user = createUser(in: uiMOC)

        let legalHoldClient = UserClient.insertNewObject(in: uiMOC)
        legalHoldClient.type = .legalHold
        legalHoldClient.deviceClass = .legalHold
        legalHoldClient.user = user

        let normalClient = UserClient.insertNewObject(in: uiMOC)
        normalClient.type = .permanent
        normalClient.deviceClass = .phone
        normalClient.user = user

        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        uiMOC.saveOrRollback()

        let modifier: (ZMConversation, ConversationObserver) -> Void = { _, _ in
            self.performPretendingUiMocIsSyncMoc {
                legalHoldClient.deleteClientAndEndSession()
            }
        }

        // Removing a legal hold client should add a system message and change the legal hold value
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
                                                     modifier: modifier,
                                                     expectedChangedFields: [#keyPath(ConversationChangeInfo.legalHoldStatusChanged), #keyPath(ConversationChangeInfo.messagesChanged)],
                                                     expectedChangedKeys: [#keyPath(ZMConversation.legalHoldStatus), #keyPath(ZMConversation.allMessages)])
    }

    // MARK: - Role

    func testThatItNotifiesOfParticipantRoleChanges() {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        let user = createUser(in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)

        let role = Role.create(managedObjectContext: uiMOC, name: "dummy role", conversation: conversation)

        uiMOC.saveOrRollback()

        let modifier: (ZMConversation, ConversationObserver) -> Void = { conversation, _ in
            self.performPretendingUiMocIsSyncMoc {
                user.participantRole(in: conversation)?.role = role
            }
        }

        checkThatItNotifiesTheObserverOfAChange(conversation,
                                                modifier: modifier,
                                                expectedChangedFields: [#keyPath(ConversationChangeInfo.participantsChanged)],
                                                expectedChangedKeys: [#keyPath(ZMConversation.localParticipantRoles)])
    }

}

extension ZMUser {
    func participantRole(in conversation: ZMConversation?) -> ParticipantRole? {
        return participantRoles.first(where: { $0.conversation == conversation })
    }
}

// MARK: Performance

extension ConversationObserverTests {

    func testPerformanceOfCalculatingChangeNotificationsWhenUserChangesName() {
        // average: 0.056, relative standard deviation: 2.400%, values: [0.056840, 0.054732, 0.059911, 0.056330, 0.055015, 0.055535, 0.055917, 0.056481, 0.056177, 0.056115]
        // 13/02/17 average: 0.049, relative standard deviation: 4.095%, values: [0.052629, 0.046448, 0.046743, 0.047157, 0.051125, 0.048899, 0.047646, 0.048362, 0.048110, 0.051135]
        let count = 50

        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {

            let user = ZMUser.insertNewObject(in: self.uiMOC)
            user.name = "foo"
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.conversationType = .group
            conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
            self.uiMOC.saveOrRollback()

            let observer = ConversationObserver()
            self.token = ConversationChangeInfo.add(observer: observer, for: conversation)

            var lastName = "bar"
            self.startMeasuring()
            for _ in 1...count {
                let temp = lastName
                lastName = user.name!
                user.name = temp
                self.uiMOC.saveOrRollback()
            }
            XCTAssertEqual(observer.notifications.count, count)
            self.stopMeasuring()
        }
    }

    func testPerformanceOfCalculatingChangeNotificationsWhenANewMessageArrives() {
       // average: 0.059, relative standard deviation: 13.343%, values: [0.082006, 0.056299, 0.056005, 0.056230, 0.059868, 0.055533, 0.055511, 0.055503, 0.055434, 0.055458]
        // 13/02/17: average: 0.062, relative standard deviation: 10.863%, values: [0.082063, 0.059699, 0.059220, 0.059861, 0.060348, 0.059494, 0.064300, 0.060022, 0.058819, 0.058870]
        let count = 50

        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {

            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            self.uiMOC.saveOrRollback()

            let observer = ConversationObserver()
            self.token = ConversationChangeInfo.add(observer: observer, for: conversation)

            self.startMeasuring()
            for _ in 1...count {
                try! conversation.appendText(content: "hello")
                self.uiMOC.saveOrRollback()
            }
            XCTAssertEqual(observer.notifications.count, count)
            self.stopMeasuring()
        }
    }

    func testPerformanceOfCalculatingChangeNotificationsWhenANewMessageArrives_AppendingManyMessages() {
        // 50: average: 0.026, relative standard deviation: 29.098%, values: [0.047283, 0.023655, 0.024622, 0.025462, 0.029163, 0.024709, 0.024966, 0.020773, 0.020413, 0.019464],
        // 500: average: 0.243, relative standard deviation: 4.039%, values: [0.264489, 0.235209, 0.245864, 0.244984, 0.231789, 0.244359, 0.251886, 0.229036, 0.247700, 0.239637],

        // 13/02/17 - 50 : average: 0.023, relative standard deviation: 27.833%, values: [0.041493, 0.020441, 0.020226, 0.020104, 0.021268, 0.021039, 0.020917, 0.020330, 0.020558, 0.019953]
        let count = 50

        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {

            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            self.uiMOC.saveOrRollback()

            let observer = ConversationObserver()
            self.token = ConversationChangeInfo.add(observer: observer, for: conversation)

            self.startMeasuring()
            for _ in 1...count {
                try! conversation.appendText(content: "hello")
            }
            self.uiMOC.saveOrRollback()
            XCTAssertEqual(observer.notifications.count, 1)
            self.stopMeasuring()
        }
    }

    func testPerformanceOfCalculatingChangeNotificationsWhenANewMessageArrives_RegisteringNewObservers() {
       // 50: average: 0.093, relative standard deviation: 9.576%, values: [0.119425, 0.091509, 0.088228, 0.090549, 0.090424, 0.086471, 0.091216, 0.091060, 0.094097, 0.089602],
        // 500: average: 0.886, relative standard deviation: 1.875%, values: [0.922453, 0.878736, 0.880529, 0.899234, 0.875889, 0.904563, 0.890234, 0.872045, 0.868912, 0.871016]
        // 500: after adding convList observer average: 1.167, relative standard deviation: 9.521%, values: [1.041614, 1.020351, 1.055602, 1.098007, 1.129816, 1.166439, 1.221696, 1.293128, 1.314360, 1.331703], --> growing due to additional conversation observers
        // 500: after forwarding conversation changes: average: 0.941, relative standard deviation: 2.144%, values: [0.991118, 0.956727, 0.947056, 0.928683, 0.937171, 0.947680, 0.928902, 0.925021, 0.923206, 0.922440] --> constant! yay!
        // 13/02/17 50: average: 0.104, relative standard deviation: 10.316%, values: [0.134496, 0.097219, 0.106044, 0.100265, 0.098114, 0.097030, 0.105297, 0.099680, 0.098974, 0.099365]

        let count = 50

        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {

            let observer = ConversationObserver()

            self.startMeasuring()
            for _ in 1...count {
                let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
                self.uiMOC.saveOrRollback()
                _ = ConversationChangeInfo.add(observer: observer, for: conversation)
                try! conversation.appendText(content: "hello")
                self.uiMOC.saveOrRollback()
            }
            self.stopMeasuring()
        }
    }
}
