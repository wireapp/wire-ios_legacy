
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

// Placeholder for conversation requests item
@objc
final class ConversationListConnectRequestsItem : NSObject {}

final class ConversationListViewModel: NSObject {
    @objc
    let contactRequestsItem: ConversationListConnectRequestsItem = ConversationListConnectRequestsItem()

    /// ZMConversaton or ConversationListConnectRequestsItem
    @objc
    private(set) var selectedItem: Any?

    @objc
    weak var delegate: ConversationListViewModelDelegate?

    private weak var selfUserObserver: NSObjectProtocol?
    private var isFolderEnable = false
    private var aggregatedItems: AggregateArray!
    // Local copies of the lists.

    ///TODO: [[Any]]
    ///TODO: non optional
    private var inbox: [Any]? = []
    private var conversations: [Any]? = []
    private var oneOnOneConversations: [Any]? = []

    private var pendingConversationListObserverToken: Any?
    private var conversationListObserverToken: Any?
    private var clearedConversationListObserverToken: Any?
    private var conversationListsReloadObserverToken: Any?


    override init() {
        super.init()
        isFolderEnable = true

        updateAllSections()
        setupObserversForListReloading()
        setupObserversForActiveTeam()
        subscribeToTeamsUpdates()
    }

    func setupObserversForListReloading() {
        guard let userSession = ZMUserSession.shared() else {
            return
        }

        conversationListsReloadObserverToken = ConversationListChangeInfo.add(observer: self, userSession: userSession)
    }

    func setupObserversForActiveTeam() {
        guard let userSession = ZMUserSession.shared() else {
            return
        }

        pendingConversationListObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.pendingConnectionConversations(inUserSession: userSession), userSession: userSession)

        conversationListObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.conversations(inUserSession: userSession), userSession: userSession)

        clearedConversationListObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.clearedConversations(inUserSession: userSession), userSession: userSession)
    }

    @objc
    var sectionCount: UInt {
        return aggregatedItems.numberOfSections()
    }

    @objc
    func numberOfItems(inSection sectionIndex: UInt) -> UInt {
        return aggregatedItems.numberOfItems(inSection: sectionIndex)
    }

    @objc(sectionAtIndex:)
    func section(at sectionIndex: UInt) -> [Any]? {
        if sectionIndex >= sectionCount {
            return nil
        }
        return aggregatedItems.section(at: sectionIndex)
    }

    @objc(itemForIndexPath:)
    func item(for indexPath: IndexPath?) -> NSObjectProtocol? {
        return aggregatedItems.item(for: indexPath)
    }

    @objc(indexPathForItem:)
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

    func newConversationList() -> [ZMConversation] {
        guard let userSession = ZMUserSession.shared() else { return [] }

        return ZMConversationList.conversations(inUserSession: userSession).map { $0 } as? [ZMConversation] ?? []
    }

    func newOneOnOneConversationList() -> [ZMConversation] {
        return ZMUserSession.shared()?.oneOnOneConversations.map { $0 } ?? []
    }

    func reload() {
        updateAllSections()
        setupObserversForActiveTeam()
        //        debugLog("RELOAD conversation list")
        delegate?.listViewModelShouldBeReloaded()
    }

    /// Select the item at an index path
    ///
    /// - Parameter indexPath: <#indexPath description#>
    /// - Returns: <#return value description#>
    @objc(selectItemAtIndexPath:)
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
    @objc(itemAfterIndex:section:)
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
    @objc(itemPreviousToIndex:section:)
    func itemPrevious(to index: Int, section sectionIndex: UInt) -> IndexPath? {
        guard let section = self.section(at: sectionIndex) else { return nil }

        if index > 0 && section.count > index - 1 {
            // Select previous item in section
            return IndexPath(item: index - 1, section: Int(sectionIndex))
        } else if index == 0 {
            // select last item in previous section
            return lastItemInSectionPrevious(to: Int(sectionIndex))
        }

        return nil
    }

    func lastItemInSectionPrevious(to sectionIndex: Int) -> IndexPath? {
        let previousSectionIndex = sectionIndex - 1

        if previousSectionIndex < 0 {
            // we are at the top, so return nil
            return nil
        }

        guard let section = self.section(at: UInt(previousSectionIndex)) else { return nil }

        if section.count > 0 {
            return IndexPath(item: section.count - 1, section: Int(previousSectionIndex))
        } else {
            // Recursively move back
            return lastItemInSectionPrevious(to: previousSectionIndex)
        }
    }

    ///TODO: for debug
    func toggleSort() {
        isFolderEnable = !isFolderEnable

        updateAllSections()
        delegate?.listViewModelShouldBeReloaded()
    }


    @objc
    func updateAllSections() {
        updateSection(sectionIndexs: SectionIndex.allCases)
    }

    func updateSection(_ sectionIndex: SectionIndex, withItems items: [Any]? = nil) {
        updateSection(sectionIndexs: [sectionIndex], withItems: items)
    }

    /// This updates a specific section in the model, by copying the contents locally.
    /// Passing in a value of SectionIndexAll updates all sections. The reason why we need to keep
    /// local copies of the lists is that we get separate notifications for each list,
    /// which means that an update to one can render the collection view out of sync with the datasource.
    ///
    /// - Parameter sectionIndex: the section to update
    func updateSection(sectionIndexs: [SectionIndex], withItems items: [Any]? = nil) {
        if sectionIndexs == SectionIndex.allCases && items != nil {
            assert(true, "Update for all sections with proposed items is not allowed.")
        }

        for sectionIndex in sectionIndexs {
            switch sectionIndex {
            case .contactRequests:
                if let userSession = ZMUserSession.shared(), ZMConversationList.pendingConnectionConversations(inUserSession: userSession).count > 0 {
                    inbox = items ?? [contactRequestsItem]
                } else {
                    inbox = []
                }
            case .conversations:
                // Make a new copy of the conversation list
                conversations = items ?? newConversationList()
            case .contactsConversations:
                oneOnOneConversations = items ?? newOneOnOneConversationList()
            }
        }


        ///TODO: use a dictionary instead of fix size array
        // Re-create the aggregate array
        let sections: [Any]

        if isFolderEnable {
            sections = [inbox ?? [],
                        oneOnOneConversations ?? [],
                        conversations ?? []]
        } else {
            sections = [inbox ?? [],
                        conversations ?? []]
        }

        aggregatedItems = AggregateArray(sections: sections)
    }

    @discardableResult
    func updateForConvoType(sectionIndex: SectionIndex) -> Bool {
        let sectionNumber = sectionIndex.sectionNumber(isFolderEnable: isFolderEnable)
        let newList = newConversationList()

        if let oldConversationList = aggregatedItems.section(at: sectionNumber) as? [ZMConversation],
            oldConversationList != newList {

            ///TODO: use diff kit and retire requiresReload
            let startState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: oldConversationList))
            let endState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: newList))
            let updatedState = ZMOrderedSetState(orderedSet: [])

            guard let changedIndexes = ZMChangedIndexes(start: startState, end: endState, updatedState: updatedState, moveType: ZMSetChangeMoveType.uiCollectionView) else { return true}

            if changedIndexes.requiresReload == true {
                reload()
            } else {
                // We need to capture the state of `newConversationList` to make sure that we are updating the value
                // of the list to the exact new state.
                // It is important to keep the data source of the collection view consistent, since
                // any inconsistency in the delta update would make it throw an exception.
                let modelUpdates = {
                    self.updateSection(sectionIndex, withItems: newList)
                }
                delegate?.listViewModel(self, didUpdateSection: sectionNumber, usingBlock: modelUpdates, with: changedIndexes)
            }

            return true
        }

        return false
    }

    func updateConversationListAnimated() {
        ///TODO: folder and non folder mode handling
        if numberOfItems(inSection: SectionIndex.conversations.sectionNumber(isFolderEnable: isFolderEnable)) == 0 &&
            numberOfItems(inSection: SectionIndex.contactsConversations.sectionNumber(isFolderEnable: isFolderEnable)) == 0 {

            reload()
        } else if !updateForConvoType(sectionIndex: .conversations) {
            updateForConvoType(sectionIndex: .contactsConversations)
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

        // Couldn't find the item
        if self.indexPath(for: itemToSelect as! NSObject) == nil {
            (itemToSelect as? ZMConversation)?.unarchive()
        }

        selectedItem = itemToSelect
        delegate?.listViewModel(self, didSelectItem: itemToSelect)

        return true
    }

    @objc
    func subscribeToTeamsUpdates() {
        if let session = ZMUserSession.shared() {
            selfUserObserver = UserChangeInfo.add(observer: self, for: ZMUser.selfUser(), userSession: session)
        }
    }

}

fileprivate let log = ZMSLog(tag: "ConversationListViewModel")

extension ConversationListViewModel: ZMConversationListObserver {

    public func conversationInsideList(_ list: ZMConversationList, didChange changeInfo: ConversationChangeInfo) {
        delegate?.listViewModel(self, didUpdateConversationWithChange: changeInfo)
    }

    public func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        guard let userSession = ZMUserSession.shared() else { return }

        ///TODO: check the info instead of compare the lists
        if changeInfo.conversationList == ZMConversationList.conversations(inUserSession: userSession) {
            // If the section was empty in certain cases collection view breaks down on the big amount of conversations,
            // so we prefer to do the simple reload instead.

            updateConversationListAnimated() ///TODO: update oneOneOne also
        } else if changeInfo.conversationList == ZMConversationList.pendingConnectionConversations(inUserSession: userSession) {
            log.info("RELOAD contact requests")

            let sectionIndex = SectionIndex.contactRequests
            updateSection(sectionIndex)

            delegate?.listViewModel(self, didUpdateSectionForReload: sectionIndex.sectionNumber(isFolderEnable: isFolderEnable))
        }
    }
}


extension ConversationListViewModel: ZMConversationListReloadObserver {
    func conversationListsDidReload() {
        reload()
    }
}
