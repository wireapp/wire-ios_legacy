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

/**
 * An object that observes changes in the message data source.
 */

protocol MessageDetailsDataSourceObserver: class {
    /// Called when the message details change.
    func dataSourceDidChange(_ dataSource: MessageDetailsDataSource)
}

/**
 * The data source to present message details.
 */

class MessageDetailsDataSource: NSObject, ZMMessageObserver {

    /// The way the details are displayed.
    enum DisplayMode {
        case likes, receipts, combined
    }

    /// The presented message.
    let message: ZMConversationMessage

    /// How to display the message details.
    let displayMode: DisplayMode

    /// The list of likes.
    private(set) var reactions: [ZMUser]

    /// The list of read receipts with the associated date.
    private(set) var readReciepts: [ZMUser: Date]

    /// The object that receives information when the message details changes.
    weak var observer: MessageDetailsDataSourceObserver?

    // MARK: - Initialization

    private var changeObserverToken: Any?

    init(message: ZMConversationMessage) {
        self.message = message

        // Compute the display mode
        let supportsLikes = message.canBeLiked
        let supportsReadReciepts = message.areReadReceiptsDetailsAvailable

        switch (supportsLikes, supportsReadReciepts) {
        case (true, true):
            self.displayMode = .combined
        case (false, true):
            self.displayMode = .receipts
        case (true, false):
            self.displayMode = .likes
        default:
            fatal("Trying to display a message that does not support likes or receipts.")
        }

        // Assign the initial details
        self.reactions = message.likers()

        // TODO: Get read receipts from message.
        self.readReciepts = [:]

        super.init()
        setupMessageObserver()
    }

    // MARK: - Changes

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        // TODO: Detect read receipts in change info

        if changeInfo.reactionsChanged {
            performChanges {
                self.reactions = message.likers()
            }
        }
    }

    private func setupMessageObserver() {
        if let userSession = ZMUserSession.shared() {
            changeObserverToken = MessageChangeInfo.add(observer: self, for: message, userSession: userSession)
        }
    }

    /// Commits changes to the data source and notifies the observer.
    private func performChanges(_ block: () -> Void) {
        block()
        observer?.dataSourceDidChange(self)
    }

}
