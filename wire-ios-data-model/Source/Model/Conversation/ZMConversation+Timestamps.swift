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

import Foundation

fileprivate extension ZMConversationMessage {

    var serverTimestampIncludingChildMessages: Date? {

        if let systemMessage = self as? ZMSystemMessage {
            return systemMessage.lastChildMessageDate
        }

        return serverTimestamp
    }

}

fileprivate extension ZMMessage {

    static func isVisible(_ message: ZMMessage) -> Bool {
        if let systemMessage = message as? ZMSystemMessage, let parentMessage = systemMessage.parentMessage as? ZMMessage {
            return parentMessage.visibleInConversation != nil
        } else {
            return message.visibleInConversation != nil
        }
    }

}

extension ZMConversation {

    // MARK: - Timestamps

    func updatePendingLastRead(_ timestamp: Date) {
        if timestamp > pendingLastReadServerTimestamp {
            pendingLastReadServerTimestamp = timestamp
        }

        if previousLastReadServerTimestamp == nil {
            previousLastReadServerTimestamp = lastReadServerTimeStamp
        }
    }

    @objc
    func updateLastRead(_ timestamp: Date, synchronize: Bool = false) {
        guard let managedObjectContext = managedObjectContext else { return }

        if timestamp > lastReadServerTimeStamp {
            lastReadServerTimeStamp = timestamp

            // modified keys are set "automatically" on the uiMOC
            if synchronize && managedObjectContext.zm_isSyncContext {
                setLocallyModifiedKeys(Set([ZMConversationLastReadServerTimeStampKey]))
            }

            NotificationInContext(name: ZMConversation.lastReadDidChangeNotificationName, context: managedObjectContext.notificationContext, object: self, userInfo: nil).post()
        }
    }

    @objc
    public func updateLastModified(_ timestamp: Date) {
        if timestamp > lastModifiedDate {
            lastModifiedDate = timestamp
        }
    }

    @objc
    public func updateServerModified(_ timestamp: Date) {
        if timestamp > lastServerTimeStamp {
            lastServerTimeStamp = timestamp
        }
    }

    @objc
    public func updateCleared(_ timestamp: Date, synchronize: Bool = false) {
        guard let managedObjectContext = managedObjectContext else { return }

        if timestamp > clearedTimeStamp {
            clearedTimeStamp = timestamp

            if synchronize && managedObjectContext.zm_isSyncContext {
                setLocallyModifiedKeys(Set([ZMConversationClearedTimeStampKey]))
            }
        }
    }

    @objc @discardableResult
    func updateArchived(_ timestamp: Date, synchronize: Bool = false) -> Bool {
        guard let managedObjectContext = managedObjectContext else { return false }

        if timestamp > archivedChangedTimestamp {
            archivedChangedTimestamp = timestamp

            if synchronize && managedObjectContext.zm_isSyncContext {
                setLocallyModifiedKeys([ZMConversationArchivedChangedTimeStampKey])
            }

            return true
        } else if timestamp == archivedChangedTimestamp {
            if synchronize {
                setLocallyModifiedKeys([ZMConversationArchivedChangedTimeStampKey])
            }

            return true
        }

        return false
    }

    @objc @discardableResult
    func updateMuted(_ timestamp: Date, synchronize: Bool = false) -> Bool {
        guard let managedObjectContext = managedObjectContext else { return false }

        if timestamp > silencedChangedTimestamp {
            silencedChangedTimestamp = timestamp

            if synchronize && managedObjectContext.zm_isSyncContext {
                setLocallyModifiedKeys([ZMConversationSilencedChangedTimeStampKey])
            }

            return true
        } else if timestamp == silencedChangedTimestamp {
            if synchronize {
                setLocallyModifiedKeys([ZMConversationSilencedChangedTimeStampKey])
            }

            return true
        }

        return false
    }

    fileprivate func updateLastUnreadKnock(_ timestamp: Date?) {
        guard let timestamp = timestamp else { return lastUnreadKnockDate = nil }

        if timestamp > lastUnreadKnockDate {
            lastUnreadKnockDate = timestamp
        }
    }

    fileprivate func updateLastUnreadMissedCall(_ timestamp: Date?) {
        guard let timestamp = timestamp else { return lastUnreadMissedCallDate = nil }

        if timestamp > lastUnreadMissedCallDate {
            lastUnreadMissedCallDate = timestamp
        }
    }

    // MARK: - Update timestamps on messages events

