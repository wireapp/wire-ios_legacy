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

import Foundation

class Typing {

    #if DEBUG
    public static var defaultTimeout: TimeInterval = 60
    #else
    public static let defaultTimeout: TimeInterval = 60
    #endif

    // MARK: - Properties

    var timeout: TimeInterval = 0

    private let uiContext: NSManagedObjectContext
    private let syncContext: NSManagedObjectContext

    private let typingUserTimeout: TypingUsersTimeout
    private var expirationTimer: ZMTimer?
    private var nextPruneDate: Date?

    private var needsTearDown: Bool

    // MARK: - Life Cycle

    init(uiContext: NSManagedObjectContext, syncContext: NSManagedObjectContext) {
        self.needsTearDown = true
        self.uiContext = uiContext
        self.syncContext = syncContext
        self.timeout = Typing.defaultTimeout
        self.typingUserTimeout = TypingUsersTimeout()
    }

    func tearDown() {
        needsTearDown = false
        expirationTimer?.cancel()
        expirationTimer = nil
    }

    // MARK: - Methods

    func setIsTyping(_ isTyping: Bool, for user: ZMUser, in conversation: ZMConversation) {
        let wasTyping = typingUserTimeout.contains(user, for: conversation)

        if isTyping {
            typingUserTimeout.add(user, for: conversation, withTimeout: Date(timeIntervalSinceNow: timeout))
        }

        if wasTyping != isTyping {
            if !isTyping {
                typingUserTimeout.remove(user, for: conversation)
            }
            sendNotification(for: conversation)
        }

        updateExpirationIfNeeded()
    }

    private func sendNotification(for conversation: ZMConversation) {
        let userIds = typingUserTimeout.userIds(in: conversation)
        let conversationId = conversation.objectID

        uiContext.performGroupedBlock {
            if let conversation = self.uiContext.object(with: conversationId) as? ZMConversation {
                let users = userIds.compactMap { self.uiContext.object(with: $0) as? ZMUser }
                self.uiContext.typingUsers?.update(typingUsers: Set(users), in: conversation)
                conversation.notifyTyping(typingUsers: Set(users))
            }
        }
    }

    private func updateExpirationIfNeeded() {
        guard
            let date = typingUserTimeout.firstTimeout,
            date != nextPruneDate
        else {
            return
        }

        expirationTimer?.cancel()
        expirationTimer = ZMTimer(target: self)
        expirationTimer?.fire(at: date)
        nextPruneDate = date
    }

}

// MARK: - TimerClient

extension Typing: ZMTimerClient {

    func timerDidFire(_ timer: ZMTimer!) {
        guard timer === expirationTimer else { return }

        syncContext.performGroupedBlock {
            let conversationIds = self.typingUserTimeout.pruneConversationsThatHaveTimoutBefore(date: Date())
            conversationIds.forEach {
                if let conversation = self.syncContext.object(with: $0) as? ZMConversation {
                    self.sendNotification(for: conversation)
                }
            }

            self.updateExpirationIfNeeded()
        }
    }
}
