//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import WireSyncEngine

final class ForegroundNotificationFilter {

    // MARK: - Public Property
    var sessionManager: SessionManager?

    // MARK: - Initialization
    public init(sessionManager: SessionManager? = nil) {
        self.sessionManager = sessionManager
    }
}

// TO DO: Ask for the logic, not clear when a notification shuld be presented
extension ForegroundNotificationFilter: ForegroundNotificationResponder {

    func shouldPresentNotification(with userInfo: NotificationUserInfo) -> Bool {
        // user wants to see fg notifications
        let chatHeadsDisabled: Bool = Settings.shared[.chatHeadsDisabled] ?? false
        guard !chatHeadsDisabled else {
            return false
        }

        // the concerned account is active
        guard
            let selfUserID = userInfo.selfUserID,
            selfUserID == sessionManager?.accountManager.selectedAccount?.userIdentifier
        else {
            return true
        }

        guard let clientVC = ZClientViewController.shared else {
            return true
        }

        if clientVC.isConversationListVisible {
            return false
        }

        guard clientVC.isConversationViewVisible else {
            return true
        }

        // conversation view is visible for another conversation
        guard
            let convID = userInfo.conversationID,
            convID != clientVC.currentConversation?.remoteIdentifier
        else {
            return false
        }

        return true
    }
}
