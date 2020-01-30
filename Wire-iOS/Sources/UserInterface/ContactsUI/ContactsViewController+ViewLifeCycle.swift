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

extension ContactsViewController {

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        showKeyboardIfNeeded()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presentShareContactsViewControllerIfNeeded()
    }

    private func presentShareContactsViewControllerIfNeeded() {
        let shouldSkip: Bool = AutomationHelper.sharedHelper.skipFirstLoginAlerts || ZMUser.selfUser().hasTeam
        if sharingContactsRequired &&
            !AddressBookHelper.sharedHelper.isAddressBookAccessGranted &&
            !shouldSkip &&
            shouldShowShareContactsViewController {
            presentShareContactsViewController()
        }
    }
    

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchHeaderViewController.tokenField.resignFirstResponder()
    }

    private func presentShareContactsViewController() {
        let shareContactsViewController = ShareContactsViewController()
        shareContactsViewController.delegate = self

        addToSelf(shareContactsViewController)
    }

}

