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

// These are the "base" keys for messages. We append to these for the specific case.
//
private let ZMPushStringDefault             = "default"

private let ZMPushStringEphemeralTitle      = "ephemeral.title"
private let ZMPushStringEphemeral           = "ephemeral"

// Title with team name
private let ZMPushStringTitle               = "title"                // "[conversationName] in [teamName]

// 1 user, 1 conversation, 1 string
// %1$@    %2$@            %3$@
//
private let ZMPushStringMessageAdd          = "add.message"          // "[senderName]: [messageText]"
private let ZMPushStringImageAdd            = "add.image"            // "[senderName] shared a picture"
private let ZMPushStringVideoAdd            = "add.video"            // "[senderName] shared a video"
private let ZMPushStringAudioAdd            = "add.audio"            // "[senderName] shared an audio message"
private let ZMPushStringFileAdd             = "add.file"             // "[senderName] shared a file"
private let ZMPushStringLocationAdd         = "add.location"         // "[senderName] shared a location"

// currently disabled
// public let ZMPushStringMessageAddMany      = "add.message.many"    // "x new messages in [conversationName] / from [senderName]"

private let ZMPushStringFailedToSend        = "failed.message"       // "Unable to send a message"

private let ZMPushStringAlertAvailability   = "alert.availability"   // "Availability now affects notifications"

private let ZMPushStringBundledMessages     = "bundled-messages"

private let ZMPushStringMemberJoin          = "member.join"          // "[senderName] added you"
private let ZMPushStringMemberLeave         = "member.leave"         // "[senderName] removed you"
private let ZMPushStringMessageTimerUpdate  = "message-timer.update" // "[senderName] set the message timer to [duration]
private let ZMPushStringMessageTimerOff     = "message-timer.off"    // "[senderName] turned off the message timer

private let ZMPushStringKnock               = "knock"                // "pinged"
private let ZMPushStringReaction            = "reaction"             // "[emoji] your message"

private let ZMPushStringVideoCallStarts     = "call.started.video"   // "is video calling"
private let ZMPushStringCallStarts          = "call.started"         // "is calling"
private let ZMPushStringCallMissed          = "call.missed"          // "called"

// currently disabled
// public let ZMPushStringCallMissedMany      = "call.missed.many"    // "You have x missed calls in a conversation"

private let ZMPushStringConnectionRequest   = "connection.request"   // "[senderName] wants to connect"
private let ZMPushStringConnectionAccepted  = "connection.accepted"  // "You and [senderName] are now connected"

private let ZMPushStringConversationCreate  = "conversation.create"  // "[senderName] created a group"
private let ZMPushStringConversationDelete  = "conversation.delete"  // "[senderName] deleted the group"
private let ZMPushStringNewConnection       = "new_user"             // "[senderName] just joined Wire"

private let OneOnOneKey = "oneonone"
private let GroupKey = "group"
private let SelfKey = "self"
private let MentionKey = "mention"
private let ReplyKey = "reply"
private let TeamKey = "team"
private let NoConversationNameKey = "noconversationname"
private let NoUserNameKey = "nousername"

extension LocalNotificationType {

