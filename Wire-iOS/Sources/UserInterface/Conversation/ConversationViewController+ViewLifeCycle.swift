// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireSyncEngine

extension ConversationViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateLeftNavigationBarItems()

        if isFocused {
            // We are presenting the conversation screen so mark it as the last viewed screen,
            // but only if we are acutally focused (otherwise we would be shown on the next launch)
            Settings.shared[.lastViewedScreen] = SettingsLastScreen.conversation
            if let currentAccount = SessionManager.shared?.accountManager.selectedAccount {
                Settings.shared.setLastViewed(conversation: conversation, for: currentAccount)
            }
        }

        contentViewController.searchQueries = collectionController?.currentTextSearchQuery ?? []

        ZMUserSession.shared()?.didOpen(conversation: conversation)

        isAppearing = false
    }
}
