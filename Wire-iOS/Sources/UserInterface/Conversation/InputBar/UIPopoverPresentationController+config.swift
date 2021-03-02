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
import UIKit

protocol PopoverPresenter: class {

    /// The presenting popover. Its frame should be updated when the orientation or screen size changes.
    var presentedPopover: UIPopoverPresentationController? {get set}

    /// The popover's arrow points to this view
    var popoverPointToView: UIView? {get set}

    /// call this method when the presented popover have to update its frame, e.g. when device roated or keyboard toggled
    func updatePopoverSourceRect()
}

extension PopoverPresenter where Self: UIViewController {
    func updatePopoverSourceRect() {
        guard let presentedPopover = presentedPopover,
              let popoverPointToView = popoverPointToView else { return }

        presentedPopover.sourceRect = popoverPointToView.popoverSourceRect(from: self)
    }
}

extension UIPopoverPresentationController {

    /// Config a UIPopoverPresentationController to let it can update its position correctly after its presenter's frame is updated
    ///
    /// - Parameters:
    ///   - popoverPresenter: the PopoverPresenter which presents this popover
    ///   - pointToView: the view in the presenter the popover's arrow points to
    ///   - sourceView: the view which presents this popover, usually a view of a UIViewController
    func config(from popoverPresenter: PopoverPresenter,
                pointToView: UIView,
                sourceView: UIView) {

        if let viewController = popoverPresenter as? UIViewController {
            sourceRect = pointToView.popoverSourceRect(from: viewController)
        }

        popoverPresenter.presentedPopover = self
        popoverPresenter.popoverPointToView = pointToView

        self.sourceView = sourceView
    }
}