    fileprivate var baseKey: String {
        switch self {
        case .message(let contentType):
            switch contentType {
            case .image:
                return ZMPushStringImageAdd
            case .video:
                return ZMPushStringVideoAdd
            case .audio:
                return ZMPushStringAudioAdd
            case .location:
                return ZMPushStringLocationAdd
            case .fileUpload:
                return ZMPushStringFileAdd
            case .text:
                return ZMPushStringMessageAdd
            case .knock:
                return ZMPushStringKnock
            case .reaction:
                return ZMPushStringReaction
            case .ephemeral:
                return ZMPushStringEphemeral
            case .hidden:
                return ZMPushStringDefault
            case .participantsAdded:
                return ZMPushStringMemberJoin
            case .participantsRemoved:
                return ZMPushStringMemberLeave
            case .messageTimerUpdate(nil):
                return ZMPushStringMessageTimerOff
            case .messageTimerUpdate:
                return ZMPushStringMessageTimerUpdate
            }

        case .calling(let callState):
            switch callState {
            case .incomingCall(video: true):
                return ZMPushStringVideoCallStarts
            case .incomingCall(video: false):
                return ZMPushStringCallStarts
            case .missedCall:
                return ZMPushStringCallMissed
            }

        case .event(let eventType):
            switch eventType {
            case .conversationCreated:
                return ZMPushStringConversationCreate
            case .conversationDeleted:
                return ZMPushStringConversationDelete
            case .connectionRequestPending:
                return ZMPushStringConnectionRequest
            case .connectionRequestAccepted:
                return ZMPushStringConnectionAccepted
            case .newConnection:
                return ZMPushStringNewConnection
            }
        case .failedMessage:
            return ZMPushStringFailedToSend

        case .availabilityBehaviourChangeAlert:
            return ZMPushStringAlertAvailability

        case .bundledMessages:
            return ZMPushStringBundledMessages
        }
    }

    fileprivate func senderKey(_ sender: ZMUser?, _ conversation: ZMConversation?) -> String? {
        guard let sender = sender else { return NoUserNameKey }

        if case .failedMessage = self {
            return nil
        } else if sender.name == nil || sender.name!.isEmpty {
            return NoUserNameKey
        }

        return nil
    }

    fileprivate func conversationKey(_ conversation: ZMConversation?) -> String? {
        if conversation?.conversationType != .oneOnOne && conversation?.meaningfulDisplayName == nil {
            return NoConversationNameKey
        }

        return nil
    }

    fileprivate func messageBodyText(eventType: LocalNotificationEventType, senderName: String?) -> String {
        let senderKey = senderName == nil ? NoUserNameKey : nil
        let localizationKey = [baseKey, senderKey].compactMap { $0 }.joined(separator: ".")
        var arguments: [CVarArg] = []

        if let senderName = senderName {
            arguments.append(senderName)
        }

        return .localizedStringWithFormat(localizationKey.pushFormatString, arguments: arguments)
    }

    public func titleText(selfUser: ZMUser, conversation: ZMConversation? = nil) -> String? {

        if case .message(let contentType) = self {
            switch contentType {
            case .ephemeral:
                return .localizedStringWithFormat(ZMPushStringEphemeralTitle.pushFormatString)
            case .hidden:
                return nil
            default:
                break
            }
        }

        let teamName = selfUser.team?.name
        let conversationName = conversation?.meaningfulDisplayName

        if let conversationName = conversationName, let teamName = teamName {
            return .localizedStringWithFormat(ZMPushStringTitle.pushFormatString, arguments: [conversationName, teamName])
        } else if let conversationName = conversationName {
            return conversationName
        } else if let teamName = teamName {
            return teamName
        }

        return nil
    }

    public func alertTitleText(team: Team?) -> String? {
        guard case .availabilityBehaviourChangeAlert(let availability) = self, availability.isOne(of: .away, .busy) else { return nil }

        let teamName = team?.name
        let teamKey = teamName != nil ? TeamKey : nil
        let availabilityKey = availability == .away ? "away" : "busy"
        let localizationKey = [baseKey, availabilityKey, "title", teamKey].compactMap({ $0 }).joined(separator: ".")
        return .localizedStringWithFormat(localizationKey.pushFormatString, arguments: [teamName].compactMap({ $0 }))
    }

    public func alertMessageBodyText() -> String {
        guard case .availabilityBehaviourChangeAlert(let availability) = self, availability.isOne(of: .away, .busy) else { return "" }

        let availabilityKey = availability == .away ? "away" : "busy"
        let localizationKey = [baseKey, availabilityKey, "message"].compactMap({ $0 }).joined(separator: ".")
        return .localizedStringWithFormat(localizationKey.pushFormatString)
    }

