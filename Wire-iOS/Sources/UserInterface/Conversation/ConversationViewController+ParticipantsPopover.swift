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

        endEditing()
        controller.modalPresentationStyle = .formSheet
        present(controller, animated: true)
    }

    @objc func didTap(onUserAvatar user: GenericUser, view: UIView?, frame: CGRect) {
        if view == nil {
            return
        }

        let profileViewController = ProfileViewController(user: user,
                                                          viewer: ZMUser.selfUser(),
                                                          conversation: conversation,
                                                          viewControllerDismisser: self)
        profileViewController.preferredContentSize = CGSize.IPadPopover.preferredContentSize

        profileViewController.delegate = self

        endEditing()

        createAndPresentParticipantsPopoverController(with: frame, from: view!, contentViewController: profileViewController.wrapInNavigationController())
    }

}

extension ConversationViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        dismiss(animated: true, completion: completion)
    }
}
