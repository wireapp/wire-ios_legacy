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
enum ConversationStatusIcon: Equatable {
    case none
    case pendingConnection
    
    case typing
    
    case unreadMessages(count: Int)
    case unreadPing
    case missedCall
    case mention
    case reply

    case silenced
    
    case playingMedia
    
    case activeCall(showJoin: Bool)
}

// Describes the status of the conversation.
struct ConversationStatus {
    let isGroup: Bool
    
    let hasMessages: Bool
    let hasUnsentMessages: Bool
    
    let messagesRequiringAttention: [ZMConversationMessage]
    let messagesRequiringAttentionByType: [StatusMessageType: UInt]
    let isTyping: Bool
    let mutedMessageTypes: MutedMessageTypes
    let isOngoingCall: Bool
    let isBlocked: Bool
    let isSelfAnActiveMember: Bool
    let hasSelfMention: Bool
    let hasSelfReply: Bool
}

// Describes the conversation message.
enum StatusMessageType: Int {
    case mention
    case reply
    case missedCall
    case knock
    case text
    case link
    case image
    case location
    case audio
    case video
    case file
    case addParticipants
    case removeParticipants
    case newConversation
}

extension StatusMessageType {
    /// Types of statuses that can be included in a status summary.
    static let summaryTypes: [StatusMessageType] = [.mention, .reply, .missedCall, .knock, .text, .link, .image, .location, .audio, .video, .file]

    var parentSummaryType: StatusMessageType? {
        switch self {
        case .link, .image, .location, .audio, .video, .file: return .text
        default: return nil
        }
    }

    private static let conversationSystemMessageTypeToStatusMessageType: [ZMSystemMessageType: StatusMessageType] = [
        .participantsAdded:   .addParticipants,
        .participantsRemoved: .removeParticipants,
        .missedCall:          .missedCall,
        .newConversation:     .newConversation
    ]
    
    init?(message: ZMConversationMessage) {
        
        if message.isText, let textMessage = message.textMessageData {
            if textMessage.isMentioningSelf {
                self = .mention
            }
            else if textMessage.isQuotingSelf {
                self = .reply
            }
            else if let _ = textMessage.linkPreview {
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
            if let statusMessageType = StatusMessageType.conversationSystemMessageTypeToStatusMessageType[system.systemMessageType] {
                self = statusMessageType
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
protocol ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString?
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon
    
    // An array of matchers that are compatible with the current one. Leads to display the description of all matching 
    // in one row, like "description1 | description2"
    var combinesWith: [ConversationStatusMatcher] { get }
}

protocol TypedConversationStatusMatcher: ConversationStatusMatcher {
    var matchedTypes: [StatusMessageType] { get }
}

extension TypedConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        let matches: [UInt] = matchedTypes.compactMap { status.messagesRequiringAttentionByType[$0] }
        return matches.reduce(0, +) > 0
    }
}

extension ConversationStatusMatcher {
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        return .none
    }
    
    func addEmphasis(to string: NSAttributedString, for substring: String) -> NSAttributedString {
        return string.setAttributes(type(of: self).emphasisStyle, toSubstring: substring)
    }
}


final class ContentSizeCategoryUpdater {
    private let callback: () -> ()
    private var observer: NSObjectProtocol!
    
    deinit {
        NotificationCenter.default.removeObserver(observer)
    }
    
    init(callback: @escaping () -> ()) {
        self.callback = callback
        callback()
        self.observer = NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification,
                                                               object: nil,
                                                               queue: nil) { [weak self] _ in
                                                                self?.callback()
        }
    }
}

final class ConversationStatusStyle {
    private(set) var regularStyle: [NSAttributedString.Key: AnyObject] = [:]
    private(set) var emphasisStyle: [NSAttributedString.Key: AnyObject] = [:]
    private var contentSizeStyleUpdater: ContentSizeCategoryUpdater!
    
    init() {
        contentSizeStyleUpdater = ContentSizeCategoryUpdater { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.regularStyle = [.font: FontSpec(.medium, .none).font!,
                                 .foregroundColor: UIColor(white:1.0, alpha:0.64)]
            self.emphasisStyle = [.font: FontSpec(.medium, .medium).font!,
                                  .foregroundColor: UIColor(white:1.0, alpha:0.64)]
        }
    }
}

fileprivate let statusStyle = ConversationStatusStyle()

