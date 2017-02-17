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
import zmessaging
import ZMCDataModel
import Cartography

final public class TextSearchViewController: NSObject {
    public var resultsView: TextSearchResultsView!
    public var searchBar: TextSearchInputView!
    
    public weak var delegate: MessageActionResponder? = .none
    public let conversation: ZMConversation
    public var searchQuery: String? {
        return self.searchBar.query
    }

    fileprivate var textSearchQuery: TextSearchQuery?
    
    fileprivate var results: [ZMConversationMessage] = [] {
        didSet {
            self.resultsView.tableView.isHidden = results.count == 0
            self.resultsView.noResultsView.isHidden = results.count != 0
            self.resultsView.tableView.reloadData()
        }
    }

    fileprivate var searchStartedDate: Date?
    
    init(conversation: ZMConversation) {
        self.conversation = conversation
        super.init()
        self.loadViews()
    }
    
    private func loadViews() {
        self.resultsView = TextSearchResultsView()
        self.resultsView.isHidden = results.count == 0
        self.resultsView.tableView.isHidden = results.count == 0
        self.resultsView.noResultsView.isHidden = results.count != 0

        self.resultsView.tableView.delegate = self
        self.resultsView.tableView.dataSource = self
        
        self.searchBar = TextSearchInputView()
        self.searchBar.delegate = self
        self.searchBar.placeholderString = "collections.search.field.placeholder".localized.uppercased()
    }

    public func teardown() {
        textSearchQuery?.cancel()
    }
    
    fileprivate func scheduleSearch() {
        let searchSelector = #selector(TextSearchViewController.search)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: searchSelector, object: .none)
        self.perform(searchSelector, with: .none, afterDelay: 0.2)
    }
    
    @objc fileprivate func search() {
        let searchSelector = #selector(TextSearchViewController.search)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: searchSelector, object: .none)
        textSearchQuery?.cancel()
        textSearchQuery = nil

        guard let query = self.searchQuery, !query.isEmpty else {
            self.results = []
            return
        }

        textSearchQuery = TextSearchQuery(conversation: conversation, query: query, delegate: self)
        if let query = textSearchQuery {
            searchStartedDate = Date()
            query.execute()
            resultsView.isLoading = true
        }
    }

}

extension TextSearchViewController: TextSearchQueryDelegate {
    public func textSearchQueryDidReceive(result: TextQueryResult) {
        guard result.query == textSearchQuery else { return }
        if result.matches.count > 0 || !result.hasMore {
            resultsView.isLoading = false
            results = result.matches
        }

        if !result.hasMore {
            Analytics.shared()?.tag(searchEvent: .receivedResult(startedAt: searchStartedDate))
        }
    }
}

extension TextSearchViewController: TextSearchInputViewDelegate {
    public func searchView(_ searchView: TextSearchInputView, didChangeQueryTo query: String) {
        textSearchQuery?.cancel()
        searchStartedDate = nil

        if query.isEmpty {
            self.resultsView.isHidden = true
        }
        else {
            self.scheduleSearch()
            self.resultsView.isHidden = false
        }

        if query.characters.count < 2 {
            resultsView.isLoading = false
        }
    }

    public func searchViewShouldReturn(_ searchView: TextSearchInputView) -> Bool {
        return searchView.query.characters.count >= 2
    }
}

extension TextSearchViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TextSearchResultCell.reuseIdentifier) as! TextSearchResultCell
        cell.configure(with: self.results[indexPath.row], queries: self.searchQuery?.components(separatedBy: .whitespacesAndNewlines) ?? [])
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Analytics.shared()?.tag(searchEvent: .selected)
        self.delegate?.wants(toPerform: .showInConversation, for: self.results[indexPath.row])
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard searchBar.searchInput.isEditing else { return }
        searchBar.searchInput.endEditing(true)
    }
}
