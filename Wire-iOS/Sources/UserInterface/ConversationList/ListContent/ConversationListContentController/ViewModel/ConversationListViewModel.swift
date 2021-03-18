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
import DifferenceKit
import WireSystem
import WireDataModel
import WireSyncEngine
import WireRequestStrategy

final class ConversationListViewModel: NSObject {

    typealias SectionIdentifier = String

    fileprivate struct Section: DifferentiableSection {

        enum Kind: Equatable, Hashable {

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

            /// conversations in folders
            case folder(label: LabelType)

            func hash(into hasher: inout Hasher) {
                hasher.combine(identifier)
            }

            var identifier: SectionIdentifier {
                switch self {
                case.folder(label: let label):
                    return label.remoteIdentifier?.transportString() ?? "folder"
                default:
                    return canonicalName
                }
            }

            var canonicalName: String {
                switch self {
                case .contactRequests:
                    return "contactRequests"
                case .conversations:
                    return "conversations"
                case .contacts:
                    return "contacts"
                case .groups:
                    return "groups"
                case .favorites:
                    return "favorites"
                case .folder(label: let label):
                    return label.name ?? "folder"
                }
            }

            var localizedName: String? {
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
                case .folder(label: let label):
                    return label.name
                }
            }

            static func == (lhs: ConversationListViewModel.Section.Kind, rhs: ConversationListViewModel.Section.Kind) -> Bool {
                switch (lhs, rhs) {
                case (.conversations, .conversations):
                    return true
                case (.contactRequests, .contactRequests):
                    return true
                case (.contacts, .contacts):
                    return true
                case (.groups, .groups):
                    return true
                case (.favorites, .favorites):
                    return true
                case (.folder(let lhsLabel), .folder(let rhsLabel)):
                    return lhsLabel === rhsLabel
                default:
                    return false
                }
            }
        }

        var kind: Kind
        var items: [SectionItem]
        var collapsed: Bool

        var elements: [SectionItem] {
            return collapsed ? [] : items
        }

        /// ref to AggregateArray, we return the first found item's index
        ///
        /// - Parameter item: item to search
        /// - Returns: the index of the item
        func index(for item: ConversationListItem) -> Int? {
            return items.firstIndex(of: SectionItem(item: item, kind: kind))
        }

        func isContentEqual(to source: ConversationListViewModel.Section) -> Bool {
            return kind == source.kind
        }

        var differenceIdentifier: String {
            return kind.identifier
        }

        init<C>(source: ConversationListViewModel.Section, elements: C) where C: Collection, C.Element == SectionItem {
            self.kind = source.kind
            self.collapsed = source.collapsed
            items = Array(elements)
        }

