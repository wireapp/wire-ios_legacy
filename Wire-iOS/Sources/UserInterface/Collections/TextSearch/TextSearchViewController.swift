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
import WireSyncEngine

final class TextSearchViewController: NSObject {
    let resultsView: TextSearchResultsView = TextSearchResultsView()
    let searchBar: TextSearchInputView = TextSearchInputView()

    weak var delegate: MessageActionResponder? = .none
    let conversation: ConversationLike
    var searchQuery: String? {
        return searchBar.query
    }

    fileprivate var textSearchQuery: TextSearchQuery?

    fileprivate var results: [ZMConversationMessage] = [] {
        didSet {
            reloadResults()
        }
    }

    fileprivate var searchStartedDate: Date?

    init(conversation: ConversationLike) {
        self.conversation = conversation
        super.init()
        loadViews()
    }

    private func loadViews() {
        resultsView.isHidden = results.isEmpty
        resultsView.tableView.isHidden = results.isEmpty
        resultsView.noResultsView.isHidden = !results.isEmpty

        resultsView.tableView.delegate = self
        resultsView.tableView.dataSource = self

        searchBar.delegate = self
        searchBar.placeholderString = "collections.search.field.placeholder".localized(uppercased: true)
    }

    func teardown() {
        textSearchQuery?.cancel()
    }

    fileprivate func scheduleSearch() {
        let searchSelector = #selector(TextSearchViewController.search)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: searchSelector, object: .none)
        perform(searchSelector, with: .none, afterDelay: 0.2)
    }

    @objc
    fileprivate func search() {
        let searchSelector = #selector(TextSearchViewController.search)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: searchSelector, object: .none)
        textSearchQuery?.cancel()
        textSearchQuery = nil

        guard let query = searchQuery, !query.isEmpty else {
            results = []
            return
        }

        textSearchQuery = TextSearchQuery(conversation: conversation, query: query, delegate: self)
        if let query = textSearchQuery {
            searchStartedDate = Date()
            perform(#selector(showLoadingSpinner), with: nil, afterDelay: 2)
            query.execute()
        }
    }

    fileprivate func reloadResults() {
        let query = searchQuery ?? ""
        let noResults = results.isEmpty
        let validQuery = TextSearchQuery.isValid(query: query)

        // We hide the results when we either have none or the query is too short
        resultsView.tableView.isHidden = noResults || !validQuery
        // We only show the no results view if there are no results and a valid query
        resultsView.noResultsView.isHidden = !noResults || !validQuery
        // If the user did not enter any search query we show the collection again
        resultsView.isHidden = query.isEmpty

        resultsView.tableView.reloadData()
    }

    @objc
    fileprivate func showLoadingSpinner() {
        searchBar.isLoading = true
    }

    fileprivate func hideLoadingSpinner() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showLoadingSpinner), object: nil)
        searchBar.isLoading = false
    }

}

extension TextSearchViewController: TextSearchQueryDelegate {
    func textSearchQueryDidReceive(result: TextQueryResult) {
        guard result.query == textSearchQuery else { return }
        if !result.matches.isEmpty || !result.hasMore {
            hideLoadingSpinner()
            results = result.matches
        }
    }
}

extension TextSearchViewController: TextSearchInputViewDelegate {
    func searchView(_ searchView: TextSearchInputView, didChangeQueryTo query: String) {
        textSearchQuery?.cancel()
        searchStartedDate = nil
        hideLoadingSpinner()

        if TextSearchQuery.isValid(query: query) {
            scheduleSearch()
        } else {
            // We reset the results to avoid showing the previous
            // results for a short period for subsequential searches
            results = []
        }
    }

    func searchViewShouldReturn(_ searchView: TextSearchInputView) -> Bool {
        return TextSearchQuery.isValid(query: searchView.query)
    }
}

extension TextSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TextSearchResultCell.reuseIdentifier) as! TextSearchResultCell
        cell.configure(with: results[indexPath.row], queries: searchQuery?.components(separatedBy: .whitespacesAndNewlines) ?? [])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.perform(action: .showInConversation, for: results[indexPath.row], view: tableView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.searchInput.endEditing(true)
    }
}
