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

import UIKit

extension ConversationViewController: UIPopoverPresentationControllerDelegate {

    @objc (createAndPresentParticipantsPopoverControllerWithRect:fromView:contentViewController:)
    func createAndPresentParticipantsPopoverController(with rect: CGRect,
                                                       from view: UIView,
                                                       contentViewController controller: UIViewController) {

        controller.modalPresentationStyle = .popover

        guard let popover = controller.popoverPresentationController else { return }
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController as? PopoverPresenter & UIViewController else { return }

        popover.delegate = self
        popover.config(from: rootViewController,
                       pointToView: view,
                       sourceView: rootViewController.view)

        popover.backgroundColor = .white

        rootViewController.present(controller, animated: true)
    }

    @objc
    func didTap(onUserAvatar user: UserType?, view: UIView?, frame: CGRect) {
        if user == nil || view == nil {
            return
        }

        let profileViewController = ProfileViewController(user: user as! UserType & AccentColorProvider, conversation: conversation)
        profileViewController.preferredContentSize = CGSize.IPadPopover.preferredContentSize

        profileViewController.delegate = self

        endEditing()

        createAndPresentParticipantsPopoverController(with: frame, from: view!, contentViewController: profileViewController.wrapInNavigationController())
    }

}

