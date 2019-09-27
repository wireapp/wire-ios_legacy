
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

extension ProfilePresenter {

    @objc
    func deviceOrientationChanged(_ notification: Notification?) {
        guard let controllerToPresentOn = controllerToPresentOn,
            controllerToPresentOn.isIPadRegular() else { return }

        ZClientViewController.shared()?.transitionToList(animated: false, completion: nil)

        if let _ = viewToPresentOn,
            let presentedViewController = controllerToPresentOn.presentedViewController {

            presentedViewController.popoverPresentationController?.sourceRect = presentedFrame
            presentedViewController.preferredContentSize = presentedViewController.view.frame.insetBy(dx: -0.01, dy: 0.0).size
        }
    }
}
