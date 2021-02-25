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
import WireDataModel
import WireSyncEngine

// Describes the icon to be shown for the conversation in the list.
enum ConversationStatusIcon: Equatable {
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
enum StatusMessageType: Int, CaseIterable {
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

    private var localizationSilencedRootPath: String {
        return "conversation.silenced.status.message"
    }

    private var localizationKeySuffix: String? {
        switch self {
            case .mention:
                return "mention"
            case .reply:
                return "reply"
            case .missedCall:
                return "missedcall"
            case .knock:
                return "knock"
            case .text:
                return "generic_message"
            default:
                return nil
        }
    }

    var localizationKey: String? {
        guard let localizationKey = localizationKeySuffix else {
            return nil
        }

        return (localizationSilencedRootPath + "." + localizationKey)
    }

    func localizedString(with count: UInt) -> String? {
        guard let localizationKey = localizationKey else { return nil }

        return String(format: localizationKey.localized, count)
    }
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
        .participantsAdded: .addParticipants,
        .participantsRemoved: .removeParticipants,
        .missedCall: .missedCall,
        .newConversation: .newConversation
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
    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString?
    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon?

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
    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        return nil
    }

    func addEmphasis(to string: NSAttributedString, for substring: String) -> NSAttributedString {
        return string.setAttributes(type(of: self).emphasisStyle, toSubstring: substring)
    }
}

final class ContentSizeCategoryUpdater {
    private let callback: () -> ()
    private var observer: NSObjectProtocol!

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
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
                                 .foregroundColor: UIColor(white: 1.0, alpha: 0.64)]
            self.emphasisStyle = [.font: FontSpec(.medium, .medium).font!,
                                  .foregroundColor: UIColor(white: 1.0, alpha: 0.64)]
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
    static func statusRegularStyle() -> [NSAttributedString.Key: AnyObject] {
        return statusStyle.regularStyle
    }

    static func statusEmphasisStyle() -> [NSAttributedString.Key: AnyObject] {
        return statusStyle.emphasisStyle
    }
}

// "You left"
final class SelfUserLeftMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return !status.hasMessages && status.isGroup && !status.isSelfAnActiveMember
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        return "conversation.status.you_left".localized && type(of: self).regularStyle
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        return nil
    }

    var combinesWith: [ConversationStatusMatcher] = []
}

// "Blocked"
final class BlockedMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.isBlocked
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        return "conversation.status.blocked".localized && type(of: self).regularStyle
    }

    var combinesWith: [ConversationStatusMatcher] = []
}

// "Active Call"
final class CallingMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.isOngoingCall
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        if conversation.voiceChannel?.state.canJoinCall == true {
            if let callerDisplayName = conversation.voiceChannel?.initiator?.name {
                return "conversation.status.incoming_call".localized(args: callerDisplayName) && type(of: self).regularStyle
            } else {
                return "conversation.status.incoming_call.someone".localized && type(of: self).regularStyle
            }
        }
        return .none
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        return CallingMatcher.icon(for: conversation.voiceChannel?.state, conversation: conversation)
    }

    public static func icon(for state: CallState?, conversation: ConversationStatusProvider?) -> ConversationStatusIcon? {

        guard let state = state else {
            return nil
        }

        if state.canJoinCall {
            return .activeCall(showJoin: true)
        } else if state.isCallOngoing {
            return .activeCall(showJoin: false)
        }

        return nil
    }

    var combinesWith: [ConversationStatusMatcher] = []
}

final class SecurityAlertMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.messagesRequiringAttention.contains(where: { $0.isComposite })
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {

        guard let message = status.messagesRequiringAttention.reversed().first(where: {
            $0.isComposite
        }) else {
            return nil
        }

        let textItem = (message as? ConversationCompositeMessage)?.compositeMessageData?.items.first(where: {
            if case .text(_) = $0 {
                return true
            }
            return false
        })

        let text: String
        if let textItem = textItem,
           case let .text(data) = textItem,
           let messageText = data.messageText {
            text = messageText
        } else {
            text = "conversation.status.poll.default".localized
        }

        return text && Swift.type(of: self).regularStyle
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        return nil ///TODO: icon for poll message
    }

    var combinesWith: [ConversationStatusMatcher] = []
}

