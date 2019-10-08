
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

    fileprivate struct Section {
        enum Kind: String, CaseIterable, Codable {

            /// for incoming requests
            case contactRequests

            /// for self pending requests / conversations
            case conversations

            /// one to one conversations
            case contacts

            /// group conversations
            case groups

            /// favorites
            case favorites

            ///TODO: Bill - custom folder
            //    case folder(folder: FolderType)

            var title: String? {
                switch self {
                case .conversations:
                    return nil
                case .contactRequests:
                    return "list.section.requests".localized
                case .contacts:
                    return "list.section.contacts".localized
                case .groups:
                    return "list.section.groups".localized
                case .favorites:
                    return "list.section.favorites".localized
                }
            }
        }

        var kind: Kind
        var items: [AnyHashable]

        /// ref to AggregateArray, we return the first found item's index
        ///
        /// - Parameter item: item to search
        /// - Returns: the index of the item
        func index(for item: AnyHashable) -> Int? {
            return items.firstIndex(of: item)
        }

        init(kind: Kind, userSession: UserSessionSwiftInterface?) {
            items = ConversationListViewModel.newList(for: kind, userSession: userSession)
            self.kind = kind
        }
    }

    @objc
    static let contactRequestsItem: ConversationListConnectRequestsItem = ConversationListConnectRequestsItem()

    /// current selected ZMConversaton or ConversationListConnectRequestsItem object
    ///TODO: create protocol of these 2 classes
    @objc
    private(set) var selectedItem: AnyHashable? {
        didSet {
            /// expend the section if selcted item is update
            guard selectedItem != oldValue,
                  let indexPath = self.indexPath(for: selectedItem),
                  collapsed(at: indexPath.section) else { return }

            setCollapsed(sectionIndex: indexPath.section, collapsed: false, batchUpdate: false)
        }
    }

    @objc
    weak var delegate: ConversationListViewModelDelegate?
    weak var restorationDelegate: ConversationListViewModelRestorationDelegate? {
        didSet {
            restorationDelegate?.listViewModel(self, didRestoreFolderEnabled: folderEnabled)
        }
    }

    private weak var selfUserObserver: NSObjectProtocol?

    var folderEnabled: Bool {
        set {
            guard newValue != state.folderEnabled else { return }

            state.folderEnabled = newValue
            
            updateAllSections()
            delegate?.listViewModelShouldBeReloaded()
            
            /// restore collapse state
            if state.folderEnabled {
                restoreCollapse()
            }
        }
        
        get {
            return state.folderEnabled
        }
    }

    // Local copies of the lists.
    private var sections: [Section] = []

    /// for folder enabled and collapse presistent
    private lazy var _state: State = {
        guard let persistentPath = ConversationListViewModel.persistentURL,
            let jsonData = try? Data(contentsOf: persistentPath) else { return State()
        }

        do {
            return try JSONDecoder().decode(ConversationListViewModel.State.self, from: jsonData)
        } catch {
            log.error("restore state error: \(error)")
            return State()
        }
    }()

    private var state: State {
        get {
            return _state
        }

        set {
            if newValue != _state {
                _state = newValue
            }

            /// simulate didSet
            saveState(state: _state)
        }
    }

    private var conversationDirectoryToken: Any?

    private let userSession: UserSessionSwiftInterface?

    init(userSession: UserSessionSwiftInterface? = ZMUserSession.shared()) {
        self.userSession = userSession

        super.init()

        setupObservers()
        subscribeToTeamsUpdates()

        updateAllSections()

        restoreState()
    }

    private func setupObservers() {
        guard let userSession = ZMUserSession.shared() else {
            return
        }

        conversationDirectoryToken = userSession.conversationDirectory.addObserver(self)
    }

    func sectionHeaderTitle(sectionIndex: Int) -> String? {
        return kind(of: sectionIndex)?.title
    }

    /// return true if seaction header is visible.
    /// For .contactRequests section it is always invisible
    /// When folderEnabled == true, returns false
    ///
    /// - Parameter sectionIndex: section number of collection view
    /// - Returns: if the section exists and visible, return true. 
    func sectionHeaderVisible(section: Int) -> Bool {
        guard sections.indices.contains(section),
              kind(of: section) != .contactRequests,
              folderEnabled else { return false }

        return sections[section].items.count > 0
    }


    private func kind(of sectionIndex: Int) -> Section.Kind? {
        guard sections.indices.contains(sectionIndex) else { return nil }

        return sections[sectionIndex].kind
    }


    /// get section's name in raw value
    ///
    /// - Parameter sectionIndex: section index of the collection view
    /// - Returns: raw value of the section's type
    func sectionName(of sectionIndex: Int) -> String? {
        return kind(of: sectionIndex)?.rawValue
    }

    @objc
    var sectionCount: UInt {
        return UInt(sections.count)
    }

    @objc
    func numberOfItems(inSection sectionIndex: Int) -> Int {
        guard sectionIndex < sectionCount,
              !collapsed(at: sectionIndex) else { return 0 }

        return sections[sectionIndex].items.count
    }

    private func numberOfItems(of kind: Section.Kind) -> Int? {
        return sections.first(where: { $0.kind == kind })?.items.count ?? nil
    }

    ///TODO: convert all UInt to Int
    @objc(sectionAtIndex:)
    func section(at sectionIndex: UInt) -> [AnyHashable]? {
        if sectionIndex >= sectionCount {
            return nil
        }

        return sections[Int(sectionIndex)].items
    }

    @objc(itemForIndexPath:)
    func item(for indexPath: IndexPath) -> AnyHashable? {
        return section(at: UInt(indexPath.section))?[indexPath.item]
    }

    ///TODO: Question: we may have multiple items in folders now. return array of IndexPaths?
    @objc(indexPathForItem:)
    func indexPath(for item: AnyHashable?) -> IndexPath? {
        guard let item = item else { return nil } 

        for (sectionIndex, section) in sections.enumerated() {
            if let index = section.index(for: item) {
                return IndexPath(item: index, section: sectionIndex)
            }
        }

        return nil
    }

    private static func newList(for kind: Section.Kind, userSession: UserSessionSwiftInterface?) -> [AnyHashable] {
        guard let userSession = userSession else { return [] } 

        let conversationListType: ConversationListType
        switch kind {
        case .contactRequests:
            conversationListType = .pending
            return userSession.conversations(by: conversationListType).count > 0 ? [contactRequestsItem] : []
        case .conversations:
            conversationListType = .unarchived
        case .contacts:
            conversationListType = .contacts
        case .groups:
            conversationListType = .groups
        case .favorites:
            conversationListType = .favorites
        }

        return userSession.conversations(by: conversationListType)
    }

    private func reload() {
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
    func selectItem(at indexPath: IndexPath) -> AnyHashable? {
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

    private func updateAllSections() {
        for section in Section.Kind.allCases {
            let items = ConversationListViewModel.newList(for: section, userSession: userSession)

            update(kind: section, with: items)
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
    private func update(kind: Section.Kind, with items: [AnyHashable]?) {

        /// replace the section with new items if section found
        if let sectionNum = sectionNumber(for: kind) {
            sections[sectionNum].items = items ?? []
        } else {
            // Re-create the sections
            createSections(replaceKind: kind, withReplaceItems: items)
        }
    }


    /// Create the section structure
    private func createSections(replaceKind: Section.Kind, withReplaceItems replaceItems: [AnyHashable]?) {
        let kinds: [Section.Kind]
        if folderEnabled {
            kinds = [.contactRequests,
                     .favorites,
                     .groups,
                     .contacts]
        } else {
            kinds = [.contactRequests,
                     .conversations]
        }

        sections = kinds.map{ Section(kind: $0, userSession: userSession) }

        if let sectionNumber = self.sectionNumber(for: replaceKind) {
            sections[sectionNumber].items = replaceItems ?? []
        }
    }

    private func sectionItems(for kind: Section.Kind) -> [AnyHashable]? {
        for section in sections {
            if section.kind == kind {
                return section.items
            }
        }

        return nil
    }

    private func sectionNumber(for kind: Section.Kind) -> Int? {
        for (index, section) in sections.enumerated() {
            if section.kind == kind {
                return index
            }
        }

        return nil
    }

    ///TODO: use diff kit and retire requiresReload
    private func changedIndexes(oldConversationList: [AnyHashable],
                                newConversationList: [AnyHashable]) -> ZMChangedIndexes? {
        let startState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: oldConversationList))
        let endState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: newConversationList))
        let updatedState = ZMOrderedSetState(orderedSet: [])
        
        return ZMChangedIndexes(start: startState, end: endState, updatedState: updatedState, moveType: ZMSetChangeMoveType.uiCollectionView)
    }
    
    @discardableResult
    private func updateForConversationType(kind: Section.Kind) -> Bool {
        guard let sectionNumber = self.sectionNumber(for: kind) else { return false }

        let newConversationList = ConversationListViewModel.newList(for: kind, userSession: userSession)

        /// no need to update collapsed section's cells but the section header, update the stored list
        /// hide section header if no items
        if (collapsed(at: sectionNumber) && newConversationList.count > 0) ||
           newConversationList.count == 0 {
            update(kind: kind, with: newConversationList)
            delegate?.listViewModel(self, didUpdateSectionForReload: UInt(sectionNumber))
            return true
        }

        if let oldConversationList = sectionItems(for: kind),
            oldConversationList != newConversationList {


            guard let changedIndexes = changedIndexes(oldConversationList: oldConversationList, newConversationList: newConversationList) else { return true }

            if changedIndexes.requiresReload {
                reload()
            } else {
                // We need to capture the state of `newConversationList` to make sure that we are updating the value
                // of the list to the exact new state.
                // It is important to keep the data source of the collection view consistent, since
                // any inconsistency in the delta update would make it throw an exception.
                let modelUpdates = {
                    self.update(kind: kind, with: newConversationList)
                }
                
                delegate?.listViewModel(self, didUpdateSection: UInt(sectionNumber), usingBlock: modelUpdates, with: changedIndexes)
            }

            return true
        }

        return false
    }

    private func updateAllConversations() {
        /// reload if all sections are empty
        if numberOfItems(of: .conversations) == 0 &&
            numberOfItems(of: .contacts) == 0 {
            reload()
        } else {
            sectionKinds.forEach() {
                updateForConversationType(kind: $0)
            }
        }
    }

    private var sectionKinds: [Section.Kind] {
        return sections.map() { return $0.kind}
    }

    @objc(selectItem:)
    @discardableResult
    func select(itemToSelect: AnyHashable?) -> Bool {
        guard let itemToSelect = itemToSelect else {
            internalSelect(itemToSelect: nil)
            return false
        }

        if indexPath(for: itemToSelect) == nil {
            guard let conversation = itemToSelect as? ZMConversation else { return false }

            ZMUserSession.shared()?.enqueueChanges({
                conversation.isArchived = false
            }, completionHandler: {
                self.internalSelect(itemToSelect: itemToSelect)
            })
        } else {
            internalSelect(itemToSelect: itemToSelect)
        }

        return true
    }

    private func internalSelect(itemToSelect: AnyHashable?) {
        selectedItem = itemToSelect
        delegate?.listViewModel(self, didSelectItem: itemToSelect)
    }

    func subscribeToTeamsUpdates() {
        guard let session = ZMUserSession.shared() else { return }

        selfUserObserver = UserChangeInfo.add(observer: self, for: ZMUser.selfUser(), userSession: session)
    }

    // MARK: - collapse section

    func collapsed(at sectionIndex: Int) -> Bool {
        guard let kind = kind(of: sectionIndex) else { return false }

        return state.collapsed.contains(kind)
    }

    func setCollapsed(sectionIndex: Int,
                      collapsed: Bool,
                      batchUpdate: Bool = true) {
        guard let kind = self.kind(of: sectionIndex) else { return }
        guard self.collapsed(at: sectionIndex) != collapsed else { return }

        if collapsed {
            state.collapsed.insert(kind)
        } else {
            state.collapsed.remove(kind)
        }

        if batchUpdate {
            let oldConversationList = collapsed ? sections[sectionIndex].items : []
            let newConversationList = collapsed ? [] : sections[sectionIndex].items

            let modelUpdates = {}

            guard let changedIndexes = changedIndexes(oldConversationList: oldConversationList, newConversationList: newConversationList) else { return }

            delegate?.listViewModel(self, didUpdateSection: UInt(sectionIndex), usingBlock: modelUpdates, with: changedIndexes)
        } else {
            UIView.performWithoutAnimation { ///TODO: mv UIKit method to VC
                self.delegate?.listViewModel(self, didUpdateSectionForReload: UInt(sectionIndex))
            }
        }
    }

    // MARK: - state presistent

    private struct State: Codable, Equatable {
        var collapsed: Set<Section.Kind>
        var folderEnabled: Bool

        init() {
            collapsed = []
            folderEnabled = false
        }

        var jsonString: String? {
            guard let jsonData = try? JSONEncoder().encode(self) else {
                return nil }

            return String(data: jsonData, encoding: .utf8)
        }
    }

    var jsonString: String? {
        return state.jsonString
    }

    private func saveState(state: State) {

        guard let jsonString = state.jsonString,
              let persistentDirectory = ConversationListViewModel.persistentDirectory,
              let directoryURL = URL.directoryURL(persistentDirectory) else { return }

        FileManager.default.createAndProtectDirectory(at: directoryURL)

        do {
            try jsonString.write(to: directoryURL.appendingPathComponent(ConversationListViewModel.persistentFilename), atomically: true, encoding: .utf8)
        } catch {
            log.error("error writing ConversationListViewModel to \(directoryURL): \(error)")
        }
    }

    private func restoreState() {
        folderEnabled = state.folderEnabled

        restoreCollapse()
    }

    private func restoreCollapse() {
        for (index, _) in sections.enumerated() {            
            if let kind = self.kind(of: index),
               let sectionNum = sectionNumber(for: kind) {
                setCollapsed(sectionIndex: sectionNum, collapsed: collapsed(at :index), batchUpdate: false)
            }
        }
    }


    private static var persistentDirectory: String? {
        guard let userID = ZMUser.selfUser()?.remoteIdentifier else { return nil }

        return "UI_state/\(userID)"
    }

    private static var persistentFilename: String {
        let className = String(describing: self)
        return "\(className).json"
    }

    static var persistentURL: URL? {
        guard let persistentDirectory = persistentDirectory else { return nil }

        return URL.directoryURL(persistentDirectory)?.appendingPathComponent(ConversationListViewModel.persistentFilename)
    }
}

