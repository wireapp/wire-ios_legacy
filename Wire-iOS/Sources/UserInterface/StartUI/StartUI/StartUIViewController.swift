//
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

extension StartUIViewController {
    
    ///TODO: tmp
    var searchHeader: SearchHeaderViewController {
        return self.searchHeaderViewController
    }

    var searchResults: SearchResultsViewController {
        return self.searchResultsViewController
    }

    var selfUser: UserType {
        return ZMUser.selfUser()
    }
    
    static let StartUIInitiallyShowsKeyboardConversationThreshold = 10

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
        handleUploadAddressBookLogicIfNeeded()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.navigationBar.barTintColor = UIColor.clear
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.from(scheme: .textForeground, variant: .dark)
        navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: .dark)
        
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
    }
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func showKeyboardIfNeeded() {
        let conversationCount = ZMConversationList.conversations(inUserSession: ZMUserSession.shared()!).count ///TODO: unwrap
        if conversationCount > StartUIViewController.StartUIInitiallyShowsKeyboardConversationThreshold {
            searchHeader.tokenField.becomeFirstResponder()
        }
        
    }
    
    @objc
    func updateActionBar() {
        if !searchHeader.query.isEmpty || (selfUser as? ZMUser)?.hasTeam == true {
            searchResults.searchResultsView?.accessoryView = nil
        } else {
            searchResults.searchResultsView?.accessoryView = quickActionsBar
        }
        
        view.setNeedsLayout()
    }
    
    @objc
    func onDismissPressed() {
        searchHeader.tokenField.resignFirstResponder()
        navigationController?.dismiss(animated: true)
    }
    
    override open func accessibilityPerformEscape() -> Bool {
        onDismissPressed()
        return true
    }
}
