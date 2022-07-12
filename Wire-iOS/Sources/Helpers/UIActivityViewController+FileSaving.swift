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

import UIKit
import WireDataModel

extension UIActivityViewController {

    convenience init?(message: ZMConversationMessage, from view: UIView) {
        guard let fileMessageData = message.fileMessageData, message.isFileDownloaded() == true, let fileURL = fileMessageData.fileURL else { return nil }
        self.init(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        configPopover(pointToView: view)
    }
}

typealias PopoverPresenterViewController = PopoverPresenter & UIViewController
extension UIViewController {
    /// On iPad, UIActivityViewController must be presented in a popover and the popover's source view must be set
    ///
    /// - Parameter pointToView: the view which the popover points to
    func configPopover(pointToView: UIView, popoverPresenter: PopoverPresenterViewController? = UIApplication.shared.firstKeyWindow?.rootViewController as? PopoverPresenterViewController) {
        guard let popover = popoverPresentationController,
            let popoverPresenter = popoverPresenter else { return }

        popover.config(from: popoverPresenter,
                       pointToView: pointToView,
                       sourceView: popoverPresenter.view)
    }
}