// MARK: - ZMUserObserver

fileprivate let log = ZMSLog(tag: "ConversationListViewModel")

extension ConversationListViewModel: ZMUserObserver {

    public func userDidChange(_ note: UserChangeInfo) {
        if note.teamsChanged {
            updateAllConversations()
        }
    }
}

// MARK: - ConversationDirectoryObserver

extension ConversationListViewModel: ConversationDirectoryObserver {
    func conversationDirectoryDidChange(_ changeInfo: ConversationDirectoryChangeInfo) {
        if changeInfo.reloaded {
            // If the section was empty in certain cases collection view breaks down on the big amount of conversations,
            // so we prefer to do the simple reload instead.
            reload()
        } else {
            for updatedList in changeInfo.updatedLists {
                if let kind = self.kind(of: updatedList) {
                    updateForConversationType(kind: kind)
                }
            }
        }
    }

    private func kind(of conversationListType: ConversationListType) -> Section.Kind? {

        let kind: Section.Kind?

        switch conversationListType {
        case .unarchived:
            kind = .conversations
        case .contacts:
            kind = .contacts
        case .pending:
            kind = .contactRequests
        case .groups:
            kind = .groups
        case .favorites:
            kind = .favorites
        case .folder(_):
            ///TODO: Bill - folder
            kind = nil
        case .archived:
            kind = nil
        }

        return kind

    }
}