    /// Update timetamps after an message has been updated or created from an update event
    @objc
    func updateTimestampsAfterUpdatingMessage(_ message: ZMMessage) {
        guard let timestamp = message.serverTimestamp else { return }

        updateServerModified(timestamp)

        if message.shouldGenerateUnreadCount() {
            updateLastModified(timestamp)
        }

        if let sender = message.sender, sender.isSelfUser {
            // if the message was sent by the self user we don't want to send a lastRead event, since we consider this message to be already read
            updateLastRead(timestamp, synchronize: false)
        }

        self.needsToCalculateUnreadMessages = true
    }

    /// Update timetamps after an message has been inserted locally by the self user
    @objc
    func updateTimestampsAfterInsertingMessage(_ message: ZMMessage) {
        guard let timestamp = message.serverTimestamp else { return }

        if message.shouldGenerateUnreadCount() {
            updateLastModified(timestamp)
        }

        calculateLastUnreadMessages()
    }

    /// Update timetamps after an message has been deleted
    @objc
    func updateTimestampsAfterDeletingMessage() {
        // If an unread message is deleted we must re-calculate the unread messages.
        calculateLastUnreadMessages()
    }

    // MARK: - Mark as read

    /// Mark all messages in the conversation as read
    @objc
    public func markAsRead() {
        guard let timestamp = lastServerTimeStamp else { return }

        enqueueMarkAsReadUpdate(timestamp)
        savePendingLastRead()
    }

    /// Mark messages up until the given message as read
    @objc(markMessagesAsReadUntil:)
    public func markMessagesAsRead(until message: ZMConversationMessage) {
        guard let messageTimestamp = message.serverTimestampIncludingChildMessages else { return }

        if let currentTimestamp = lastReadServerTimeStamp,
            currentTimestamp.compare(messageTimestamp) == .orderedDescending {
            // Current last read timestamp is newer than message we are marking as read
            return
        }

        // Any unsent unread message is cleared when entering a conversation
        if hasUnreadUnsentMessage {
            hasUnreadUnsentMessage = false
        }

        guard let unreadTimestamp = message.isSent ? messageTimestamp : unreadMessagesIncludingInvisible(until: messageTimestamp).last?.serverTimestamp else { return }

        enqueueMarkAsReadUpdate(unreadTimestamp)
    }

    /// Enqueue an mark-as-read update.
    ///
    /// - parameter timestamp: Point in time from which all older messages should be considered read.
    ///
    /// This method only has an effect when called from the UI context and it's throttled so it's fine to call it repeatedly.

    fileprivate func enqueueMarkAsReadUpdate(_ timestamp: Date) {
        guard let managedObjectContext = managedObjectContext, managedObjectContext.zm_isUserInterfaceContext else { return }

        updatePendingLastRead(timestamp)

        lastReadTimestampUpdateCounter += 1
        let currentCount: Int64 = lastReadTimestampUpdateCounter
        let groups = managedObjectContext.enterAllGroups()

        DispatchQueue.main.asyncAfter(deadline: .now() + lastReadTimestampSaveDelay) { [weak self] in
            guard currentCount == self?.lastReadTimestampUpdateCounter else { return managedObjectContext.leaveAllGroups(groups) }
            self?.savePendingLastRead()
            managedObjectContext.leaveAllGroups(groups)
        }
    }

    /// Perform the an mark-as-read update by updating the last-read timestamp and
    /// create read confirmations for the newly read messages.
    ///
    /// - Parameters:
    ///     - range: The range of time in which all messages should be considered read.
    ///
    /// This method can only be run from the UI context but the actual work will happen
    /// on the sync context since that's the context where we update timestamps.

    fileprivate func performMarkAsReadUpdate(in range: ClosedRange<Date>) {
        guard
            managedObjectContext?.zm_isUserInterfaceContext == true,
            let syncMOC = managedObjectContext?.zm_sync
        else {
            return
        }

        let objectID = self.objectID

        syncMOC.performGroupedBlock {
            let conversation = syncMOC.object(with: objectID) as? ZMConversation
            conversation?.confirmUnreadMessagesAsRead(in: range)
            conversation?.updateLastRead(range.upperBound, synchronize: true)
            syncMOC.saveOrRollback()
        }
    }

    /// Triggers the mark-as-read update.

    @objc
    public func savePendingLastRead() {
        guard let upperBound = pendingLastReadServerTimestamp else { return }
        let lowerBound = previousLastReadServerTimestamp ?? lastReadServerTimeStamp ?? .distantPast
        performMarkAsReadUpdate(in: lowerBound...upperBound)
        pendingLastReadServerTimestamp = nil
        previousLastReadServerTimestamp = nil
        lastReadTimestampUpdateCounter = 0
    }

