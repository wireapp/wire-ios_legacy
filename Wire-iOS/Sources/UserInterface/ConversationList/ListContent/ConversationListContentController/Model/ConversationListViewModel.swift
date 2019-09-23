
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
///TODO: create a protocol, shared with ZMConversation
@objc
final class ConversationListConnectRequestsItem : NSObject {}


final class ConversationListViewModel: NSObject {
    struct Folder {
        var sectionIndex: SectionIndex
        var items: [AnyHashable]

        /// ref to AggregateArray, we return the first found item's index
        ///
        /// - Parameter item: item to search
        /// - Returns: the index of the item
        func index(for item: NSObject) -> Int? {
            return items.firstIndex(of: item)
        }
    }

    @objc
    let contactRequestsItem: ConversationListConnectRequestsItem = ConversationListConnectRequestsItem()

    /// ZMConversaton or ConversationListConnectRequestsItem
    ///TODO: protocol
    @objc
    private(set) var selectedItem: Any?

    @objc
    weak var delegate: ConversationListViewModelDelegate?

    private weak var selfUserObserver: NSObjectProtocol?

    private var folderEnabled = false {
        didSet {
            guard folderEnabled != oldValue else { return }

            updateAllSections()
            delegate?.listViewModelShouldBeReloaded()
        }
    }

    // Local copies of the lists.
    private var folders: [Folder] = []

    ///TODO: retire
//    private var pendingConversationListObserverToken: Any?
//    private var conversationListObserverToken: Any?
//    private var clearedConversationListObserverToken: Any?
//    private var conversationListsReloadObserverToken: Any?

    private var conversationDirectoryToken: Any?


    override init() {
        super.init()

        updateAllSections()
        setupObservers()
        subscribeToTeamsUpdates()
    }

    private func setupObservers() {
        guard let userSession = ZMUserSession.shared() else {
            return
        }

//        conversationListsReloadObserverToken = ConversationListChangeInfo.add(observer: self, userSession: userSession)

        ///TODO:
//        conversationDirectoryToken = userSession.conversationDirectory.addObserver(self)

        conversationDirectoryToken = userSession.managedObjectContext.conversationListDirectory().addObserver(self)


        ///TODO: retire
//        pendingConversationListObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.pendingConnectionConversations(inUserSession: userSession), userSession: userSession)
//
//        conversationListObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.conversations(inUserSession: userSession), userSession: userSession)
//
//        clearedConversationListObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.clearedConversations(inUserSession: userSession), userSession: userSession)

        ///TODO: oberve more lists?
    }

    @objc
    var sectionCount: UInt {
//        return aggregatedItems.numberOfSections()
        return UInt(folders.count)
    }

    ///TODO: test for out of bound cases
    ///TODO: convert all UInt to Int
    @objc
    func numberOfItems(inSection sectionIndex: UInt) -> UInt {
        guard sectionIndex < sectionCount else { return 0 }

        return UInt(folders[Int(sectionIndex)].items.count)
    }

    private
    func numberOfItems(in sectionIndex: SectionIndex) -> Int? {
        for (folder) in folders {
            if folder.sectionIndex == sectionIndex {
                return folder.items.count
            }
        }

        return nil
    }

    @objc(sectionAtIndex:)
    func section(at sectionIndex: UInt) -> [Any]? {
        if sectionIndex >= sectionCount {
            return nil
        }

        return folders[Int(sectionIndex)].items
    }

    ///TODO: out of bound test
    @objc(itemForIndexPath:)
    func item(for indexPath: IndexPath) -> NSObject? {
        return section(at: UInt(indexPath.section))?[indexPath.item] as? NSObject
    }

    ///Question: we may have multiple items in folders now.
    ///TODO: test
    @objc(indexPathForItem:)
    func indexPath(for item: NSObject?) -> IndexPath? {
        guard let item = item else { return nil } 

        for (folderIndex, folder) in folders.enumerated() {
            if let index = folder.index(for: item) {
                return IndexPath(item: index, section: folderIndex)
            }
        }

        return nil
    }

