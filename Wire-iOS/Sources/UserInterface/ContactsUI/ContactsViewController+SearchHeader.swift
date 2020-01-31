//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import Cartography

extension ContactsViewController {

    @objc func setupSearchHeader() {
        let searchHeaderViewController = SearchHeaderViewController(userSelection: .init(), variant: .dark)
        searchHeaderViewController.delegate = self
        searchHeaderViewController.allowsMultipleSelection = false
        searchHeaderViewController.view.backgroundColor = UIColor.from(scheme: .searchBarBackground, variant: .dark)

        addToSelf(searchHeaderViewController)

        self.searchHeaderViewController = searchHeaderViewController
    }

    func createSearchHeaderConstraints() {
        guard let searchHeaderViewControllerView = searchHeaderViewController.view else { return }

        constrain(searchHeaderViewControllerView, self.view, separatorView) { searchHeader, selfView, separatorView in
            searchHeader.leading == selfView.leading
            searchHeader.trailing == selfView.trailing
            searchHeader.top == selfView.top
            searchHeader.bottom == separatorView.top
        }
    }

    var numTableRows: UInt {
        return tableView.numberOfTotalRows()
    }

    @objc func updateEmptyResults() {
        let searchQueryCount = dataSource.searchQuery.count
        let showEmptyResults = searchResultsReceived && !(numTableRows != 0)
        let showNoContactsLabel = !(numTableRows != 0) && (searchQueryCount == 0) && !(searchHeaderViewController.tokenField.userDidConfirmInput)
        noContactsLabel.isHidden = !showNoContactsLabel
        bottomContainerView.isHidden = (searchQueryCount > 0) || showEmptyResults

        setEmptyResultsHidden(!showEmptyResults, animated: showEmptyResults)
    }

    func showKeyboardIfNeeded() {
        if numTableRows > StartUIViewController.InitiallyShowsKeyboardConversationThreshold {
            searchHeaderViewController.tokenField.becomeFirstResponder()
        }
    }
}

extension ContactsViewController: SearchHeaderViewControllerDelegate {
    public func searchHeaderViewController(_ searchHeaderViewController: SearchHeaderViewController, updatedSearchQuery query: String) {
        dataSource.searchQuery = query
        updateEmptyResults()
    }

    public func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController) {
        if searchHeaderViewController.tokenField.tokens.count == 0 {
            updateEmptyResults()
            return
        }

        delegate?.contactsViewControllerDidConfirmSelection(self)
    }
}
