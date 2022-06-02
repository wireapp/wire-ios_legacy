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

import WireDataModel

let IsTypingKey = "isTyping"

let StatusKey = "status"
let StoppedKey = "stopped"
let StartedKey = "started"

@objc extension ZMConversation {

    // Used for handling remote notifications
    public static let typingNotificationName = Notification.Name(rawValue: "ZMTypingNotification")

    // Used for handling local notifications
    public static let typingChangeNotificationName = Notification.Name(rawValue: "ZMTypingChangeNotification")

}

public struct TypingEvent {

    let date: Date
    let objectID: NSManagedObjectID
    let isTyping: Bool

    static func typingEvent(with objectID: NSManagedObjectID,
                            isTyping: Bool,
                            ifDifferentFrom other: TypingEvent?) -> TypingEvent? {
        let newEvent = TypingEvent(date: Date(), objectID: objectID, isTyping: isTyping)
        if let other = other, newEvent.isEqual(other: other) {
            return nil
        }
        return newEvent
    }

    func isEqual(other: TypingEvent) -> Bool {
        return isTyping == other.isTyping &&
               objectID.isEqual(other.objectID) &&
               fabs(date.timeIntervalSince(other.date)) < Typing.defaultTimeout
    }

}

class TypingEventQueue {

    /// conversations with their current isTyping state
    var conversations: [NSManagedObjectID: Bool] = [:]

    /// conversations that started typing, but never ended
    var unbalancedConversations: Set<NSManagedObjectID> = Set()

    /// last event that has been requested
    var lastSentTypingEvent: TypingEvent?

    /// Adds the conversation to the "queue"
    /// If `isTyping` is true, it turns all other conversation events to endTyping events
    func addItem(conversationID: NSManagedObjectID, isTyping: Bool) {
        if isTyping {
            // end all previous typings
            conversations.forEach {
                conversations[$0.key] = false
            }
            unbalancedConversations.forEach {
                conversations[$0] = false
            }
            unbalancedConversations.insert(conversationID)
        } else {
            unbalancedConversations.remove(conversationID)
        }
        conversations[conversationID] = isTyping
    }

    /// Returns the next typing event that is different from the last sent typing event
    func nextEvent() -> TypingEvent? {
        var event: TypingEvent?

        while event == nil, let (convObjectID, isTyping) = conversations.popFirst() {
            event = TypingEvent.typingEvent(with: convObjectID, isTyping: isTyping, ifDifferentFrom: lastSentTypingEvent)
        }
        if let anEvent = event {
            lastSentTypingEvent = anEvent
        }
        return event
    }

    func clear(conversationID: NSManagedObjectID) {
        conversations.removeValue(forKey: conversationID)
    }
}

public class TypingStrategy: AbstractRequestStrategy, TearDownCapable, ZMEventConsumer {

    fileprivate var typing: Typing!
    fileprivate let typingEventQueue = TypingEventQueue()
    fileprivate var tornDown: Bool = false
    fileprivate var observers: [Any] = []

    @available (*, unavailable)
    override init(withManagedObjectContext moc: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        fatalError()
    }

    public convenience init(applicationStatus: ApplicationStatus, managedObjectContext: NSManagedObjectContext) {
        self.init(applicationStatus: applicationStatus, syncContext: managedObjectContext, uiContext: managedObjectContext.zm_userInterface, typing: nil)
    }

    init(applicationStatus: ApplicationStatus, syncContext: NSManagedObjectContext, uiContext: NSManagedObjectContext, typing: Typing?) {
        self.typing = typing ?? Typing(uiContext: uiContext, syncContext: syncContext)
        super.init(withManagedObjectContext: syncContext, applicationStatus: applicationStatus)
        self.configuration = [
            .allowsRequestsWhileInBackground,
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsWhileWaitingForWebsocket
        ]

        observers.append(
            NotificationInContext.addObserver(name: ZMConversation.typingNotificationName,
                                              context: self.managedObjectContext.notificationContext,
                                              using: { [weak self] in self?.addConversationForNextRequest(note: $0)})
            )

        observers.append(
            NotificationInContext.addObserver(name: ZMConversation.typingChangeNotificationName,
                                              context: self.managedObjectContext.notificationContext,
                                              using: { [weak self] in self?.addConversationForNextRequest(note: $0)})
        )

        observers.append(
            NotificationInContext.addObserver(name: ZMConversation.clearTypingNotificationName,
                                              context: self.managedObjectContext.notificationContext,
                                              using: { [weak self] in self?.shouldClearTypingForConversation(note: $0)})
        )
    }

