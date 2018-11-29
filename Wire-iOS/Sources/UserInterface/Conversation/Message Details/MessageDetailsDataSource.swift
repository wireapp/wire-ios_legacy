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

/// The way the details are displayed.
enum MessageDetailsDisplayMode {
    case reactions, receipts, combined
}

/**
 * An object that observes changes in the message data source.
 */

protocol MessageDetailsDataSourceObserver: class {
    /// Called when the message details change.
    func dataSourceDidChange(_ dataSource: MessageDetailsDataSource)

    /// Called when the message subtitle changes.
    func detailsHeaderDidChange(_ dataSource: MessageDetailsDataSource)
}

/**
 * The data source to present message details.
 */

class MessageDetailsDataSource: NSObject, ZMMessageObserver, ZMConversationObserver {

    /// The presented message.
    let message: ZMConversationMessage

    /// The conversation where the message is
    let conversation: ZMConversation

    /// How to display the message details.
    let displayMode: MessageDetailsDisplayMode

    /// The title of the message details.
    let title: String

    /// The subtitle of the message details.
    private(set) var subtitle: String!

    /// The list of likes.
    private(set) var reactions: [ZMUser]

    /// The list of read receipts with the associated date.
    private(set) var readReciepts: [ZMUser: Date]

    /// The object that receives information when the message details changes.
    weak var observer: MessageDetailsDataSourceObserver?

    // MARK: - Initialization

    private var observationTokens: [Any] = []

    deinit {
        observationTokens.removeAll()
    }

    init(message: ZMConversationMessage) {
        self.message = message
        self.conversation = message.conversation!

        // Assign the initial data
        self.reactions = message.likers()
        self.readReciepts = [:]

        // Compute the title and display mode
        let supportsLikes = message.canBeLiked
        let supportsReadReciepts = message.areReadReceiptsDetailsAvailable
//        let readReceiptsEnabled = false // TODO: Support read receipts settings in conversation

        switch (supportsLikes, supportsReadReciepts) {
        case (true, true):
            self.displayMode = .combined
            self.title = "message_details.combined_title".localized
        case (false, true):
            self.displayMode = .receipts
            self.title = "message_details.receipts_title".localized
        case (true, false):
            self.displayMode = .reactions
            self.title = "message_details.likes_title".localized
        default:
            fatal("Trying to display a message that does not support reactions or receipts.")
        }

        super.init()
        
        updateSubtitle()
        setupMessageObserver()
    }

    // MARK: - Interface Properties

    private func updateSubtitle() {
        guard let sentDate = message.formattedReceivedDate() else {
            return
        }

        let sentString = "message_details.subtitle_send_date".localized(args: sentDate)
        var subtitle = sentString

        if let editedDate = message.formattedEditedDate() {
            let editedString = "message_details.subtitle_edit_date".localized(args: editedDate)
            subtitle += " · " + editedString
        }

        self.subtitle = subtitle
        self.observer?.detailsHeaderDidChange(self)
    }

    // MARK: - Changes

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        // TODO: Detect read receipts in change info

        if changeInfo.reactionsChanged {
            performChanges {
                self.reactions = message.likers()
            }
        }

        if message.updatedAt != nil {
            updateSubtitle()
        }
    }

    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        // TODO: Detect "read receipts" settings change
//        let receiptsStatusChanged = false
//
//        if receiptsStatusChanged {
//            updateDisplayMode()
//        }
    }

    private func setupMessageObserver() {
        if let userSession = ZMUserSession.shared() {
            let messageObserver = MessageChangeInfo.add(observer: self, for: message, userSession: userSession)
            let conversationObserver = ConversationChangeInfo.add(observer: self, for: conversation)
            observationTokens = [messageObserver, conversationObserver]
        }
    }

    /// Commits changes to the data source and notifies the observer.
    private func performChanges(_ block: () -> Void) {
        block()
        observer?.dataSourceDidChange(self)
    }

}
