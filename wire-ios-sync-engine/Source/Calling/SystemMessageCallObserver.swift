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

private let log = ZMSLog(tag: "Calling System Message")

/// Inserts a calling system message for V3 calls.
final class CallSystemMessageGenerator: NSObject {

    var startDateByConversation = [ZMConversation: Date]()
    var connectDateByConversation = [ZMConversation: Date]()

    func appendSystemMessageIfNeeded(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?, previousCallState: CallState?) -> ZMSystemMessage? {
        var systemMessage: ZMSystemMessage?

        switch callState {
        case .outgoing:
            log.info("Setting call start date for \(conversation.displayName)")
            startDateByConversation[conversation] = Date()
        case .established:
            log.info("Setting call connect date for \(conversation.displayName)")
            connectDateByConversation[conversation] = Date()
        case .terminating(reason: let reason):
        systemMessage = appendCallEndedSystemMessage(reason: reason, conversation: conversation, caller: caller, timestamp: timestamp, previousCallState: previousCallState)
        case .none, .unknown, .answered, .establishedDataChannel, .incoming, .mediaStopped:
            break
        }
        return systemMessage
    }

    private func appendCallEndedSystemMessage(reason: CallClosedReason, conversation: ZMConversation, caller: ZMUser, timestamp: Date?, previousCallState: CallState?) -> ZMSystemMessage? {

        var systemMessage: ZMSystemMessage?
        if let connectDate = connectDateByConversation[conversation] {
            let duration = -connectDate.timeIntervalSinceNow
            log.info("Appending performed call message: \(duration), \(caller.name ?? ""), \"\(conversation.displayName)\"")
            systemMessage =  conversation.appendPerformedCallMessage(with: duration, caller: caller)
        } else {
            if caller.isSelfUser {
                log.info("Appending performed call message: \(caller.name ?? ""), \"\(conversation.displayName)\"")
                systemMessage =  conversation.appendPerformedCallMessage(with: 0, caller: caller)
            } else if reason.isOne(of: .canceled, .timeout, .normal) {
                log.info("Appending missed call message: \(caller.name ?? ""), \"\(conversation.displayName)\"")

                var isRelevant = true
                if case .incoming(video: _, shouldRing: false, degraded: _)? = previousCallState {
                    // Call was ignored by recipient
                    isRelevant = false
                }

                systemMessage = conversation.appendMissedCallMessage(fromUser: caller, at: timestamp ?? Date(), relevantForStatus: isRelevant)
            }
        }

        startDateByConversation[conversation] = nil
        connectDateByConversation[conversation] = nil
        return systemMessage
    }

}
