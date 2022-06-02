//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import WireDataModel

extension ConversationListChangeInfo {
    public static func add(observer: ZMConversationListObserver,
                           for list: ZMConversationList,
                           userSession: ZMUserSession
        ) -> NSObjectProtocol {
        return self.addListObserver(observer, for: list, managedObjectContext: userSession.managedObjectContext)
    }

    public static func add(observer: ZMConversationListReloadObserver, userSession: ZMUserSession) -> NSObjectProtocol {
        return addReloadObserver(observer, managedObjectContext: userSession.managedObjectContext)
    }
}
