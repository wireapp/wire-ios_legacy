
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

extension ConversationListViewModel {
    @objc
    func setupObserversForListReloading() {
        guard let userSession = ZMUserSession.shared() else {
            return
        }

        conversationListsReloadObserverToken = ConversationListChangeInfo.add(observer: self, userSession: userSession)
    }

    @objc
    func setupObserversForActiveTeam() {
        guard let userSession = ZMUserSession.shared() else {
            return
        }

        pendingConversationListObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.pendingConnectionConversations(inUserSession: userSession), userSession: userSession)

        conversationListObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.conversations(inUserSession: userSession), userSession: userSession)

        clearedConversationListObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.clearedConversations(inUserSession: userSession), userSession: userSession)
    }

    func sectionCount() -> UInt {
        return aggregatedItems.numberOfSections()
    }

    func numberOfItems(inSection sectionIndex: UInt) -> UInt {
        return aggregatedItems.numberOfItems(inSection: sectionIndex)
    }

    @objc(sectionAtIndex:)
    func section(at sectionIndex: UInt) -> [Any]? {
        if sectionIndex >= sectionCount() {
            return nil
        }
        return aggregatedItems.section(at: sectionIndex)
    }

    func item(for indexPath: IndexPath?) -> NSObjectProtocol? {
        return aggregatedItems.item(for: indexPath)
    }

    func indexPath(for item: NSObject) -> IndexPath? {
        return aggregatedItems.indexPath(forItem: item)
    }

    func isConversation(at indexPath: IndexPath?) -> Bool {
        let obj = item(for: indexPath)
        return obj is ZMConversation
    }

    func indexPath(forConversation conversation: NSObject) -> IndexPath? {

        var result: IndexPath? = nil
        ///TODO: use dictionary instead of searching?
        aggregatedItems.enumerateItems({ section, sectionIndex, item, itemIndex, stop in
            if let itemObj = item as? NSObject, itemObj == conversation {
                result = IndexPath(item: Int(itemIndex), section: Int(sectionIndex))
                //                stop = true
            }
        })

        return result
    }

    func newConversationList() -> [ZMConversation]? {
        guard let userSession = ZMUserSession.shared() else { return nil }

        return ZMConversationList.conversations(inUserSession: userSession).map { $0 } as? [ZMConversation]
    }

    func newOneOnOneConversationList() -> [ZMConversation]? {
        return ZMUserSession.shared()?.oneOnOneConversations.map { $0 }
    }

    func reload() {
        updateAllSections()
        setupObserversForActiveTeam()
        //        debugLog("RELOAD conversation list")
        delegate?.listViewModelShouldBeReloaded()
    }

    func conversationListsDidReload() {
        reload()
    }

    // Select the item at an index path
    func selectItem(at indexPath: IndexPath?) -> Any? {
        let item = self.item(for: indexPath)
        select(itemToSelect: item)
        return item
    }


    /// Search for next items
    ///
    /// - Parameters:
    ///   - index: <#index description#>
    ///   - sectionIndex: <#sectionIndex description#>
    /// - Returns: <#return value description#>
    func item(after index: Int, section sectionIndex: UInt) -> IndexPath? {
        guard let section = self.section(at: sectionIndex) else { return nil }

        if section.count > index + 1 {
            // Select next item in section
            return IndexPath(item: index + 1, section: Int(sectionIndex))
        } else if index >= section.count {
            // select last item in previous section
            return firstItemInSection(after: sectionIndex)
        }

        return nil
    }

    func firstItemInSection(after sectionIndex: UInt) -> IndexPath? {
        let nextSectionIndex = sectionIndex + 1

        if nextSectionIndex >= sectionCount {
            // we are at the end, so return nil
            return nil
        }

        let section = self.section(at: nextSectionIndex)
        if section != nil {

            if section?.count > 0 {
                return IndexPath(item: 0, section: Int(nextSectionIndex))
            } else {
                // Recursively move forward
                return firstItemInSection(after: nextSectionIndex)
            }
        }

        return nil
    }


    /// Search for previous items
    ///
    /// - Parameters:
    ///   - index: <#index description#>
    ///   - sectionIndex: <#sectionIndex description#>
    /// - Returns: <#return value description#>
    func itemPrevious(to index: Int, section sectionIndex: UInt) -> IndexPath? {
        guard let section = self.section(at: sectionIndex) else { return nil }

        if index > 0 && section.count > index - 1 {
            // Select previous item in section
            return IndexPath(item: index - 1, section: Int(sectionIndex))
        } else if index == 0 {
            // select last item in previous section
            return lastItemInSectionPrevious(to: sectionIndex)
        }

        return nil
    }

    func lastItemInSectionPrevious(to sectionIndex: UInt) -> IndexPath? {
        let previousSectionIndex = sectionIndex - 1

        if previousSectionIndex < 0 {
            // we are at the top, so return nil
            return nil
        }

        guard let section = self.section(at: previousSectionIndex) else { return nil }

        if section.count > 0 {
            return IndexPath(item: section.count - 1, section: Int(previousSectionIndex))
        } else {
            // Recursively move back
            return lastItemInSectionPrevious(to: previousSectionIndex)
        }
    }

}