// "A, B, C: typing a message..."
final class TypingMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.isTyping && status.showingAllMessages
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {

        let statusString: NSAttributedString
        if status.isGroup {
            let typingUsersString = conversation.typingUsers.compactMap(\.name).joined(separator: ", ")
            let resultString = String(format: "conversation.status.typing.group".localized, typingUsersString)
            let intermediateString = NSAttributedString(string: resultString, attributes: type(of: self).regularStyle)
            statusString = self.addEmphasis(to: intermediateString, for: typingUsersString)
        }
        else {
            statusString = "conversation.status.typing".localized && type(of: self).regularStyle
        }
        return statusString
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        return .typing
    }

    var combinesWith: [ConversationStatusMatcher] = []
}

// "Silenced"
final class SilencedMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return !status.showingAllMessages
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        return .none
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
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
final class NewMessagesMatcher: TypedConversationStatusMatcher {
    var matchedTypes: [StatusMessageType] {
        return StatusMessageType.summaryTypes
    }

    let localizationRootPath = "conversation.status.message"

    let matchedTypesDescriptions: [StatusMessageType: String] = [
        .mention: "mention",
        .reply: "reply",
        .missedCall: "missedcall",
        .knock: "knock",
        .text: "text",
        .link: "link",
        .image: "image",
        .location: "location",
        .audio: "audio",
        .video: "video",
        .file: "file"
    ]

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
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
                    guard let count = flattenedCount[$1], let string = $1.localizedString(with: count) else {
                        return
                    }

                    $0.append(string)
                }

            let resultString = localizedMatchedItems.joined(separator: ", ")
            return resultString.capitalizingFirstLetter() && type(of: self).regularStyle
        }
        else {
            guard let message = status.messagesRequiringAttention.reversed().first(where: {
                    if let _ = $0.senderUser,
                       let type = StatusMessageType(message: $0),
                       let _ = matchedTypesDescriptions[type] {
                        return true
                    } else {
                        return false
                    }
                }),
                    let sender = message.senderUser,
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
                    return format.localized(args: sender.name ?? "") && Swift.type(of: self).regularStyle
                }

                messageDescription = String(format: format.localized, message.textMessageData?.messageText ?? "")
            }

            if status.isGroup && !message.isEphemeral {
                return (((sender.name ?? "") + ": ") && Swift.type(of: self).emphasisStyle) +
                        (messageDescription && Swift.type(of: self).regularStyle)
            }
            else {
                return messageDescription && Swift.type(of: self).regularStyle
            }
        }
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {

        if status.hasSelfMention {
            return .mention
        } else if status.hasSelfReply {
            return .reply
        }

        guard let message = status.messagesRequiringAttention.reversed().first(where: {
                if let _ = $0.senderUser,
                   let type = StatusMessageType(message: $0),
                   let _ = matchedTypesDescriptions[type] {
                    return true
                }
                else {
                    return false
                }
            }),
            let type = StatusMessageType(message: message) else {
            return nil
        }

        switch type {
        case .knock:
            return .unreadPing
        case .missedCall:
            return .missedCall
        default:
            return .unreadMessages(count: status.messagesRequiringAttention.compactMap { StatusMessageType(message: $0) }.filter { matchedTypes.firstIndex(of: $0) != .none }.count)
        }
    }

    var combinesWith: [ConversationStatusMatcher] = []
}

// ! Failed to send
final class FailedSendMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return status.hasUnsentMessages
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        return "conversation.status.unsent".localized && type(of: self).regularStyle
    }

    var combinesWith: [ConversationStatusMatcher] = []
}

// "[You|User] [added|removed|left] [_|users|you]"
final class GroupActivityMatcher: TypedConversationStatusMatcher {
    let matchedTypes: [StatusMessageType] = [.addParticipants, .removeParticipants]

    private func addedString(for messages: [ZMConversationMessage], in conversation: MatcherConversation) -> NSAttributedString? {
        if let message = messages.last,
           let systemMessage = message.systemMessageData,
           let sender = message.senderUser,
           !sender.isSelfUser {

            if systemMessage.userTypes.contains(where: { ($0 as? UserType)?.isSelfUser == true }) {
                let fullName = sender.name ?? ""
                let result = String(format: "conversation.status.you_was_added".localized, fullName) && type(of: self).regularStyle
                return self.addEmphasis(to: result, for: fullName)
            }
        }
        return .none
    }