extension ConversationStatusMatcher {
    static var regularStyle: [NSAttributedString.Key: AnyObject] {
        return statusStyle.regularStyle
    }
    
    static var emphasisStyle: [NSAttributedString.Key: AnyObject] {
        return statusStyle.emphasisStyle
    }
}

// Accessors for ObjC
extension ZMConversation {
    @objc static func statusRegularStyle() -> [NSAttributedString.Key: AnyObject] {
        return statusStyle.regularStyle
    }
    
    @objc static func statusEmphasisStyle() -> [NSAttributedString.Key: AnyObject] {
        return statusStyle.emphasisStyle
    }
}


// "You left"
final internal class SelfUserLeftMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return !status.hasMessages && status.isGroup && !status.isSelfAnActiveMember
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        return "conversation.status.you_left".localized && type(of: self).regularStyle
    }
    
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        return .none
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// "Blocked"
final internal class BlockedMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.isBlocked
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        return "conversation.status.blocked".localized && type(of: self).regularStyle
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// "Active Call"
final internal class CallingMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.isOngoingCall
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        return .none
    }
    
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        return CallingMatcher.icon(for: conversation.voiceChannel?.state, conversation: conversation)
    }
    
    public static func icon(for state: CallState?, conversation: ZMConversation?) -> ConversationStatusIcon {
        
        guard let conversation = conversation, let state = state else {
            return .none
        }
        
        if case CallState.incoming(video: _, shouldRing: false, degraded: _) = state {
            return .activeCall(showJoin: true)
        } else if state.canJoinCall && conversation.mutedMessageTypes != .none {
            return .activeCall(showJoin: true)
        } else if state.isCallOngoing {
            return .activeCall(showJoin: false)
        }
        
        return .none
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// "A, B, C: typing a message..."
final internal class TypingMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.isTyping && status.showingAllMessages
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        let statusString: NSAttributedString
        if status.isGroup, let typingUsers = conversation.typingUsers() {
            let typingUsersString = typingUsers.compactMap { $0 as? ZMUser }.map { $0.displayName(in: conversation) }.joined(separator: ", ")
            let resultString = String(format: "conversation.status.typing.group".localized, typingUsersString)
            let intermediateString = NSAttributedString(string: resultString, attributes: type(of: self).regularStyle)
            statusString = self.addEmphasis(to: intermediateString, for: typingUsersString)
        }
        else {
            statusString = "conversation.status.typing".localized && type(of: self).regularStyle
        }
        return statusString
    }
    
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        return .typing
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// "Silenced"
final internal class SilencedMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return !status.showingAllMessages
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        return .none
    }
    
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        if status.showingOnlyMentionsAndReplies {
            if status.hasSelfMention {
                return .mention
            } else if status.hasSelfReply {
                return .reply
            }
        }

        return .silenced
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}


extension ConversationStatus {

    var showingAllMessages: Bool {
        return mutedMessageTypes == .none
    }

    var showingOnlyMentionsAndReplies: Bool {
        return mutedMessageTypes == .regular
    }

    var completelyMuted: Bool {
        return mutedMessageTypes == .all
    }
        
    var shouldSummarizeMessages: Bool {
        if completelyMuted {
            // Always summarize for completely muted conversation
            return true
        } else if showingOnlyMentionsAndReplies && !hasSelfMention && !hasSelfReply {
            // Summarize when there is no mention
            return true
        } else if hasSelfMention {
            // Summarize if there is at least one mention and another activity that can be inside a summary
            return StatusMessageType.summaryTypes.reduce(into: UInt(0)) { $0 += (messagesRequiringAttentionByType[$1] ?? 0) } > 1
        } else if hasSelfReply {
            // Summarize if there is at least one reply and another activity that can be inside a summary

            let count = StatusMessageType.summaryTypes.reduce(into: UInt(0)) { $0 += (messagesRequiringAttentionByType[$1] ?? 0) }

            // if all activities are replies, do not summarize
            if messagesRequiringAttentionByType[.reply] == count {
                return false
            } else {
                return count > 1
            }
        } else {
            // Never summarize in other cases
            return false
        }
    }
}


// In silenced "N (text|image|link|...) message, ..."
// In not silenced: "[Sender:] <message text>"
// Ephemeral: "Ephemeral message"
final internal class NewMessagesMatcher: TypedConversationStatusMatcher {
    var matchedTypes: [StatusMessageType] {
        return StatusMessageType.summaryTypes
    }

