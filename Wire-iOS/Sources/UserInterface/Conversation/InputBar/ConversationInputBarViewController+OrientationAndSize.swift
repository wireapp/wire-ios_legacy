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

extension ConversationInputBarViewController: PopoverPresenter {
    
}

extension ConversationInputBarViewController {
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator?) {

        if let coordinator = coordinator {
            super.viewWillTransition(to: size, with: coordinator)
            self.inRotation = true

            coordinator.animate(alongsideTransition: { (context) in
                self.updatePopoverSourceRect()
            }) { _ in
                self.inRotation = false
            }
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }

        updatePopoverSourceRect()
    }

    fileprivate func updatePopoverSourceRect() {
        ///TODO: if popoverPresentationController is nil, may be it was in compact mode and full screen UI
        if let presentedPopover = presentedPopover,
            let popoverSourceView = popoverSourceView{
            presentedPopover.sourceRect = popoverSourceView.popoverSourceRect(from: self)
        }
    }
}