    ///TODO: new methods with SectionIndex as param
    func newConversationList() -> [ZMConversation] {
        guard let userSession = ZMUserSession.shared() else { return [] }

        return ZMConversationList.conversations(inUserSession: userSession).map { $0 } as? [ZMConversation] ?? []
    }

    func newOneOnOneConversationList() -> [ZMConversation] {
        return ZMUserSession.shared()?.oneToOneConversations.map { $0 } ?? []
    }

    private
    func reload() {
        updateAllSections()
        setupObservers()
        log.debug("RELOAD conversation list")
        delegate?.listViewModelShouldBeReloaded()
    }

    /// Select the item at an index path
    ///
    /// - Parameter indexPath: indexPath of the item to select
    /// - Returns: the item selected
    @objc(selectItemAtIndexPath:)
    @discardableResult
    func selectItem(at indexPath: IndexPath) -> Any? {
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

        if let section = self.section(at: nextSectionIndex) {
            if section.count > 0 {
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
        folderEnabled = !folderEnabled
    }


    @objc
    func updateAllSections() {
        updateSection(sectionIndexs: SectionIndex.allCases)
    }

    func updateSection(_ sectionIndex: SectionIndex, withItems items: [AnyHashable]? = nil) {
        updateSection(sectionIndexs: [sectionIndex], withItems: items)
    }

    /// This updates a specific section in the model, by copying the contents locally.
    /// Passing in a value of SectionIndexAll updates all sections. The reason why we need to keep
    /// local copies of the lists is that we get separate notifications for each list,
    /// which means that an update to one can render the collection view out of sync with the datasource.
    ///
    /// - Parameter sectionIndex: the section to update
    func updateSection(sectionIndexs: [SectionIndex], withItems items: [AnyHashable]? = nil) {
        if sectionIndexs == SectionIndex.allCases && items != nil {
            assert(true, "Update for all sections with proposed items is not allowed.")
        }


        ///TODO: non optional, store in folders directly
        var inbox = folderItems(for: .contactRequests)
        var conversations = folderItems(for: .conversations)
        ///TODO: ignore this when folded not enabled
        var oneOnOneConversations = folderItems(for: .contacts)

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
                if let items = items {
                    conversations = items
                } else {
                    conversations = newConversationList()
                }
            case .contacts:
                if let items = items {
                    oneOnOneConversations = items
                } else {
                    oneOnOneConversations = newOneOnOneConversationList()
                }
            }
        }


        // Re-create the folders
        if folderEnabled {
            folders = [Folder(sectionIndex: .contactRequests, items: inbox ?? []),
                       Folder(sectionIndex: .contacts, items: oneOnOneConversations ?? []),
                       Folder(sectionIndex: .conversations, items: conversations ?? [])]
        } else {
            folders = [Folder(sectionIndex: .contactRequests, items: inbox ?? []),
                       Folder(sectionIndex: .conversations, items: conversations ?? [])]
        }
    }

    private func folderItems(for sectionIndex: SectionIndex) -> [AnyHashable]? {
        for folder in folders {
            if folder.sectionIndex == sectionIndex {
                return folder.items
            }
        }

        return nil
    }

    private func sectionNumber(for sectionIndex: SectionIndex) -> Int? {
        for (index, folder) in folders.enumerated() {
            if folder.sectionIndex == sectionIndex {
                return index
            }
        }

        return nil
    }

