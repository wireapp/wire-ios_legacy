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

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchHeaderViewController?.tokenField.resignFirstResponder()
    }

    @objc func keyboardFrameWillChange(_ notification: Notification) {
        guard let beginOrigin = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect)?.origin.y,
            let endOrigin = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.origin.y else { return }

        let diff = beginOrigin - endOrigin
        let padding: CGFloat = 12

        UIView.animate(withKeyboardNotification: notification, in: self.view, animations: { (keyboardFrame) in
            self.bottomEdgeConstraint?.constant = -padding - (diff > 0 ? 0 : UIScreen.safeArea.bottom)
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