    private func removedString(for messages: [ZMConversationMessage],
                               in conversation: MatcherConversation) -> NSAttributedString? {

        if let message = messages.last,
           let systemMessage = message.systemMessageData,
           let sender = message.senderUser,
           !sender.isSelfUser{

            if systemMessage.userTypes.contains(where: { ($0 as? UserType)?.isSelfUser == true }) {
                return "conversation.status.you_were_removed".localized && type(of: self).regularStyle
            }
        }
        return .none
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
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

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        return .unreadMessages(count: status.messagesRequiringAttention
            .compactMap { StatusMessageType(message: $0) }
            .filter { matchedTypes.contains($0) }
            .count)
    }
}

// [Someone] started a conversation
final class StartConversationMatcher: TypedConversationStatusMatcher {
    let matchedTypes: [StatusMessageType] = [.newConversation]

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        guard let message = status.messagesRequiringAttention.first(where: { StatusMessageType(message: $0) == .newConversation }),
              let sender = message.senderUser,
              !sender.isSelfUser
            else {
            return .none
        }

        let senderString = sender.name ?? ""
        let resultString = String(format: "conversation.status.started_conversation".localized, senderString)
        return (resultString && type(of: self).regularStyle).addAttributes(type(of: self).emphasisStyle, toSubstring: senderString)
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        return ConversationStatusIcon.unreadMessages(count: 1)
    }

    var combinesWith: [ConversationStatusMatcher] = []
}

// Fallback for empty conversations: showing the handle.
final class UnsernameMatcher: ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        return !status.hasMessages
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {

        guard let handle = conversation.connectedUserType?.handle else {
            return .none
        }

        return "@" + handle && type(of: self).regularStyle
    }

    var combinesWith: [ConversationStatusMatcher] = []
}

/*
 Matchers priorities (highest first):
 
 (SecurityAlert)
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

    return [SecurityAlertMatcher(),
            SelfUserLeftMatcher(),
            BlockedMatcher(),
            CallingMatcher(),
            silencedMatcher,
            TypingMatcher(),
            newMessageMatcher,
            failedSendMatcher,
            groupActivityMatcher,
            StartConversationMatcher(), UnsernameMatcher()]
}()

extension ConversationStatus {
    func appliedMatchersForDescription(for conversation: MatcherConversation) -> [ConversationStatusMatcher] {
        guard let topMatcher = allMatchers.first(where: { $0.isMatching(with: self) && $0.description(with: self, conversation: conversation) != .none }) else {
            return []
        }

        return [topMatcher] + topMatcher.combinesWith.filter { $0.isMatching(with: self) && $0.description(with: self, conversation: conversation) != .none }
    }

    func appliedMatcherForIcon(for conversation: MatcherConversation) -> ConversationStatusMatcher? {

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

    func description(for conversation: MatcherConversation) -> NSAttributedString {
        let allMatchers = appliedMatchersForDescription(for: conversation)
        guard !allMatchers.isEmpty else {
            return "" && [:]
        }
        let allStrings = allMatchers.compactMap { $0.description(with: self, conversation: conversation) }
        return allStrings.joined(separator: " | " && CallingMatcher.regularStyle)
    }

    func icon(for conversation: MatcherConversation) -> ConversationStatusIcon? {
        guard let topMatcher = appliedMatcherForIcon(for: conversation) else {
            return nil
        }

        return topMatcher.icon(with: self, conversation: conversation)
    }
}

extension ZMConversation {

    var status: ConversationStatus {
        let messagesRequiringAttention = estimatedUnreadCount > 0 ? unreadMessages : []

        let messagesRequiringAttentionByType: [StatusMessageType: UInt] = messagesRequiringAttention.reduce(into: [:]) { histogram, element in
            guard let messageType = StatusMessageType(message: element) else {
                return
            }

            histogram[messageType, default: 0] += 1
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
            hasMessages: estimatedHasMessages,
            hasUnsentMessages: hasUnreadUnsentMessage,
            messagesRequiringAttention: messagesRequiringAttention,
            messagesRequiringAttentionByType: messagesRequiringAttentionByType,
            isTyping: typingUsers.count > 0,
            mutedMessageTypes: mutedMessageTypes,
            isOngoingCall: isOngoingCall,
            isBlocked: connectedUser?.isBlocked ?? false,
            isSelfAnActiveMember: isSelfAnActiveMember,
            hasSelfMention: estimatedUnreadSelfMentionCount > 0,
            hasSelfReply: estimatedUnreadSelfReplyCount > 0
        )
    }
}