    @discardableResult
    func updateForConvoType(sectionIndex: SectionIndex) -> Bool {
        guard let sectionNumber = self.sectionNumber(for: sectionIndex) else { return false }

        ///TODO: mv to method
        let newList: [ZMConversation]

        switch sectionIndex {
        case .contacts:
            newList = newOneOnOneConversationList()
        case .conversations:
            newList = newConversationList()
        default:
            return false
        }

        if let oldConversationList = folderItems(for: sectionIndex) as? [ZMConversation],
            oldConversationList != newList {

            ///TODO: use diff kit and retire requiresReload
            let startState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: oldConversationList))
            let endState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: newList))
            let updatedState = ZMOrderedSetState(orderedSet: [])

            guard let changedIndexes = ZMChangedIndexes(start: startState, end: endState, updatedState: updatedState, moveType: ZMSetChangeMoveType.uiCollectionView) else { return true}

            if changedIndexes.requiresReload {
                reload()
            } else {
                // We need to capture the state of `newConversationList` to make sure that we are updating the value
                // of the list to the exact new state.
                // It is important to keep the data source of the collection view consistent, since
                // any inconsistency in the delta update would make it throw an exception.
                let modelUpdates = {
                    self.updateSection(sectionIndex, withItems: newList)
                }
                
                delegate?.listViewModel(self, didUpdateSection: UInt(sectionNumber), usingBlock: modelUpdates, with: changedIndexes)
            }

            return true
        }

        return false
    }

    private func updateConversationListAnimated() {
        /// reload if all sections are empty
        if numberOfItems(in: .conversations) == 0 &&
           numberOfItems(in: .contacts) == 0 {
            reload()
        } else {
            ///TODO: loop for sections in folders
            updateForConvoType(sectionIndex: .conversations)
            updateForConvoType(sectionIndex: .contacts)
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
        if self.indexPath(for: itemToSelect as? NSObject) == nil {
            (itemToSelect as? ZMConversation)?.unarchive()
        }

        selectedItem = itemToSelect
        delegate?.listViewModel(self, didSelectItem: itemToSelect)

        return true
    }

    func subscribeToTeamsUpdates() {
        guard let session = ZMUserSession.shared() else { return }

        selfUserObserver = UserChangeInfo.add(observer: self, for: ZMUser.selfUser(), userSession: session)
    }

}

fileprivate let log = ZMSLog(tag: "ConversationListViewModel")

///TODO: retire
extension ConversationListViewModel: ZMConversationListReloadObserver {
    func conversationListsDidReload() {
        reload()
    }
}

extension ConversationListViewModel: ZMUserObserver {

    public func userDidChange(_ note: UserChangeInfo) {
        if note.teamsChanged {
            updateConversationListAnimated()
        }
    }
}

extension ConversationListViewModel: ConversationDirectoryObserver {
    func conversationDirectoryDidChange(_ changeInfo: ConversationDirectoryChangeInfo) {

//        guard let userSession = ZMUserSession.shared() else { return }

        ///TODO: check the info instead of compare the lists
        if changeInfo.reloaded {
            // If the section was empty in certain cases collection view breaks down on the big amount of conversations,
            // so we prefer to do the simple reload instead.
            reload()
        } else {
            updateConversationListAnimated() ///TODO: update oneOneOne also
//            log.info("RELOAD section requests")
//                let dir = userSession.managedObjectContext.
//
////            let sectionIndex = SectionIndex.contactRequests
//            updateSection(sectionIndex)
//
//            if let sectionNumber = sectionNumber(for: sectionIndex) {
//                delegate?.listViewModel(self, didUpdateSectionForReload: UInt(sectionNumber))
//            }
        }

    }
}

///TODO: retire
extension ConversationListViewModel: ZMConversationListObserver {

    ///TODO: still need to observe for single cell changes?
    public func conversationInsideList(_ list: ZMConversationList, didChange changeInfo: ConversationChangeInfo) {
        delegate?.listViewModel(self, didUpdateConversationWithChange: changeInfo)
    }

    public func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
//        return
        ///TODO: no op
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

            if let sectionNumber = sectionNumber(for: sectionIndex) {
                delegate?.listViewModel(self, didUpdateSectionForReload: UInt(sectionNumber))
            }
        }
    }
}
