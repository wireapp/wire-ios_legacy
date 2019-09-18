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


extension ConversationListViewModel {

    @objc public func subscribeToTeamsUpdates() {
        if let session = ZMUserSession.shared() {
            selfUserObserver = UserChangeInfo.add(observer: self, for: ZMUser.selfUser(), userSession: session)
        }
    }

    @objc(selectItem:)
    @discardableResult
    func select(itemToSelect: Any?) -> Bool {
        guard let itemToSelect = itemToSelect else {
            selectedItem = nil
            delegate?.listViewModel(self, didSelectItem: nil)

            return false
        }

        let indexPath: IndexPath? = self.indexPath(forItem: itemToSelect as! NSObjectProtocol)

        // Couldn't find the item
        if indexPath == nil,
            let conversation = itemToSelect as? ZMConversation {

            let containedInOtherLists = conversation.revealClearedOrArchived(userSession: ZMUserSession.shared(), completionHandler: nil)

            if containedInOtherLists {
                selectedItem = itemToSelect as? UITabBarItem
                delegate?.listViewModel(self, didSelectItem: itemToSelect)

                return true
            }

            return false
        }

        selectedItem = itemToSelect as? UITabBarItem
        delegate?.listViewModel(self, didSelectItem: itemToSelect)

        return true
    }
}


extension ConversationListViewModel: ZMUserObserver {

    public func userDidChange(_ note: UserChangeInfo) {
        if note.teamsChanged {
            updateConversationListAnimated()
        }
    }

}