        init(kind: Kind,
             conversationDirectory: ConversationDirectoryType,
             collapsed: Bool) {
            items = ConversationListViewModel.newList(for: kind, conversationDirectory: conversationDirectory)
            self.kind = kind
            self.collapsed = collapsed
        }
    }

    static let contactRequestsItem: ConversationListConnectRequestsItem = ConversationListConnectRequestsItem()

    /// current selected ZMConversaton or ConversationListConnectRequestsItem object
    private(set) var selectedItem: ConversationListItem? {
        didSet {
            /// expand the section if selcted item is update
            guard let indexPath = self.indexPath(for: selectedItem),
                  collapsed(at: indexPath.section) else { return }

            setCollapsed(sectionIndex: indexPath.section, collapsed: false, batchUpdate: false)
        }
    }

    weak var restorationDelegate: ConversationListViewModelRestorationDelegate? {
        didSet {
            restorationDelegate?.listViewModel(self, didRestoreFolderEnabled: folderEnabled)
        }
    }
    weak var delegate: ConversationListViewModelDelegate? {
        didSet {
            delegateFolderEnableState(newState: state)
        }
    }

    var folderEnabled: Bool {
        get {
            return state.folderEnabled
        }

        set {
            guard newValue != state.folderEnabled else { return }

            state.folderEnabled = newValue

            updateAllSections()
            delegate?.listViewModelShouldBeReloaded()
            delegateFolderEnableState(newState: state)
        }
    }

    // Local copies of the lists.
    private var sections: [Section] = []

    private typealias DiffKitSection = ArraySection<Int, SectionItem>

    /// make items has different hash in different sections
    struct SectionItem: Hashable, Differentiable {
        let item: ConversationListItem
        let isFavorite: Bool

        fileprivate init(item: ConversationListItem, kind: Section.Kind) {
            self.item = item
            self.isFavorite = kind == .favorites
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(isFavorite)

            let hashableItem: NSObject = item
            hasher.combine(hashableItem)
        }

        static func == (lhs: SectionItem, rhs: SectionItem) -> Bool {
            return lhs.isFavorite == rhs.isFavorite &&
                   lhs.item == rhs.item
        }
    }

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
            /// simulate willSet

            /// assign
            if newValue != _state {
                _state = newValue
            }

            /// simulate didSet
            saveState(state: _state)
        }
    }

    private var conversationDirectoryToken: Any?

    private let userSession: UserSessionInterface?

    init(userSession: UserSessionInterface? = ZMUserSession.shared()) {
        self.userSession = userSession

        super.init()

        setupObservers()
        updateAllSections()
    }

    private func delegateFolderEnableState(newState: State) {
        delegate?.listViewModel(self, didChangeFolderEnabled: folderEnabled)
    }

    private func setupObservers() {
        conversationDirectoryToken = userSession?.conversationDirectory.addObserver(self)
    }

    func sectionHeaderTitle(sectionIndex: Int) -> String? {
        return kind(of: sectionIndex)?.localizedName
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

        return !sections[section].items.isEmpty
    }

    private func kind(of sectionIndex: Int) -> Section.Kind? {
        guard sections.indices.contains(sectionIndex) else { return nil }

        return sections[sectionIndex].kind
    }

    /// Section's canonical name
    ///
    /// - Parameter sectionIndex: section index of the collection view
    /// - Returns: canonical name
    func sectionCanonicalName(of sectionIndex: Int) -> String? {
        return kind(of: sectionIndex)?.canonicalName
    }

    var sectionCount: Int {
        return sections.count
    }

    func numberOfItems(inSection sectionIndex: Int) -> Int {
        guard sections.indices.contains(sectionIndex),
              !collapsed(at: sectionIndex) else { return 0 }

        return sections[sectionIndex].elements.count
    }

    private func numberOfItems(of kind: Section.Kind) -> Int? {
        return sections.first(where: { $0.kind == kind })?.elements.count ?? nil
    }

    func section(at sectionIndex: Int) -> [ConversationListItem]? {
        if sectionIndex >= sectionCount {
            return nil
        }

        return sections[sectionIndex].elements.map(\.item)
    }

    func item(for indexPath: IndexPath) -> ConversationListItem? {
        guard let items = section(at: indexPath.section),
              items.indices.contains(indexPath.item) else { return nil }

        return items[indexPath.item]
    }

    /// TODO: Question: we may have multiple items in folders now. return array of IndexPaths?
    func indexPath(for item: ConversationListItem?) -> IndexPath? {
        guard let item = item else { return nil }

        for (sectionIndex, section) in sections.enumerated() {
            if let index = section.index(for: item) {
                return IndexPath(item: index, section: sectionIndex)
            }
        }

        return nil
    }

    private static func newList(for kind: Section.Kind, conversationDirectory: ConversationDirectoryType) -> [SectionItem] {
        let conversationListType: ConversationListType
        switch kind {
        case .contactRequests:
            conversationListType = .pending
            return conversationDirectory.conversations(by: conversationListType).isEmpty ? [] : [SectionItem(item: contactRequestsItem, kind: kind)]
        case .conversations:
            conversationListType = .unarchived
        case .contacts:
            conversationListType = .contacts
        case .groups:
            conversationListType = .groups
        case .favorites:
            conversationListType = .favorites
        case .folder(label: let label):
            conversationListType = .folder(label)
        }

        return conversationDirectory.conversations(by: conversationListType).map({ SectionItem(item: $0, kind: kind) })
    }

    /// Select the item at an index path
    ///
    /// - Parameter indexPath: indexPath of the item to select
    /// - Returns: the item selected
    @discardableResult
    func selectItem(at indexPath: IndexPath) -> ConversationListItem? {
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
    func item(after index: Int, section sectionIndex: Int) -> IndexPath? {
        guard let section = self.section(at: sectionIndex) else { return nil }

        if section.count > index + 1 {
            // Select next item in section
            return IndexPath(item: index + 1, section: sectionIndex)
        } else if index + 1 >= section.count {
            // select last item in previous section
            return firstItemInSection(after: sectionIndex)
        }

        return nil
    }

    private func firstItemInSection(after sectionIndex: Int) -> IndexPath? {
        let nextSectionIndex = sectionIndex + 1

        if nextSectionIndex >= sectionCount {
            // we are at the end, so return nil
            return nil
        }

        if let section = self.section(at: nextSectionIndex) {
            if section.isEmpty {
                // Recursively move forward
                return firstItemInSection(after: nextSectionIndex)
            } else {
                return IndexPath(item: 0, section: nextSectionIndex)
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
    func itemPrevious(to index: Int, section sectionIndex: Int) -> IndexPath? {
        guard let section = self.section(at: sectionIndex) else { return nil }

        if section.indices.contains(index - 1) {
            // Select previous item in section
            return IndexPath(item: index - 1, section: sectionIndex)
        } else if index == 0 {
            // select last item in previous section
            return lastItemInSectionPrevious(to: sectionIndex)
        }

        return nil
    }

    func lastItemInSectionPrevious(to sectionIndex: Int) -> IndexPath? {
        let previousSectionIndex = sectionIndex - 1

        if previousSectionIndex < 0 {
            // we are at the top, so return nil
            return nil
        }

        guard let section = self.section(at: previousSectionIndex) else { return nil }

        if section.isEmpty {
            // Recursively move back
            return lastItemInSectionPrevious(to: previousSectionIndex)
        } else {
            return IndexPath(item: section.count - 1, section: previousSectionIndex)
        }
    }

    private func updateAllSections() {
        sections = createSections()
    }

    /// Create the section structure
    private func createSections() -> [Section] {
        guard let conversationDirectory = userSession?.conversationDirectory else { return [] }

        var kinds: [Section.Kind]
        if folderEnabled {
            kinds = [.contactRequests,
                     .favorites,
                     .groups,
                     .contacts]

            let folders: [Section.Kind] = conversationDirectory.allFolders.map({ .folder(label: $0) })
            kinds.append(contentsOf: folders)
        } else {
            kinds = [.contactRequests,
                     .conversations]
        }

        return kinds.map { Section(kind: $0, conversationDirectory: conversationDirectory, collapsed: state.collapsed.contains($0.identifier)) }
    }

    private func sectionNumber(for kind: Section.Kind) -> Int? {
        for (index, section) in sections.enumerated() where section.kind == kind {
            return index
        }

        return nil
    }

    private func update(for kind: Section.Kind? = nil) {
        guard let conversationDirectory = userSession?.conversationDirectory else { return }

        var newValue: [Section]
        if let kind = kind,
            let sectionNumber = self.sectionNumber(for: kind) {
            newValue = sections
            let newList = ConversationListViewModel.newList(for: kind, conversationDirectory: conversationDirectory)

            newValue[sectionNumber].items = newList

            /// Refresh the section header(since it may be hidden if the sectio is empty) when a section becomes empty/from empty to non-empty
            if sections[sectionNumber].items.isEmpty || newList.isEmpty {
                sections = newValue
                delegate?.listViewModel(self, didUpdateSectionForReload: sectionNumber, animated: true)
                return
            }
        } else {
            newValue = createSections()
        }

        let changeset = StagedChangeset(source: sections, target: newValue)
        if changeset.isEmpty {
            sections = newValue
        } else {
            delegate?.reload(using: changeset, interrupt: { _ in
                return false
            }) { data in
                if let data = data {
                    self.sections = data
                }
            }
        }

        if let kind = kind,
           let sectionNumber = sectionNumber(for: kind) {
            delegate?.listViewModel(self, didUpdateSection: sectionNumber)
        } else {
            sections.enumerated().forEach {
                delegate?.listViewModel(self, didUpdateSection: $0.offset)
            }
        }
    }

    @discardableResult
    func select(itemToSelect: ConversationListItem?) -> Bool {
        guard let itemToSelect = itemToSelect else {
            internalSelect(itemToSelect: nil)
            return false
        }

        if indexPath(for: itemToSelect) == nil {
            guard let conversation = itemToSelect as? ZMConversation else { return false }

            ZMUserSession.shared()?.enqueue({
                conversation.isArchived = false
            }, completionHandler: {
                self.internalSelect(itemToSelect: itemToSelect)
            })
        } else {
            internalSelect(itemToSelect: itemToSelect)
        }

        return true
    }

    private func internalSelect(itemToSelect: ConversationListItem?) {
        selectedItem = itemToSelect

        if let itemToSelect = itemToSelect {
            delegate?.listViewModel(self, didSelectItem: itemToSelect)
        }
    }

    // MARK: - folder badge

    func folderBadge(at sectionIndex: Int) -> Int {
        return sections[sectionIndex].items.filter({
             let status = ($0.item as? ZMConversation)?.status
             return status?.messagesRequiringAttention.isEmpty == false &&
                    status?.showingAllMessages == true
        }).count
    }

    // MARK: - collapse section

    func collapsed(at sectionIndex: Int) -> Bool {
        return collapsed(at: sectionIndex, state: state)
    }

    private func collapsed(at sectionIndex: Int, state: State) -> Bool {
        guard let kind = kind(of: sectionIndex) else { return false }

        return state.collapsed.contains(kind.identifier)
    }

    /// set a collpase state of a section
    ///
    /// - Parameters:
    ///   - sectionIndex: section to update
    ///   - collapsed: collapsed or expanded
    ///   - batchUpdate: true for update with difference kit comparison, false for reload the section animated
    func setCollapsed(sectionIndex: Int,
                      collapsed: Bool,
                      batchUpdate: Bool = true) {
        guard let conversationDirectory = userSession?.conversationDirectory else { return }
        guard let kind = self.kind(of: sectionIndex) else { return }
        guard self.collapsed(at: sectionIndex) != collapsed else { return }
        guard let sectionNumber = self.sectionNumber(for: kind) else { return }

        if collapsed {
            state.collapsed.insert(kind.identifier)
        } else {
            state.collapsed.remove(kind.identifier)
        }

        var newValue = sections
        newValue[sectionNumber] = Section(kind: kind, conversationDirectory: conversationDirectory, collapsed: collapsed)

        if batchUpdate {
            let changeset = StagedChangeset(source: sections, target: newValue)

            delegate?.reload(using: changeset, interrupt: { _ in
                return false
            }) { data in
                if let data = data {
                    self.sections = data
                }
            }
        } else {
            sections = newValue
            delegate?.listViewModel(self, didUpdateSectionForReload: sectionIndex, animated: true)
        }
    }

    // MARK: - state presistent

    private struct State: Codable, Equatable {
        var collapsed: Set<SectionIdentifier>
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

private let log = ZMSLog(tag: "ConversationListViewModel")

// MARK: - ConversationDirectoryObserver

extension ConversationListViewModel: ConversationDirectoryObserver {
    func conversationDirectoryDidChange(_ changeInfo: ConversationDirectoryChangeInfo) {

        if changeInfo.reloaded {
            // If the section was empty in certain cases collection view breaks down on the big amount of conversations,
            // so we prefer to do the simple reload instead.
            update()
        } else {
            /// TODO: When 2 sections are visible and a conversation belongs to both, the lower section's update
            /// animation is missing since it started after the top section update animation started. To fix this
            /// we should calculate the change set in one batch.
            /// TODO: wait for SE update for returning multiple items in changeInfo.updatedLists
            for updatedList in changeInfo.updatedLists {
                if let kind = self.kind(of: updatedList) {
                    update(for: kind)
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
        case .folder(let label):
            kind = .folder(label: label)
        case .archived:
            kind = nil
        }

        return kind

    }
}