    let localizationSilencedRootPath = "conversation.silenced.status.message"
    let localizationRootPath = "conversation.status.message"

    let matchedSummaryTypesDescriptions: [StatusMessageType: String] = [
        .mention:    "mention",
        .reply:      "reply",
        .missedCall: "missedcall",
        .knock:      "knock",
        .text:       "generic_message"
    ]

    let matchedTypesDescriptions: [StatusMessageType: String] = [
        .mention:    "mention",
        .reply:      "reply",
        .missedCall: "missedcall",
        .knock:      "knock",
        .text:       "text",
        .link:       "link",
        .image:      "image",
        .location:   "location",
        .audio:      "audio",
        .video:      "video",
        .file:       "file"
    ]

    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        if status.shouldSummarizeMessages {
            // Get the count of each category we can summarize, and group them under their parent type
            let flattenedCount: [StatusMessageType: UInt] = matchedTypes
                .reduce(into: [StatusMessageType: UInt]()) {
                    guard let count = status.messagesRequiringAttentionByType[$1], count > 0 else {
                        return
                    }

                    if let parentType = $1.parentSummaryType {
                        $0[parentType, default: 0] += count
                    } else {
                        $0[$1, default: 0] += count
                    }
                }

            // For each top-level summary type, generate the subtitle fragment
            let localizedMatchedItems: [String] = flattenedCount.keys.lazy
                .sorted { $0.rawValue < $1.rawValue }
                .reduce(into: []) {
                    guard let count = flattenedCount[$1], let localizationKey = matchedSummaryTypesDescriptions[$1] else {
                        return
                    }

                    let string = String(format: (localizationSilencedRootPath + "." + localizationKey).localized, count)
                    $0.append(string)
                }

            let resultString = localizedMatchedItems.joined(separator: ", ")
            return resultString.capitalizingFirstLetter() && type(of: self).regularStyle
        }
        else {
            guard let message = status.messagesRequiringAttention.reversed().first(where: {
                    if let _ = $0.sender,
                        let type = StatusMessageType(message: $0),
                        let _ = matchedTypesDescriptions[type],
                        $0.messageIsRelevantForConversationStatus {
                        return true
                    } else {
                        return false
                    }
                }),
                    let sender = message.sender,
                    let type = StatusMessageType(message: message),
                    let localizationKey = matchedTypesDescriptions[type] else {
                return "" && Swift.type(of: self).regularStyle
            }
            
            let messageDescription: String

            if message.isEphemeral {
                var typeSuffix = ".ephemeral"
                if type == .mention {
                    typeSuffix += status.isGroup ? ".mention.group" : ".mention"
                } else if type == .reply {
                    typeSuffix += status.isGroup ? ".reply.group" : ".reply"
                } else if type == .knock {
                    typeSuffix += status.isGroup ? ".knock.group" : ".knock"
                } else if status.isGroup {
                    typeSuffix += ".group"
                }
                messageDescription = (localizationRootPath + typeSuffix).localized
            }
            else {
                var format = localizationRootPath + "." + localizationKey
                
                if status.isGroup && type == .missedCall {
                    format += ".groups"
                    return format.localized(args: sender.displayName(in: conversation)) && Swift.type(of: self).regularStyle
                }
                
                messageDescription = String(format: format.localized, message.textMessageData?.messageText ?? "")
            }
            
            if status.isGroup && !message.isEphemeral {
                return ((sender.displayName(in: conversation) + ": ") && Swift.type(of: self).emphasisStyle) +
                        (messageDescription && Swift.type(of: self).regularStyle)
            }
            else {
                return messageDescription && Swift.type(of: self).regularStyle
            }
        }
    }
    
    func icon(with status: ConversationStatus, conversation: ZMConversation) -> ConversationStatusIcon {
        
        if status.hasSelfMention {
            return .mention
        } else if status.hasSelfReply {
            return .reply
        }

        guard let message = status.messagesRequiringAttention.reversed().first(where: {
                if let _ = $0.sender,
                    let type = StatusMessageType(message: $0),
                     let _ = matchedTypesDescriptions[type],
                     $0.messageIsRelevantForConversationStatus {
                    return true
                }
                else {
                    return false
                }
            }),
            let type = StatusMessageType(message: message) else {
            return .none
        }
        
        switch type {
        case .knock:
            return .unreadPing
        case .missedCall:
            return .missedCall
        default:
            return .unreadMessages(count: status.messagesRequiringAttention.compactMap { StatusMessageType(message: $0) }.filter { matchedTypes.index(of: $0) != .none }.count)
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
        return "conversation.status.unsent".localized && type(of: self).regularStyle
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

extension ZMUser {
    func nameAsSender(in conversation: ZMConversation) -> String {
        if self.isSelfUser {
            return "conversation.status.you".localized
        }
        else {
            return self.displayName(in: conversation)
        }
    }
}

// "[You|User] [added|removed|left] [_|users|you]"
final internal class GroupActivityMatcher: TypedConversationStatusMatcher {
    let matchedTypes: [StatusMessageType] = [.addParticipants, .removeParticipants]
    
    private func addedString(for messages: [ZMConversationMessage], in conversation: ZMConversation) -> NSAttributedString? {
        if messages.count > 1 {
            return "conversation.status.added_multiple".localized && type(of: self).regularStyle
        }
        else if let message = messages.last,
                let systemMessage = message.systemMessageData,
                let sender = message.sender,
                !sender.isSelfUser {
            if systemMessage.users.contains(where: { $0.isSelfUser }) {
                let result = String(format: "conversation.status.you_was_added".localized, sender.displayName(in: conversation)) && type(of: self).regularStyle
                
                return self.addEmphasis(to: result, for: sender.displayName(in: conversation))
            }
            else if systemMessage.userIsTheSender {
                let senderName = sender.nameAsSender(in: conversation)
                let result = "conversation.status.joined".localized(args: senderName) && type(of: self).regularStyle
                return addEmphasis(to: result, for: senderName)
            }
            else {
                let usersList = systemMessage.users.map { $0.displayName(in: conversation) }.joined(separator: ", ")
                
                let result = String(format: "conversation.status.added_users".localized, sender.nameAsSender(in: conversation), usersList) && type(of: self).regularStyle
                
                return self.addEmphasis(to: result, for: sender.nameAsSender(in: conversation))
            }
        }
        return .none
    }
    
    private static let indicate3rdPartiesRemoval: Bool = false
    
    private func removedString(for messages: [ZMConversationMessage], in conversation: ZMConversation) -> NSAttributedString? {
        
        if messages.count > 1 {
            if type(of: self).indicate3rdPartiesRemoval {
                return "conversation.status.removed_multiple".localized && type(of: self).regularStyle
            }
            else {
                return .none
            }
        }
        else if let message = messages.last,
                let systemMessage = message.systemMessageData,
                let sender = message.sender {

            if systemMessage.users.contains(where: { $0.isSelfUser }) {
                if sender.isSelfUser {
                    return "conversation.status.you_left".localized && type(of: self).regularStyle
                }
                else {
                    return "conversation.status.you_were_removed".localized && type(of: self).regularStyle
                }
            }
            else {
                if conversation.lastServerSyncedActiveParticipants.count == 0 {
                    return "conversation.status.everyone_left".localized && type(of: self).regularStyle
                }
                else if type(of: self).indicate3rdPartiesRemoval {
                    let usersList = systemMessage.users.map { $0.displayName(in: conversation) }.joined(separator: ", ")
                    let result = "conversation.status.removed_users".localized(args: sender.nameAsSender(in: conversation), usersList) && type(of: self).regularStyle
                    return self.addEmphasis(to: result, for: sender.nameAsSender(in: conversation))
                }
                else {
                    return .none
                }
            }
        }
        return .none
    }
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        var allStatusMessagesByType: [StatusMessageType: [ZMConversationMessage]] = [:]
        
        self.matchedTypes.forEach { type in
            allStatusMessagesByType[type] = status.messagesRequiringAttention.filter {
                StatusMessageType(message: $0) == type
            }
        }
        
        let resultString = [addedString(for: allStatusMessagesByType[.addParticipants] ?? [], in: conversation),
                            removedString(for: allStatusMessagesByType[.removeParticipants] ?? [], in: conversation)].compactMap { $0 }.joined(separator: "; " && type(of: self).regularStyle)
        return resultString
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

// [Someone] started a conversation
final internal class StartConversationMatcher: TypedConversationStatusMatcher {
    let matchedTypes: [StatusMessageType] = [.newConversation]
    
    func description(with status: ConversationStatus, conversation: ZMConversation) -> NSAttributedString? {
        guard let message = status.messagesRequiringAttention.first(where: { StatusMessageType(message: $0) == .newConversation }),
              let sender = message.sender,
              !sender.isSelfUser
            else {
            return .none
        }

        let senderString = sender.displayName(in: conversation)
        let resultString = String(format: "conversation.status.started_conversation".localized, senderString)
        return (resultString && type(of: self).regularStyle).addAttributes(type(of: self).emphasisStyle, toSubstring: senderString)
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
        
        return "@" + handle && type(of: self).regularStyle
    }
    
    var combinesWith: [ConversationStatusMatcher] = []
}

/*
 Matchers priorities (highest first):
 
 (SelfUserLeftMatcher)
 (Blocked)
 (Calling)
 (Typing)
 (Silenced)
 (New message / call)
 (Unsent message combines with (Group activity), (New message / call), (Silenced))
 (Group activity)
 (Started conversation)
 (Username)
 */
private var allMatchers: [ConversationStatusMatcher] = {
    let silencedMatcher = SilencedMatcher()
    let newMessageMatcher = NewMessagesMatcher()
    let groupActivityMatcher = GroupActivityMatcher()
    
    let failedSendMatcher = FailedSendMatcher()
    failedSendMatcher.combinesWith = [silencedMatcher, newMessageMatcher, groupActivityMatcher]
    
    return [SelfUserLeftMatcher(), BlockedMatcher(), CallingMatcher(), silencedMatcher, TypingMatcher(), newMessageMatcher, failedSendMatcher, groupActivityMatcher, StartConversationMatcher(), UnsernameMatcher()]
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
    
    func description(for conversation: ZMConversation) -> NSAttributedString {
        let allMatchers = self.appliedMatchersForDescription(for: conversation)
        guard allMatchers.count > 0 else {
            return "" && [:]
        }
        let allStrings = allMatchers.compactMap { $0.description(with: self, conversation: conversation) }
        return allStrings.joined(separator: " | " && CallingMatcher.regularStyle)
    }
    
    func icon(for conversation: ZMConversation) -> ConversationStatusIcon {
        guard let topMatcher = self.appliedMatcherForIcon(for: conversation) else {
            return .none
        }
        
        return topMatcher.icon(with: self, conversation: conversation)
    }
}

extension ZMConversation {
    
    var status: ConversationStatus {
        let isBlocked = self.conversationType == .oneOnOne ? (self.firstActiveParticipantOtherThanSelf()?.isBlocked ?? false) : false

        var messagesRequiringAttention = unreadMessages

        if messagesRequiringAttention.count == 0,
            let lastMessage = self.messages.lastObject as? ZMConversationMessage,
            let systemMessageData = lastMessage.systemMessageData,
            systemMessageData.systemMessageType == .participantsRemoved || systemMessageData.systemMessageType == .participantsAdded || systemMessageData.systemMessageType == .newConversation {
            messagesRequiringAttention.append(lastMessage)
        }
        
        let messagesRequiringAttentionTypes = messagesRequiringAttention.compactMap { StatusMessageType(message: $0) }
        
        var iterator = messagesRequiringAttentionTypes.makeIterator()
        let messagesRequiringAttentionByType = iterator.histogram()
        
        let hasMessages: Bool
        
        if self.messages.count < 10 {
            hasMessages = self.messages.compactMap {
                StatusMessageType(message: $0 as! ZMConversationMessage)
            }.count > 0
        }
        else {
            hasMessages = true
        }
        
        let isOngoingCall: Bool = {
            guard let state = voiceChannel?.state else { return false }
            switch state {
            case .none, .terminating: return false
            case .incoming: return true
            default: return true
            }
        }()
        
        return ConversationStatus(
            isGroup: conversationType == .group,
            hasMessages: hasMessages,
            hasUnsentMessages: hasUnreadUnsentMessage,
            messagesRequiringAttention: messagesRequiringAttention,
            messagesRequiringAttentionByType: messagesRequiringAttentionByType,
            isTyping: typingUsers().count > 0,
            mutedMessageTypes: mutedMessageTypes,
            isOngoingCall: isOngoingCall,
            isBlocked: isBlocked,
            isSelfAnActiveMember: isSelfAnActiveMember,
            hasSelfMention: estimatedUnreadSelfMentionCount > 0,
            hasSelfReply: estimatedUnreadSelfReplyCount > 0
        )
    }
}

