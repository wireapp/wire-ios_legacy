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

import Foundation

// Describes the icon to be shown for the conversation in the list.
internal enum ConversationStatusIcon {
    case none
    case pendingConnection
    
    case typing
    
    case unreadMessages(count: Int)
    case unreadPing
    case missedCall
    
    case silenced
    
    case playingMedia
    
    case activeCall(joined: Bool)
}

// Describes the status of the conversation.
internal struct ConversationStatus {
    let isGroup: Bool
    
    let hasMessages: Bool
    let hasUnsentMessages: Bool
    
    let unreadMessages: [ZMConversationMessage]
    let unreadMessagesByType: [StatusMessageType: UInt]
    let isTyping: Bool
    let isSilenced: Bool
    let isOngoingCall: Bool
    let isBlocked: Bool
}

// Describes the conversation message.
internal enum StatusMessageType: Int {
    case text
    case link
    case image
    case location
    case audio
    case video
    case file
    case knock
    case addParticipants
    case removeParticipants
    case missedCall
}

extension StatusMessageType {
    init?(message: ZMConversationMessage) {
        if message.isText, let textMessage = message.textMessageData {
            if let _ = textMessage.linkPreview {
                self = .link
            }
            else {
                self = .text
            }
        }
        else if message.isImage {
            self = .image
        }
        else if message.isLocation {
            self = .location
        }
        else if message.isAudio {
            self = .audio
        }
        else if message.isVideo {
            self = .video
        }
        else if message.isFile {
            self = .file
        }
        else if message.isKnock {
            self = .knock
        }
        else if message.isSystem, let system = message.systemMessageData {
            if system.systemMessageType == .participantsAdded {
                self = .addParticipants
            }
            if system.systemMessageType == .participantsRemoved {
                self = .removeParticipants
            }
            else if system.systemMessageType == .missedCall {
                self = .missedCall
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
}

// Describes object that is able to match and describe the conversation.
// Provides rich description and status icon.
internal protocol ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString?
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon
    
    // An array of matchers that are compatible with the current one. Leads to display the description of all matching 
    // in one row, like "description1 | description2"
    var combinesWith: [ConversationStatusMatcher] { get }
}

extension ConversationStatusMatcher {
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        return .none
    }
}

extension ConversationStatusMatcher {
    static func regularStyle() -> [String: AnyObject] {
        return [NSFontAttributeName: FontSpec(.small, .light).font!]
    }
    
    static func emphasisStyle() -> [String: AnyObject] {
        return [NSFontAttributeName: FontSpec(.small, .medium).font!]
    }
}

// Accessors for ObjC
extension ZMConversation {
    static func statusRegularStyle() -> [String: AnyObject] {
        return BlockedMatcher.regularStyle()
    }
    
    static func statusEmphasisStyle() -> [String: AnyObject] {
        return BlockedMatcher.emphasisStyle()
    }
}

// "Blocked"
final internal class BlockedMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.isBlocked
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        return "conversation.status.blocked".localized && type(of: self).regularStyle()
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// "Active Call"
final internal class CallingMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.isOngoingCall
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        return "conversation.status.call".localized && type(of: self).regularStyle()
    }
    
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        let state = conversation.voiceChannel?.state ?? .noActiveUsers
        switch state {
        case .selfConnectedToActiveChannel:
            return .activeCall(joined: true)
        default:
            return .activeCall(joined: false)
        }
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// "A, B, C: typing a message..."
final internal class TypingMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.isTyping
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        let statusString: String
        if status.isGroup, let typingUsers = conversation.typingUsers() {
            let typingUsersString = typingUsers.flatMap { $0 as? ZMUser }.map { $0.displayName(in: conversation) }.joined(separator: ", ")
            statusString = String(format: "conversation.status.typing.group".localized, typingUsersString)
        }
        else {
            statusString = "conversation.status.typing".localized
        }
        return statusString && type(of: self).regularStyle()
    }
    
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        return .typing
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// "Silenced"
final internal class SilencedMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.isSilenced
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        return .none
    }
    
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        return .silenced
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// In silenced "N (text|image|link|...) message, ..."
// In not silenced: "[Sender:] <message text>"
final internal class NewMessagesMatcher: ConversationStatusMatcher {
    let matchedTypes: [StatusMessageType] = [.text, .link, .image, .location, .audio, .video, .file, .knock, .missedCall]
    let localizationSilencedRootPath = "conversation.silenced.status.message"
    let localizationRootPath = "conversation.status.message"

    let matchedTypesDescriptions: [StatusMessageType: String] = [
        .text:     "text",
        .link:     "link",
        .image:    "image",
        .location: "location",
        .audio:    "audio",
        .video:    "video",
        .file:     "file",
        .knock:    "knock",
        .missedCall: "missedcall"
    ]
    
