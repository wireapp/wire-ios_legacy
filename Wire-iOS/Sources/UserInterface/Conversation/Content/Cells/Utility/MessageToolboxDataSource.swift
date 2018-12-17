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

/// The different contents that can be displayed inside the message toolbox.
enum MessageToolboxContent: Equatable {
    /// Display buttons to let the user resend the message.
    case sendFailure(NSAttributedString)

    /// Display the list of reactions.
    case reactions(NSAttributedString, likers: [ZMUser])

    /// Display the message details (timestamp and/or status and/or countdown).
    case details(timestamp: NSAttributedString?, status: NSAttributedString?, countdown: NSAttributedString?, likers: [ZMUser])
}

extension MessageToolboxContent: Comparable {

    /// Returns whether one content is located above or below the other.
    /// This is used to determine from which direction to slide, so that we can keep
    /// the animations logical.
    static func < (lhs: MessageToolboxContent, rhs: MessageToolboxContent) -> Bool {
        switch (lhs, rhs) {
        case (.sendFailure, _):
            return true
        case (.details, .reactions):
            return true
        default:
            return false
        }
    }

}

// MARK: - Data Source

/**
 * An object that determines what content to display for the given message.
 */

class MessageToolboxDataSource {

    /// The displayed message.
    let message: ZMConversationMessage

    /// The content to display for the message.
    private(set) var content: MessageToolboxContent

    // MARK: - Formatting Properties

    private let statusTextColor = UIColor.from(scheme: .textDimmed)
    private let statusFont = UIFont.smallSemiboldFont
    private static let ephemeralTimeFormatter = EphemeralTimeoutFormatter()

    private var attributes: [NSAttributedString.Key: AnyObject] {
        return [.font: statusFont, .foregroundColor: statusTextColor]
    }

    private static let separator = " " + String.MessageToolbox.middleDot + " "
    
    // MARK: - Initialization

    /// Creates a toolbox data source for the given message.
    init(message: ZMConversationMessage) {
        self.message = message
        self.content = .details(timestamp: nil, status: nil, countdown: nil, likers: [])
    }

    // MARK: - Content

    /**
     * Updates the contents of the message toolbox.
     * - parameter forceShowTimestamp: Whether the timestamp should be shown, even if a state
     * with a higher priority has been calculated (ex: likes).
     * - parameter widthConstraint: The width available to rend the toolbox contents.
     */

    func updateContent(forceShowTimestamp: Bool, widthConstraint: CGFloat) -> SlideDirection? {
        // Compute the state
        let likers = message.likers()
        let isSentBySelfUser = message.sender?.isSelfUser == true
        let failedToSend = message.deliveryState == .failedToSend && isSentBySelfUser
        let showTimestamp = forceShowTimestamp || likers.isEmpty
        let previousContent = self.content

        // Determine the content by priority

        // 1) Failed to send
        if failedToSend && isSentBySelfUser {
            let detailsString = "content.system.failedtosend_message_timestamp".localized && attributes
            content = .sendFailure(detailsString)
        }
        // 2) Likers
        else if !showTimestamp {
            let text = makeReactionsLabel(with: likers, widthConstraint: widthConstraint)
            content = .reactions(text, likers: likers)
        }
        // 3) Timestamp
        else {
            let (timestamp, status, countdown) = makeDetailsString()
            content = .details(timestamp: timestamp, status: status, countdown: countdown, likers: likers)
        }

        // Only perform the changes if the content did change.
        guard previousContent != content else {
            return nil
        }

        return previousContent < content ? .up : .down
    }

    // MARK: - Reactions

