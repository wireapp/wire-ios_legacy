
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
    enum Section: CaseIterable {
        /// for incoming requests
        case contactRequests

        /// for self pending requests / conversations
        case conversations

        /// one to one conversations
        case contacts

        /// gorup conversations
        case group

        ///TODO:
        //    case customFolder(folder: FolderType)
    }

    private struct Folder {
        var section: Section
        var items: [AnyHashable]

        /// ref to AggregateArray, we return the first found item's index
        ///
        /// - Parameter item: item to search
        /// - Returns: the index of the item
        func index(for item: AnyHashable) -> Int? {
            return items.firstIndex(of: item)
        }

        init(section: Section) {
            items = ConversationListViewModel.newList(for: section)
            self.section = section
        }
    }

    @objc
    static let contactRequestsItem: ConversationListConnectRequestsItem = ConversationListConnectRequestsItem()

    /// ZMConversaton or ConversationListConnectRequestsItem
    ///TODO: protocol
    @objc
    private(set) var selectedItem: Any?

    @objc
    weak var delegate: ConversationListViewModelDelegate?

    private weak var selfUserObserver: NSObjectProtocol?

    var folderEnabled = true {///TODO: read/write to storage
        didSet {
            guard folderEnabled != oldValue else { return }

            updateAllSections()
            delegate?.listViewModelShouldBeReloaded()
        }
    }

    // Local copies of the lists.
    private var folders: [Folder] = []

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

        ///TODO:
        //        conversationDirectoryToken = userSession.conversationDirectory.addObserver(self)
        conversationDirectoryToken = userSession.managedObjectContext.conversationListDirectory().addObserver(self)
    }

    @objc
    var sectionCount: UInt {
        return UInt(folders.count)
    }

    ///TODO: convert all UInt to Int
    @objc
    func numberOfItems(inSection sectionIndex: UInt) -> UInt {
        guard sectionIndex < sectionCount else { return 0 }

        return UInt(folders[Int(sectionIndex)].items.count)
    }

    private
    func numberOfItems(in section: Section) -> Int? {
        for (folder) in folders {
            if folder.section == section {
                return folder.items.count
            }
        }

        return nil
    }

    @objc(sectionAtIndex:)
    func section(at sectionIndex: UInt) -> [AnyHashable]? {
        if sectionIndex >= sectionCount {
            return nil
        }

        return folders[Int(sectionIndex)].items
    }

    @objc(itemForIndexPath:)
    func item(for indexPath: IndexPath) -> AnyHashable? {
        return section(at: UInt(indexPath.section))?[indexPath.item]
    }

    ///TODO: Question: we may have multiple items in folders now. return array of IndexPaths?
    @objc(indexPathForItem:)
    func indexPath(for item: AnyHashable?) -> IndexPath? {
        guard let item = item else { return nil } 

        for (folderIndex, folder) in folders.enumerated() {
            if let index = folder.index(for: item) {
                return IndexPath(item: index, section: folderIndex)
            }
        }

        return nil
    }

    private static func newList(for section: Section) -> [AnyHashable] {
        guard let userSession = ZMUserSession.shared() else { return [] }

        switch section {
        case .contactRequests:
            return  ZMConversationList.pendingConnectionConversations(inUserSession: userSession).count > 0 ? [contactRequestsItem] : []
        case .conversations:
            return ZMConversationList.conversations(inUserSession: userSession).map { $0 } as? [ZMConversation] ?? []
        case .contacts:
            return ZMUserSession.shared()?.oneToOneConversations.map { $0 } ?? []
        case .group:
            return ZMUserSession.shared()?.groupConversations.map { $0 } ?? []
        }
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
    ///   - index: index of search item
    ///   - sectionIndex: section of search item
    /// - Returns: an index path for next existing item
    @objc(itemAfterIndex:section:)
    func item(after index: Int, section sectionIndex: UInt) -> IndexPath? {
        guard let section = self.section(at: sectionIndex) else { return nil }

        if section.count > index + 1 {
            // Select next item in section
            return IndexPath(item: index + 1, section: Int(sectionIndex))
        } else if index + 1 >= section.count {
            // select last item in previous section
            return firstItemInSection(after: sectionIndex)
        }

        return nil
    }

    private func firstItemInSection(after sectionIndex: UInt) -> IndexPath? {
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
    ///   - index: index of search item
    ///   - sectionIndex: section of search item
    /// - Returns: an index path for previous existing item
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
        for section in Section.allCases {
            let items = ConversationListViewModel.newList(for: section)

            updateSection(section: section, withItems: items)
        }
    }

    /// This updates a specific section in the model, by copying the contents locally.
    /// Passing in a value of SectionIndexAll updates all sections. The reason why we need to keep
    /// local copies of the lists is that we get separate notifications for each list,
    /// which means that an update to one can render the collection view out of sync with the datasource.
    ///
    /// - Parameters:
    ///   - sectionIndex: the section to update
    ///   - items: updated items
    func updateSection(section: Section, withItems items: [AnyHashable]?) {

        /// replace the section with new items if section found
        if let sectionNumber = self.sectionNumber(for: section) {
            folders[sectionNumber].items = items ?? []
        } else {
            // Re-create the folders
            createFolders()

            if let sectionNumber = self.sectionNumber(for: section) {
                folders[sectionNumber].items = items ?? []
            }
        }
    }


    /// Create the folder structure
    private func createFolders() {
        if folderEnabled {
            folders = [Folder(section: .contactRequests),
                       Folder(section: .group),
                       Folder(section: .contacts)]
        } else {
            folders = [Folder(section: .contactRequests),
                       Folder(section: .conversations)]
        }
    }

    private func folderItems(for section: Section) -> [AnyHashable]? {
        for folder in folders {
            if folder.section == section {
                return folder.items
            }
        }

        return nil
    }

    private func sectionNumber(for section: Section) -> Int? {
        for (index, folder) in folders.enumerated() {
            if folder.section == section {
                return index
            }
        }

        return nil
    }

    @discardableResult
    private func updateForConversationType(section: Section) -> Bool {
        guard let sectionNumber = self.sectionNumber(for: section) else { return false }

        let newConversationList = ConversationListViewModel.newList(for: section)

        if let oldConversationList = folderItems(for: section),
            oldConversationList != newConversationList {

            ///TODO: use diff kit and retire requiresReload
            let startState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: oldConversationList))
            let endState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: newConversationList))
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
                    self.updateSection(section: section, withItems: newConversationList)
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
            folderSections.forEach() {
                updateForConversationType(section: $0)
            }
        }
    }

    private var folderSections: [Section] {
        return folders.map() { return $0.section}
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

extension ConversationListViewModel: ZMUserObserver {

    public func userDidChange(_ note: UserChangeInfo) {
        if note.teamsChanged {
            updateConversationListAnimated()
        }
    }
}

extension ConversationListViewModel: ConversationDirectoryObserver {
    func conversationDirectoryDidChange(_ changeInfo: ConversationDirectoryChangeInfo) {
        if changeInfo.reloaded {
            // If the section was empty in certain cases collection view breaks down on the big amount of conversations,
            // so we prefer to do the simple reload instead.
            reload()
        } else {
            for updatedList in changeInfo.updatedLists {
                switch updatedList {
                case .unarchived:
                    updateForConversationType(section: .conversations)
                case .contacts:
                    updateForConversationType(section: .contacts)
                case .pending:
                    updateForConversationType(section: .contactRequests)
                case .groups:
                    updateForConversationType(section: .group)
                case .archived:
                    break
                }
            }
        }
    }
}
