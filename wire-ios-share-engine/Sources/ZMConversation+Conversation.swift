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
import WireDataModel
import WireRequestStrategy
import WireUtilities

extension ZMConversation: Conversation {

    private static let logger = ZMSLog(tag: "Message Processing")

    public var name: String { return displayName }

    public func appendTextMessage(_ message: String, fetchLinkPreview: Bool) -> Sendable? {
        do {
            return try appendText(content: message, fetchLinkPreview: fetchLinkPreview) as? Sendable
        } catch {
            Self.logger.warn("Failed to append text message from Share Ext. Reason: \(error.localizedDescription)")
            return nil
        }
    }

    public func appendImage(_ data: Data) -> Sendable? {
        do {
            return try appendImage(from: data) as? Sendable
        } catch {
            Self.logger.warn("Failed to append image message from Share Ext. Reason: \(error.localizedDescription)")
            return nil
        }
    }

    public func appendFile(_ metadata: ZMFileMetadata) -> Sendable? {
        do {
            return try appendFile(with: metadata) as? Sendable
        } catch {
            Self.logger.warn("Failed to append file message from Share Ext. Reason: \(error.localizedDescription)")
            return nil
        }
    }

    public func appendLocation(_ location: LocationData) -> Sendable? {
        do {
            return try appendLocation(with: location) as? Sendable
        } catch {
            Self.logger.warn("Failed to append location message from Share Ext. Reason: \(error.localizedDescription)")
            return nil
        }
    }

    /// Adds an observer for when the conversation verification status degrades
    public func add(conversationVerificationDegradedObserver: @escaping (ConversationDegradationInfo) -> Void) -> TearDownCapable {
        return DegradationObserver(conversation: self, callback: conversationVerificationDegradedObserver)
    }
}

public struct ConversationDegradationInfo {

    public let conversation: Conversation
    public let users: Set<ZMUser>

    public init(conversation: Conversation, users: Set<ZMUser>) {
        self.users = users
        self.conversation = conversation
    }
}

final class DegradationObserver: NSObject, ZMConversationObserver, TearDownCapable {

    let callback: (ConversationDegradationInfo) -> Void
    let conversation: ZMConversation
    private var observer: Any?

    init(conversation: ZMConversation, callback: @escaping (ConversationDegradationInfo) -> Void) {
        self.callback = callback
        self.conversation = conversation
        super.init()
        self.observer = NotificationCenter.default.addObserver(forName: contextWasMergedNotification, object: nil, queue: nil) { [weak self] _ in
                                                DispatchQueue.main.async {
                                                    self?.processSaveNotification()
                                                }
        }
    }

    deinit {
        tearDown()
    }

    func tearDown() {
        if let observer = self.observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    private func processSaveNotification() {
        if !self.conversation.messagesThatCausedSecurityLevelDegradation.isEmpty {
            let untrustedUsers = self.conversation.localParticipants.filter {
                $0.clients.first { !$0.verified } != nil
            }

            self.callback(ConversationDegradationInfo(conversation: self.conversation,
                                                      users: untrustedUsers)
            )
        }
    }

    func conversationDidChange(_ note: ConversationChangeInfo) {
        if note.causedByConversationPrivacyChange {
            self.callback(ConversationDegradationInfo(conversation: note.conversation,
                                                      users: Set(note.usersThatCausedConversationToDegrade)))
        }
    }
}