    /// Creates a label that display the likers of the message.
    private func makeReactionsLabel(with likers: [ZMUser], widthConstraint: CGFloat) -> NSAttributedString {
        let likers = message.likers()
        let conversation = message.conversation

        // If there is only one liker, always display the name, even if the width doesn't fit
        if likers.count == 1 {
            return likers[0].displayName(in: conversation) && attributes
        }

        // Create the list of likers
        let likersNames = likers.map { user in
            return user.displayName(in: message.conversation)
        }.joined(separator: ", ")

        let likersNamesAttributedString = likersNames && attributes

        // Check if the list of likers fits on the screen. Otheriwse, show the summary
        let constrainedSize = CGSize(width:  CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = likersNamesAttributedString.boundingRect(with: constrainedSize, options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil)

        if likers.count >= 3 || labelSize.width > widthConstraint {
            let likersCount = String(format: "participants.people.count".localized, likers.count)
            return likersCount && attributes
        } else {
            return likersNamesAttributedString
        }
    }

    // MARK: - Details Text

    /// Creates a label that display the status of the message.
    private func makeDetailsString() -> (NSAttributedString?, NSAttributedString?, NSAttributedString?) {
        let deliveryStateString: NSAttributedString? = selfStatus(for: message)
        let countdownStatus = makeEphemeralCountdown()

        // System message overrides

        if let childMessages = message.systemMessageData?.childMessages,
            !childMessages.isEmpty,
            let timestamp = timestampString(message) {
            let childrenTimestamps = childMessages.compactMap {
                $0 as? ZMConversationMessage
                }.sorted { left, right in
                    left.serverTimestamp < right.serverTimestamp
                }.compactMap(timestampString)

            let finalText = NSAttributedString(string: childrenTimestamps.reduce(timestamp) { (text, current) in
                return "\(text)\n\(current)"
            })

            return (finalText, deliveryStateString, countdownStatus)
        } else if let timestampString = self.timestampString(message), message.isSent {
            if let deliveryStateString = deliveryStateString, Message.shouldShowDeliveryState(message) {
                return (timestampString && attributes, deliveryStateString, countdownStatus)
            }
            else {
                return (timestampString && attributes, nil, countdownStatus)
            }
        }
        else {
            return (nil, deliveryStateString, countdownStatus)
        }
    }

    private func makeEphemeralCountdown() -> NSAttributedString? {
        let showDestructionTimer = message.isEphemeral && !message.isObfuscated && nil != message.destructionDate
        if let destructionDate = message.destructionDate, showDestructionTimer {
            let remaining = destructionDate.timeIntervalSinceNow + 1 // We need to add one second to start with the correct value

            if remaining > 0 {
                if let string = MessageToolboxDataSource.ephemeralTimeFormatter.string(from: remaining) {
                    return string && attributes
                }
            } else if message.isAudio {
                // do nothing, audio messages are allowed to extend the timer
                // past the destruction date.
            }
        }

        return nil
    }

    /// Returns the status for the sender of the message.
    fileprivate func selfStatus(for message: ZMConversationMessage) -> NSAttributedString? {
        guard let sender = message.sender,
            sender.isSelfUser else { return nil }

        var deliveryStateString: String

        switch message.deliveryState {
        case .pending:
            deliveryStateString = "content.system.pending_message_timestamp".localized
        case .read:
            return selfStatusForReadDeliveryState(for: message)
        case .delivered:
            deliveryStateString = "content.system.message_delivered_timestamp".localized
        case .sent:
            deliveryStateString = "content.system.message_sent_timestamp".localized
        case .invalid, .failedToSend:
            return nil
        }

        return NSAttributedString(string: deliveryStateString) && attributes
    }

    /// Creates the status for the read receipts.
    fileprivate func selfStatusForReadDeliveryState(for message: ZMConversationMessage) -> NSAttributedString? {
        guard let conversationType = message.conversation?.conversationType else {return nil}

        switch conversationType {
        case .group:
            let attributes: [NSAttributedString.Key: AnyObject] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: statusTextColor
            ]

            let imageIcon = NSTextAttachment.textAttachment(for: .eye, with: statusTextColor, verticalCorrection: -1)!
            return NSAttributedString(attachment: imageIcon) + " \(message.readReceipts.count)" && attributes

        case .oneOnOne:
            guard let timeString = message.readReceipts.first?.serverTimestamp else {
                return nil
            }

            let imageIcon = NSTextAttachment.textAttachment(for: .eye, with: statusTextColor, verticalCorrection: -1)!
            return NSAttributedString(attachment: imageIcon) + " " + Message.formattedDate(timeString) && attributes

        default:
            return nil
        }
    }

    /// Creates the timestamp text.
    fileprivate func timestampString(_ message: ZMConversationMessage) -> String? {
        let timestampString: String?

        if let editedTimeString = message.formattedEditedDate() {
            timestampString = String(format: "content.system.edited_message_prefix_timestamp".localized, editedTimeString)
        } else if let dateTimeString = message.formattedReceivedDate() {
            if let systemMessage = message as? ZMSystemMessage , systemMessage.systemMessageType == .messageDeletedForEveryone {
                timestampString = String(format: "content.system.deleted_message_prefix_timestamp".localized, dateTimeString)
            } else if let durationString = message.systemMessageData?.callDurationString() {
                timestampString = dateTimeString + MessageToolboxDataSource.separator + durationString
            } else {
                timestampString = dateTimeString
            }
        } else {
            timestampString = .none
        }

        return timestampString
    }

}
