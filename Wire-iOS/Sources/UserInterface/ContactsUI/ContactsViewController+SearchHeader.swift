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

    @objc func createSearchHeader() {
        let searchHeaderViewController = SearchHeaderViewController(userSelection: .init(), variant: .dark)
        searchHeaderViewController.delegate = self
        searchHeaderViewController.allowsMultipleSelection = false
        searchHeaderViewController.view.backgroundColor = UIColor.from(scheme: .searchBarBackground, variant: .dark)

        addToSelf(searchHeaderViewController)

        self.searchHeaderViewController = searchHeaderViewController
    }

    @objc func createTopContainerConstraints() {
        constrain(self.view, topContainerView!) {selfView, topContainerView in
            topContainerView.leading == selfView.leading
            topContainerView.trailing == selfView.trailing
            topContainerView.top == selfView.topMargin
            topContainerHeightConstraint = topContainerView.height == 0
        }

        topContainerHeightConstraint?.isActive = false
    }

    @objc func createSearchHeaderConstraints() {
        guard let searchHeaderViewControllerView = searchHeaderViewController?.view,
            let topContainerView = topContainerView,
            let separatorView = separatorView else { return }

        constrain(searchHeaderViewControllerView, self.view, topContainerView, separatorView) { searchHeader, selfView, topContainerView, separatorView in
            searchHeader.leading == selfView.leading
            searchHeader.trailing == selfView.trailing
            searchHeaderTopConstraint = searchHeader.top == topContainerView.bottom
            searchHeader.bottom == separatorView.top
        }

        constrain(searchHeaderViewController!.view, self.view) {
            searchHeader, selfView in
            searchHeaderWithNavigatorBarTopConstraint = searchHeader.top == selfView.top
        }

        searchHeaderTopConstraint?.isActive = false
        searchHeaderWithNavigatorBarTopConstraint?.isActive = true
    }


    var numTableRows: UInt {
        if let tableView = tableView {
            return tableView.numberOfTotalRows()
        } else {
            return 0
        }
    }

    @objc func updateEmptyResults() {

        let searchQueryCount: Int
        if let dataSource = dataSource {
            searchQueryCount = dataSource.searchQuery.count
        } else {
            searchQueryCount = 0
        }

        let showEmptyResults = searchResultsReceived && !(numTableRows != 0)
        let showNoContactsLabel = !(numTableRows != 0) && (searchQueryCount == 0) && !(searchHeaderViewController?.tokenField.userDidConfirmInput ?? false)
        noContactsLabel?.isHidden = !showNoContactsLabel
        bottomContainerView?.isHidden = (searchQueryCount > 0) || showEmptyResults

        setEmptyResultsHidden(!showEmptyResults, animated: showEmptyResults)
    }

    func showKeyboardIfNeeded() {
        if numTableRows > Int(StartUIInitiallyShowsKeyboardConversationThreshold) {
            searchHeaderViewController?.tokenField.becomeFirstResponder()
        }
    }
}

extension ContactsViewController: SearchHeaderViewControllerDelegate {
    public func searchHeaderViewController(_ searchHeaderViewController: SearchHeaderViewController, updatedSearchQuery query: String) {
        dataSource?.searchQuery = query
        updateEmptyResults()
    }

    public func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController) {
        if searchHeaderViewController.tokenField.tokens.count == 0 {
            updateEmptyResults()
            return
        }

        delegate?.contactsViewControllerDidConfirmSelection!(self)
    }
}