    deinit {
        assert(tornDown, "Need to tearDown TypingStrategy")
    }

    @objc fileprivate func addConversationForNextRequest(note: NotificationInContext) {
        guard let conversation = note.object as? ZMConversation, conversation.remoteIdentifier != nil
        else { return }

        if let isTyping = (note.userInfo[IsTypingKey] as? NSNumber)?.boolValue {
            add(conversation: conversation, isTyping: isTyping, clearIsTyping: false)
        }
    }

    @objc fileprivate func shouldClearTypingForConversation(note: NotificationInContext) {
        guard let conversation = note.object as? ZMConversation, conversation.remoteIdentifier != nil
        else { return }

        add(conversation: conversation, isTyping: false, clearIsTyping: true)
    }

    fileprivate func add(conversation: ZMConversation, isTyping: Bool, clearIsTyping: Bool) {
        guard conversation.remoteIdentifier != nil
        else { return }

        managedObjectContext.performGroupedBlock {
            if clearIsTyping {
                self.typingEventQueue.clear(conversationID: conversation.objectID)
                self.typingEventQueue.lastSentTypingEvent = nil
            } else {
                self.typingEventQueue.addItem(conversationID: conversation.objectID, isTyping: isTyping)
                RequestAvailableNotification.notifyNewRequestsAvailable(self)
            }
        }
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let typingEvent = typingEventQueue.nextEvent(),
              let conversation = managedObjectContext.object(with: typingEvent.objectID) as? ZMConversation,
              let remoteIdentifier = conversation.remoteIdentifier
        else { return nil }

        let path = "/conversations/\(remoteIdentifier.transportString())/typing"
        let payload = [StatusKey: typingEvent.isTyping ? StartedKey : StoppedKey]
        let request = ZMTransportRequest(path: path, method: .methodPOST, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
        request.setDebugInformationTranscoder(self)

        return request
    }

    // MARK: - TearDownCapable

    public func tearDown() {
        typing.tearDown()
        typing = nil
        tornDown = true
        observers = []
    }

    // MARK: - ZMEventConsumer

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        guard liveEvents else { return }

        events.forEach {process(event: $0, conversationsByID: prefetchResult?.conversationsByRemoteIdentifier)}
    }

    func process(event: ZMUpdateEvent, conversationsByID: [UUID: ZMConversation]?) {
        guard
            event.type == .conversationTyping ||
                event.type == .conversationOtrMessageAdd ||
                event.type == .conversationMemberLeave
            else { return }

        guard let userID = event.senderUUID,
              let conversationID = event.conversationUUID
        else { return }

        let user = ZMUser.fetchOrCreate(with: userID, domain: event.senderDomain, in: managedObjectContext)
        let conversation = conversationsByID?[conversationID] ?? ZMConversation.fetchOrCreate(with: conversationID, domain: event.conversationDomain, in: managedObjectContext)

        if event.type == .conversationTyping {
            guard let payloadData = event.payload["data"] as? [String: String],
                let status = payloadData[StatusKey]
                else { return }
            processIsTypingUpdateEvent(for: user, in: conversation, with: status)
        } else if event.type == .conversationOtrMessageAdd {
            if let message = GenericMessage(from: event), message.hasText
                || message.hasEdited {
                typing.setIsTyping(false, for: user, in: conversation)
            }
        } else if event.type == .conversationMemberLeave {
            let users = event.users(in: managedObjectContext, createIfNeeded: false)
            users.forEach { user in
                typing.setIsTyping(false, for: user, in: conversation)
            }
        }
    }

    func processIsTypingUpdateEvent(for user: ZMUser, in conversation: ZMConversation, with status: String) {
        let startedTyping = (status == StartedKey)
        let stoppedTyping = (status == StoppedKey)
        if startedTyping || stoppedTyping {
            typing.setIsTyping(startedTyping, for: user, in: conversation)
        }
    }
}

extension TypingStrategy {

    public static func notifyTranscoderThatUser(isTyping: Bool, in conversation: ZMConversation) {
        let userInfo = [IsTypingKey: NSNumber(value: isTyping)]
        NotificationInContext(
            name: ZMConversation.typingChangeNotificationName,
            context: conversation.managedObjectContext!.notificationContext,
            object: conversation,
            userInfo: userInfo)
        .post()
    }

    public static func clearTranscoderStateForTyping(in conversation: ZMConversation) {
        NotificationInContext(
            name: ZMConversation.clearTypingNotificationName,
            context: conversation.managedObjectContext!.notificationContext,
            object: conversation,
            userInfo: nil)
            .post()
    }
}
