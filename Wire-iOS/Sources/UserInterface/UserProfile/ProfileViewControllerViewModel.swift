//
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

enum ProfileViewControllerContext {
    case search
    case groupConversation
    case oneToOneConversation
    case deviceList
    /// when opening from a URL scheme, not linked to a specific conversation
    case profileViewer
}

final class ProfileViewControllerViewModel {
    let bareUser: UserType
    let conversation: ZMConversation?
    let viewer: UserType
    let context: ProfileViewControllerContext

    init(bareUser: UserType,
         conversation: ZMConversation?,
         viewer: UserType,
         context: ProfileViewControllerContext) {
        self.bareUser = bareUser
        self.conversation = conversation
        self.viewer = viewer
        self.context = context
    }
    
    var fullUser: ZMUser? {
        return bareUser.zmUser
    }

    var hasLegalHoldItem: Bool {
        return bareUser.isUnderLegalHold || conversation?.isUnderLegalHold == true
    }
    
    var showVerifiedShield: Bool {
        if let user = bareUser.zmUser {
            let showShield = user.trusted() &&
                !user.clients.isEmpty &&
                context != .deviceList &&
                tabsController?.selectedIndex != ProfileViewControllerTabBarIndex.devices.rawValue && ZMUser.selfUser().trusted()
            
            return showShield
        } else {
            return false
        }
    }
    
    var hasUserClientListTab: Bool {
        return nil != self.fullUser, context != .search && context != .profileViewer
    }
}