    func isMatching(with status: ConversationStatus) -> Bool {
        return matchedTypes.flatMap { status.unreadMessagesByType[$0] }.reduce(0, +) > 0
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        if status.isSilenced {
            let resultString = matchedTypes.filter { status.unreadMessagesByType[$0] > 0 }.flatMap {
                guard let localizationKey = matchedTypesDescriptions[$0] else {
                    return .none
                }
                
                return String(format: (localizationSilencedRootPath + "." + localizationKey).localized, status.unreadMessagesByType[$0] ?? 0)
                }.joined(separator: ", ")
            
            return resultString && type(of: self).regularStyle()
        }
        else {
            guard let message = status.unreadMessages.last,
                    let sender = message.sender,
                    let type = StatusMessageType(message: message),
                    let localizationKey = matchedTypesDescriptions[type] else {
                return "" && type(of: self).regularStyle()
            }
            
            let messageDescription = String(format: (localizationRootPath + "." + localizationKey).localized, message.textMessageData?.messageText ?? "")
            
            if status.isGroup {
                return ((sender.displayName(in: conversation) + ": ") && type(of: self).emphasisStyle()) +
                        (messageDescription && type(of: self).regularStyle())
            }
            else {
                return messageDescription && type(of: self).regularStyle()
            }
        }
    }
    
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        guard let last = status.unreadMessages.last, let type = StatusMessageType(message: last) else {
            return .none
        }
        
        switch type {
        case .knock:
            return .unreadPing
        case .missedCall:
            return .missedCall
        default:
            if status.unreadMessages.count == 1 {
                return .none
            }
            else {
                return .unreadMessages(count: status.unreadMessages.count)
            }
        }
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// ! Failed to send
final internal class FailedSendMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.hasUnsentMessages
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        return "conversation.status.unsent".localized && type(of: self).regularStyle()
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// "[You|User] [added|removed|left] [_|users|you]"
final internal class GroupActivityMatcher: ConversationStatusMatcher {
    let matchedTypes: [StatusMessageType] = [.addParticipants, .removeParticipants]

    func isMatching(with status: ConversationStatus) -> Bool {
        return matchedTypes.flatMap { status.unreadMessagesByType[$0] }.reduce(0, +) > 0
    }
    
    private func addedString(for messages: [ZMConversationMessage], in conversation: ZMConversation) -> String? {
        if messages.count > 0 {
            return "conversation.status.added_multiple".localized
        }
        else if let message = messages.last, let systemMessage = message.systemMessageData {
            if systemMessage.addedUsers.contains(where: { $0.isSelfUser }) {
                return "conversation.status.you_was_added".localized
            }
            else {
                let usersList = systemMessage.addedUsers.map { $0.displayName(in: conversation) }.joined(separator: ", ")
                return String(format: "conversation.status.added_useres".localized, usersList)
            }
        }
        return .none
    }
    