    /// Calculates the the last unread knock, missed call and total unread unread count. This should be re-calculated
    /// when the last read timetamp changes or a message is inserted / deleted.

    @objc
    func calculateLastUnreadMessages() {
        // We only calculate unread message on the sync MOC
        guard let managedObjectContext = managedObjectContext, managedObjectContext.zm_isSyncContext else { return }

        let messages = unreadMessages()
        var lastKnockDate: Date?
        var lastMissedCallDate: Date?
        var unreadCount: Int64 = 0
        var unreadSelfMentionCount: Int64 = 0
        var unreadSelfReplyCount: Int64 = 0

        for message in messages {
            if message.isKnock {
                lastKnockDate = message.serverTimestamp
            }

            if message.isSystem, let systemMessage = message as? ZMSystemMessage, systemMessage.systemMessageType == .missedCall {
                lastMissedCallDate = message.serverTimestamp
            }

            if let textMessageData = message.textMessageData {
                if textMessageData.isMentioningSelf {
                    unreadSelfMentionCount += 1
                }
                if textMessageData.isQuotingSelf {
                    unreadSelfReplyCount += 1
                }
            }

            if message.shouldGenerateUnreadCount() {
                unreadCount += 1
            }
        }

        updateLastUnreadKnock(lastKnockDate)
        updateLastUnreadMissedCall(lastMissedCallDate)
        internalEstimatedUnreadCount = unreadCount
        internalEstimatedUnreadSelfMentionCount = unreadSelfMentionCount
        internalEstimatedUnreadSelfReplyCount = unreadSelfReplyCount
        needsToCalculateUnreadMessages = false
    }

    /// Returns the first unread message in a converation. If the first unread message is child message
    /// of system message the parent message will be returned.

    @objc
    public var firstUnreadMessage: ZMConversationMessage? {
        let replaceChildWithParent: (ZMMessage) -> ZMMessage = { message in
            if let systemMessage = message as? ZMSystemMessage, let parentMessage = systemMessage.parentMessage as? ZMMessage {
                return parentMessage
            } else {
                return message
            }
        }

        return unreadMessagesIncludingInvisible().lazy
            .map(replaceChildWithParent)
            .filter { $0.visibleInConversation != nil }
            .first { $0.shouldGenerateUnreadCount() }
    }

    /// Returns first unread message mentioning the self user.

    public var firstUnreadMessageMentioningSelf: ZMConversationMessage? {
        return unreadMessages.first(where: { $0.textMessageData?.isMentioningSelf ?? false })
    }

    /// Returns all unread messages. This may contain unread child messages of a system message
    /// which aren't directly visible in the conversation.

    @objc
    public var unreadMessages: [ZMConversationMessage] {
        return unreadMessages()
    }

    internal func unreadMessages(until timestamp: Date = .distantFuture) -> [ZMMessage] {
        return unreadMessagesIncludingInvisible(until: timestamp).filter(ZMMessage.isVisible)
    }

    internal func unreadMessagesIncludingInvisible(until timestamp: Date = .distantFuture) -> [ZMMessage] {
        let range = (lastReadServerTimeStamp ?? .distantPast)...timestamp
        return unreadMessagesIncludingInvisible(in: range)
    }

    internal func unreadMessages(in range: ClosedRange<Date>) -> [ZMMessage] {
        return unreadMessagesIncludingInvisible(in: range).filter(ZMMessage.isVisible)
    }

    internal func unreadMessagesIncludingInvisible(in range: ClosedRange<Date>) -> [ZMMessage] {
        guard let managedObjectContext = managedObjectContext else { return [] }

        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = NSPredicate(format: "(%K == %@ OR %K == %@) AND %K != %@ AND %K > %@ AND %K <= %@",
                                             ZMMessageConversationKey, self,
                                             ZMMessageHiddenInConversationKey, self,
                                             ZMMessageSenderKey, selfUser,
                                             ZMMessageServerTimestampKey, range.lowerBound as NSDate,
                                             ZMMessageServerTimestampKey, range.upperBound as NSDate)

        fetchRequest.sortDescriptors = ZMMessage.defaultSortDescriptors()

        return managedObjectContext.fetchOrAssert(request: fetchRequest).filter { $0.shouldGenerateUnreadCount() }
    }
}
