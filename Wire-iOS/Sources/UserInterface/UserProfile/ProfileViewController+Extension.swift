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

// MARK: - Keyboard frame observer
extension ProfileViewController {
    @objc func setupKeyboardFrameNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameDidChange(notification:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)

    }

    @objc func keyboardFrameDidChange(notification: Notification) {
        updatePopoverFrame()
    }
}

// MARK: - init
extension ProfileViewController {
    convenience init(user: (UserType & AccentColorProvider), conversation: ZMConversation?, viewControllerDismisser: ViewControllerDismisser) {
        self.init(user: user, conversation: conversation)

        self.viewControllerDismisser = viewControllerDismisser
    }

    @objc
    func setupProfileDetailsViewController() -> ProfileDetailsViewController? {
        guard let profileDetailsViewController = ProfileDetailsViewController(user: bareUser, conversation: conversation, context: context) else { return nil }
        profileDetailsViewController.delegate = self
        profileDetailsViewController.viewControllerDismisser = viewControllerDismisser ?? self
        profileDetailsViewController.title = "profile.details.title".localized

        return profileDetailsViewController
    }
}

extension ProfileViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        navigationController?.popViewController(animated: true)
    }
}

extension ProfileViewController: ProfileDetailsViewControllerDelegate {
    public func profileDetailsViewController(_ profileDetailsViewController: ProfileDetailsViewController!, didSelect conversation: ZMConversation!) {
        
        delegate?.profileViewController?(self, wantsToNavigateTo: conversation)
    }

    public func profileDetailsViewController(_ profileDetailsViewController: ProfileDetailsViewController!, didPresent conversationCreationController: ConversationCreationController!) {
        conversationCreationController.delegate = self as? ConversationCreationControllerDelegate
    }

    public func profileDetailsViewController(_ profileDetailsViewController: ProfileDetailsViewController!, wantsToBeDismissedWithCompletion completion: (() -> Void)!) {
        if let viewControllerDismisser = viewControllerDismisser {
            viewControllerDismisser.dismiss(viewController: self, completion: completion)
        } else {
            completion()
        }
    }
}