    private func removedString(for messages: [ZMConversationMessage], in conversation: ZMConversation) -> String? {
        if messages.count > 0 {
            return "conversation.status.removed_multiple".localized
        }
        else if let message = messages.last, let systemMessage = message.systemMessageData {
            if systemMessage.addedUsers.contains(where: { $0.isSelfUser }) {
                if message.sender?.isSelfUser ?? false {
                    return "conversation.status.you_left".localized
                }
                else {
                    return "conversation.status.you_were_removed".localized
                }
            }
            else {
                let usersList = systemMessage.addedUsers.map { $0.displayName(in: conversation) }.joined(separator: ", ")
                return String(format: "conversation.status.removed_useres".localized, usersList)
            }
        }
        return .none
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        var allStatusMessagesByType: [StatusMessageType: [ZMConversationMessage]] = [:]
        
        self.matchedTypes.forEach { type in
            allStatusMessagesByType[type] = status.unreadMessages.filter {
                StatusMessageType(message: $0) == type
            }
        }
        
        let resultString = [addedString(for: allStatusMessagesByType[.addParticipants] ?? [], in: conversation),
                            removedString(for: allStatusMessagesByType[.removeParticipants] ?? [], in: conversation)].flatMap { $0 }.joined(separator: "; ")
        return resultString && type(of: self).regularStyle()
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// Fallback for empty conversations: showing the handle.
final internal class UnsernameMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return !status.hasMessages
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        guard let connectedUser = conversation.connectedUser,
                let handle = connectedUser.handle else {
            return .none
        }
        
        return "@" + handle && type(of: self).regularStyle()
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

/*
 Matchers priorities (highest first):
 
 (Blocked)
 (Calling)
 (Typing)
 (Silenced)
 (New message / call)
 (Unsent message combines with (Group activity), (New message / call), (Silenced))
 (Group activity)
 (Username)
 */
private var allMatchers: [ConversationStatusMatcher] = {
    let silencedMatcher = SilencedMatcher()
    let newMessageMatcher = NewMessagesMatcher()
    let groupActivityMatcher = SilencedMatcher()
    
    let failedSendMatcher = FailedSendMatcher()
    failedSendMatcher.combinesWith = [silencedMatcher, newMessageMatcher, groupActivityMatcher]
    
    return [BlockedMatcher(), CallingMatcher(), TypingMatcher(), silencedMatcher, newMessageMatcher, failedSendMatcher, groupActivityMatcher, UnsernameMatcher()]
}()

extension ConversationStatus {
    func appliedMatchersForDescription(for conversation: ZMConversation) -> [ConversationStatusMatcher] {
        guard let topMatcher = allMatchers.first(where: { $0.isMatching(with: self) && $0.description(with: self, conversation: conversation) != .none }) else {
            return []
        }
        
        return [topMatcher] + topMatcher.combinesWith.filter { $0.isMatching(with: self) && $0.description(with: self, conversation: conversation) != .none }
    }
    
    func appliedMatcherForIcon(for conversation: ZMConversation) -> ConversationStatusMatcher? {
        for matcher in allMatchers.filter({ $0.isMatching(with: self) }) {
            let icon = matcher.icon(with: self, conversation: conversation)
            switch icon {
            case .none:
                break
            default:
                return matcher
            }
        }
        
        return .none
    }
    
    internal func description(for conversation: ZMConversation) -> NSAttributedString {
        let allMatchers = self.appliedMatchersForDescription(for: conversation)
        guard allMatchers.count > 0 else {
            return "" && [:]
        }
        let allStrings = allMatchers.flatMap { $0.description(with: self, conversation: conversation) }
        return allStrings.joined(separator: " | " && CallingMatcher.regularStyle())
    }
    
    internal func icon(for conversation: ZMConversation) -> ConversationStatusIcon {
        guard let topMatcher = self.appliedMatcherForIcon(for: conversation) else {
            return .none
        }
        
        return topMatcher.icon(with: self, conversation: conversation)
    }
}

extension ZMConversation {
    private var unreadMessages: [ZMConversationMessage] {
        let lastReadIndex: Int
        
        if let lastMessage = self.lastReadMessage {
            lastReadIndex = self.messages.index(of: lastMessage)
            guard lastReadIndex != NSNotFound else {
                return []
            }
        }
        else {
            lastReadIndex = -1
        }
        
        let unreadIndexSet = IndexSet((lastReadIndex + 1)..<self.messages.count)
        return self.messages.objects(at: unreadIndexSet).flatMap {
                $0 as? ZMConversationMessage
            }.filter {
                !($0.sender?.isSelfUser ?? true)
            }
    }
    
    private var unreadMessagesTypes: [StatusMessageType] {
        return unreadMessages.flatMap { StatusMessageType(message: $0) }
    }
    
    internal var status: ConversationStatus {
        let isBlocked = self.conversationType == .oneOnOne ? (self.firstActiveParticipantOtherThanSelf()?.isBlocked ?? false) : false
        
        let unreadMessages = self.unreadMessages
        let unreadMessagesByType = { () -> [StatusMessageType : UInt] in 
            var unreadMessagesByType = [StatusMessageType: UInt]()
            
            StatusMessageType.allValues.forEach { type in
                let total = self.unreadMessagesTypes.filter {
                        $0 == type
                    }.count
                
                if total != 0 {
                    unreadMessagesByType[type] = UInt(total)
                }
            }
            return unreadMessagesByType
        }()
        
        
        let hasMessages: Bool
        
        if self.messages.count < 10 {
            hasMessages = self.messages.flatMap {
                StatusMessageType(message: $0 as! ZMConversationMessage)
            }.count > 0
        }
        else {
            hasMessages = true
        }
        
        let isOngoingCall: Bool = (self.voiceChannel?.state ?? .noActiveUsers) != .noActiveUsers
        
        return ConversationStatus(isGroup: self.conversationType == .group,
                                  hasMessages: hasMessages,
                                  hasUnsentMessages: self.hasUnreadUnsentMessage,
                                  unreadMessages: unreadMessages,
                                  unreadMessagesByType: unreadMessagesByType,
                                  isTyping: self.typingUsers().count > 0,
                                  isSilenced: self.isSilenced,
                                  isOngoingCall: isOngoingCall,
                                  isBlocked: isBlocked)
    }
}

