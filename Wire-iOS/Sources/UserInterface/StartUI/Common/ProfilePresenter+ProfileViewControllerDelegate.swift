
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
    func presentProfileViewController(for user: UserType,
                                      in controller: UIViewController?,
                                      from rect: CGRect,
                                      onDismiss: @escaping () -> (),
                                      arrowDirection: UIPopoverArrowDirection) {
        profileOpenedFromPeoplePicker = true
        viewToPresentOn = controller?.view
        controllerToPresentOn = controller
        presentedFrame = rect
        
        self.onDismiss = onDismiss
        
        let profileViewController = ProfileViewController(user: user, viewer: ZMUser.selfUser(), context: .search)
        profileViewController.delegate = self
        profileViewController.viewControllerDismisser = self
        
        let navigationController = profileViewController.wrapInNavigationController()
        navigationController.transitioningDelegate = transitionDelegate
        navigationController.modalPresentationStyle = .formSheet
        
        controller?.present(navigationController, animated: true)
        
        ///TODO: config with presentationController?.config
        // Get the popover presentation controller and configure it.
        let presentationController = navigationController.popoverPresentationController
                
        presentationController?.permittedArrowDirections = arrowDirection
        presentationController?.sourceView = viewToPresentOn
        presentationController?.sourceRect = rect
    }
}

extension ProfilePresenter: ProfileViewControllerDelegate {
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        guard let controller = controller else { return }
        
        dismiss(controller) {
            ZClientViewController.shared?.select(conversation, focusOnView: true, animated: true)
        }
    }

    func profileViewController(_ controller: ProfileViewController?, wantsToCreateConversationWithName name: String?, users: Set<ZMUser>) {
        //no-op.
    }
}