    func bundledMessagesBodyText(messageCount: Int) -> String {
        guard case .bundledMessages = self else { return "" }
        return .localizedStringWithFormat(baseKey.pushFormatString, arguments: [messageCount])
    }

    func messageBodyText(senderName: String?) -> String {
        if case LocalNotificationType.event(let eventType) = self {
            return messageBodyText(eventType: eventType, senderName: senderName)
        } else {
            return messageBodyText(sender: nil, conversation: nil)
        }
    }

    public func messageBodyText(sender: ZMUser?, conversation: ZMConversation?) -> String {
        if case LocalNotificationType.event(let eventType) = self {
            return messageBodyText(eventType: eventType, senderName: sender?.name)
        }

        let conversationName = conversation?.userDefinedName ?? ""
        let senderName = sender?.name ?? ""
        var senderKey = self.senderKey(sender, conversation)
        var conversationTypeKey: String? = (conversation?.conversationType != .oneOnOne) ? GroupKey : OneOnOneKey
        let conversationKey = self.conversationKey(conversation)

        var arguments: [CVarArg] = []

        if senderKey == nil, conversation?.conversationType != .oneOnOne {
            // if the conversation is oneOnOne, then the sender name will be in the notification title
            arguments.append(senderName)
        }

        var mentionOrReplyKey: String?

        switch self {
        case .message(let contentType):
            switch contentType {
            case let .text(content, isMention, isReply):
                arguments.append(content)
                mentionOrReplyKey = isMention ? MentionKey : (isReply ? ReplyKey : nil)

            case .reaction(emoji: let emoji):
                arguments.append(emoji)

            case .knock:
                arguments.append(NSNumber(value: 1))

            case let .ephemeral(isMention, isReply):
                mentionOrReplyKey = isMention ? MentionKey : (isReply ? ReplyKey : nil)
                let key = [baseKey, mentionOrReplyKey].compactMap { $0 }.joined(separator: ".")
                return .localizedStringWithFormat(key.pushFormatString)

            case .hidden:
                return .localizedStringWithFormat(baseKey.pushFormatString)

            case .messageTimerUpdate(let timerString):
                if let string = timerString {
                    arguments.append(string)
                }
                conversationTypeKey = nil

            case .participantsAdded:
                conversationTypeKey = nil // System messages don't follow the template and is missing the `group` suffix
                senderKey = SelfKey

            case .participantsRemoved(let reason):
                conversationTypeKey = nil // System messages don't follow the template and is missing the `group` suffix
                senderKey = SelfKey
                // If there is a reason for removal, we should display a simple message "You were removed"
                mentionOrReplyKey = reason.stringValue != nil ? NoUserNameKey : nil

            default:
                break
            }
        default: break
        }

        if conversationKey == nil, conversation?.conversationType != .oneOnOne {
            arguments.append(conversationName)
        }

        let localizationKey = [baseKey, conversationTypeKey, senderKey, conversationKey, mentionOrReplyKey].compactMap({ $0 }).joined(separator: ".")
        return .localizedStringWithFormat(localizationKey.pushFormatString, arguments: arguments)
    }

}

public extension String {

    var pushFormatString: String {
        return Bundle(for: ZMSingleRequestSync.self).localizedString(forKey: "push.notification.\(self)", value: "", table: "Push")
    }

    var pushActionString: String {
        return Bundle(for: ZMSingleRequestSync.self).localizedString(forKey: "push.notification.action.\(self)", value: "", table: "Push")
    }

    static fileprivate func localizedStringWithFormat(_ format: String, arguments: [CVarArg]) -> String {
        switch arguments.count {
        case 1:
            return String.localizedStringWithFormat(format, arguments[0])
        case 2:
            return String.localizedStringWithFormat(format, arguments[0], arguments[1])
        case 3:
            return String.localizedStringWithFormat(format, arguments[0], arguments[1], arguments[2])
        case 4:
            return String.localizedStringWithFormat(format, arguments[0], arguments[1], arguments[2], arguments[3])
        default:
            return NSLocalizedString(format, comment: "")

        }
    }

}
