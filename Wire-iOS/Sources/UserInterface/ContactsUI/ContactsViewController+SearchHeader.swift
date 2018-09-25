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
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        showKeyboardIfNeeded()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchHeaderViewController.tokenField.resignFirstResponder()
    }

    @objc func createSearchHeader() {
        searchHeaderViewController = SearchHeaderViewController(userSelection: .init(), variant: .dark)
        searchHeaderViewController.delegate = self
        searchHeaderViewController.allowsMultipleSelection = false
        searchHeaderViewController.view.backgroundColor = UIColor(scheme: .searchBarBackground, variant: .dark)

        addToSelf(searchHeaderViewController)
    }

    @objc func createTopContainerConstraints() {
        constrain(self.view, topContainerView) {selfView, topContainerView in
            topContainerView.leading == selfView.leading
            topContainerView.trailing == selfView.trailing
            topContainerView.top == selfView.top + UIScreen.safeArea.top
            topContainerHeightConstraint = topContainerView.height == 0
        }

        topContainerHeightConstraint.isActive = false
    }

    @objc func createSearchHeaderConstraints() {
        constrain(searchHeaderViewController.view, self.view, topContainerView, separatorView) { searchHeader, selfView, topContainerView, separatorView in
            searchHeader.leading == selfView.leading
            searchHeader.trailing == selfView.trailing
            searchHeader.top == topContainerView.bottom
            searchHeader.bottom == separatorView.top
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
        noContactsLabel.isHidden = !showNoContactsLabel
        bottomContainerView.isHidden = (searchQueryCount > 0) || showEmptyResults

        setEmptyResultsHidden(!showEmptyResults, animated: showEmptyResults)
    }

    func showKeyboardIfNeeded() {
        if numTableRows > Int(StartUIInitiallyShowsKeyboardConversationThreshold) {
            searchHeaderViewController.tokenField.becomeFirstResponder()
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
