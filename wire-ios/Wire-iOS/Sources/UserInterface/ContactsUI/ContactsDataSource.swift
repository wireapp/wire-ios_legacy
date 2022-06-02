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
import WireDataModel
import WireSyncEngine

protocol ContactsDataSourceDelegate: AnyObject {

    func dataSource(_ dataSource: ContactsDataSource, cellFor user: UserType, at indexPath: IndexPath) -> UITableViewCell
    func dataSource(_ dataSource: ContactsDataSource, didReceiveSearchResult newUser: [UserType])

}

class ContactsDataSource: NSObject {

    static let MinimumNumberOfContactsToDisplaySections: UInt = 15

    weak var delegate: ContactsDataSourceDelegate?

    private(set) var searchDirectory: SearchDirectory?
    private var sections = [[UserType]]()
    private var collation: UILocalizedIndexedCollation { return .current() }

    // MARK: - Life Cycle

    override init() {
        super.init()
        searchDirectory = ZMUserSession.shared().map(SearchDirectory.init)
        performSearch()
    }

    deinit {
        searchDirectory?.tearDown()
    }

    // MARK: - Getters / Setters

    var ungroupedSearchResults = [UserType]() {
        didSet {
            recalculateSections()
        }
    }

    var searchQuery: String = "" {
        didSet {
            performSearch()
        }
    }

    var shouldShowSectionIndex: Bool {
        return ungroupedSearchResults.count >= type(of: self).MinimumNumberOfContactsToDisplaySections
    }

    // MARK: - Methods

    private func performSearch() {
        guard let searchDirectory = searchDirectory else { return }

        let request = SearchRequest(query: searchQuery, searchOptions: [.contacts, .addressBook])
        let task = searchDirectory.perform(request)

        task.onResult { [weak self] (searchResult, _) in
            guard let `self` = self else { return }
            self.ungroupedSearchResults = searchResult.addressBook
            self.delegate?.dataSource(self, didReceiveSearchResult: searchResult.addressBook)
        }

        task.start()
    }

    func user(at indexPath: IndexPath) -> UserType {
        return section(at: indexPath.section)[indexPath.row]
    }

    private func section(at index: Int) -> [UserType] {
        return sections[index]
    }

    private func recalculateSections() {
        let nameSelector = #selector(getter: UserType.name)

        guard shouldShowSectionIndex else {
            let sortedResults = collation.sortedArray(from: ungroupedSearchResults, collationStringSelector: nameSelector)
            sections = [sortedResults] as? [[UserType]] ?? []
            return
        }

        let numberOfSections = collation.sectionTitles.count
        let emptySections = Array(repeating: [UserType](), count: numberOfSections)

        let unsortedSections = ungroupedSearchResults.reduce(into: emptySections) { (sections, user) in
            let index = collation.section(for: user, collationStringSelector: nameSelector)
            sections[index].append(user)
        }

        let sortedSections = unsortedSections.map {
            collation.sortedArray(from: $0, collationStringSelector: nameSelector)
        }

        sections = sortedSections as? [[UserType]] ?? []
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
        return delegate?.dataSource(self, cellFor: user(at: indexPath), at: indexPath) ?? UITableViewCell()
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
