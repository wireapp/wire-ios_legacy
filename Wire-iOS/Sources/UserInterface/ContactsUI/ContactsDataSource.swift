//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

@objc protocol ContactsDataSourceDelegate: class {

    func dataSource(_ dataSource: ContactsDataSource, cellFor user: UserType, at indexPath: IndexPath) -> UITableViewCell
    func dataSource(_ dataSource: ContactsDataSource, didReceiveSearchResult newUser: [UserType])
    func dataSource(_ dataSource: ContactsDataSource, didSelect user: UserType)
    func dataSource(_ dataSource: ContactsDataSource, didDeselect user: UserType)
}

@objc class ContactsDataSource: NSObject {

    static let MinimumNumberOfContactsToDisplaySections: UInt = 15

    @objc weak var delegate: ContactsDataSourceDelegate?

    private(set) var searchDirectory: SearchDirectory?
    private var sections = [[ZMSearchUser]]()
    private var collation: UILocalizedIndexedCollation { return .current() }

    // MARK: - Life Cycle

    override init() {
        super.init()

        // FIXME: I think we could require a non nil search directory.
        if let userSession = ZMUserSession.shared() {
            searchDirectory = SearchDirectory(userSession: userSession)
        }
    }

    deinit {
        searchDirectory?.tearDown()
    }

    // MARK: - Getters / Setters

    var ungroupedSearchResults = [ZMSearchUser]() {
        didSet {
            recalculateSections()
        }
    }

    var searchQuery: String = "" {
        didSet {
            guard searchQuery != oldValue else { return }
            search(withQuery: searchQuery, searchDirectory: searchDirectory)
        }
    }

    var selection = Set<ZMSearchUser>() {
        didSet {
            guard let delegate = delegate else { return }
            let removedUsers = oldValue.subtracting(selection)
            let addedUsers = selection.subtracting(oldValue)
            removedUsers.forEach { delegate.dataSource(self, didDeselect: $0) }
            addedUsers.forEach { delegate.dataSource(self, didSelect: $0) }
        }
    }

    private var shouldShowSectionIndex: Bool {
        return ungroupedSearchResults.count >= type(of: self).MinimumNumberOfContactsToDisplaySections
    }

    // MARK: - Methods

    func user(at indexPath: IndexPath) -> ZMSearchUser {
        return section(at: indexPath.section)[indexPath.row]
    }

    private func section(at index: Int) -> [ZMSearchUser] {
        return sections[index]
    }

    func select(user: ZMSearchUser) {
        guard !selection.contains(user) else { return }
        selection.insert(user)
        delegate?.dataSource(self, didSelect: user)
    }

    func deselect(user: ZMSearchUser) {
        guard selection.contains(user) else { return }
        selection.remove(user)
        delegate?.dataSource(self, didDeselect: user)
    }

    private func recalculateSections() {
        let nameSelector = #selector(getter: ZMSearchUser.displayName)

        guard shouldShowSectionIndex else {
            let sortedResults = collation.sortedArray(from: ungroupedSearchResults, collationStringSelector: nameSelector)
            sections = [sortedResults] as! [[ZMSearchUser]] // FIXME: don't force unwrap
            return
        }

        let numberOfSections = collation.sectionTitles.count
        let emptySections = Array(repeating: [ZMSearchUser](), count: numberOfSections)

        let unsortedSections = ungroupedSearchResults.reduce(into: emptySections) { (sections, user) in
            let index = collation.section(for: user, collationStringSelector: nameSelector)
            sections[index].append(user)
        }

        let sortedSections = unsortedSections.map {
            collation.sortedArray(from: $0, collationStringSelector: nameSelector)
        }

        sections = sortedSections as! [[ZMSearchUser]] // FIXME
    }
}

extension ContactsDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.section(at: section).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return delegate!.dataSource(self, cellFor: user(at: indexPath), at: indexPath) // FIXME
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard shouldShowSectionIndex && !self.section(at: section).isEmpty else { return nil }
        return collation.sectionTitles[section]
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return collation.sectionIndexTitles
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return collation.section(forSectionIndexTitle: index)
    }
}

extension ContactsDataSource: UITableViewDelegate {

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
