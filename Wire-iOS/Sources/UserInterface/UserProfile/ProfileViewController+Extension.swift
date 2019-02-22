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
    convenience init(user: GenericUser, viewer: GenericUser, conversation: ZMConversation?, viewControllerDismisser: ViewControllerDismisser) {
        self.init(user: user, viewer: viewer, conversation: conversation)
        self.viewControllerDismisser = viewControllerDismisser
    }

    @objc func setupProfileDetailsViewController() -> ProfileDetailsViewController? {
        let profileDetailsViewController = ProfileDetailsViewController(user: bareUser, viewer: viewer, conversation: conversation!)
        profileDetailsViewController.title = "profile.details.title".localized

        return profileDetailsViewController
    }
}

extension ProfileViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Footer View

extension ProfileViewController: ProfileFooterViewDelegate {

    @objc func updateFooterView() {
        guard let conversation = self.conversation else {
            profileFooterView.isHidden = true
            return
        }

        let factory = ProfileActionsFactory(user: bareUser, viewer: viewer, conversation: conversation)
        let actions = factory.makeActionsList()

        profileFooterView.delegate = self
        profileFooterView.isHidden = actions.isEmpty
        profileFooterView.configure(with: actions)
        view.bringSubviewToFront(profileFooterView)
    }

    func footerView(_ footerView: ProfileFooterView, shouldPerformAction action: ProfileAction) {
        performAction(action, targetView: footerView.leftButton)
    }

    func footerView(_ footerView: ProfileFooterView, shouldPresentMenuWithActions actions: [ProfileAction]) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        for action in actions {
            let sheetAction = UIAlertAction(title: action.buttonText, style: action.isDestructive ? .destructive : .default) { _ in
                self.performAction(action, targetView: footerView.rightButton)
            }

            actionSheet.addAction(sheetAction)
        }

        actionSheet.addAction(.cancel())
        presentAlert(actionSheet, targetView: footerView.rightButton)
    }

    func performAction(_ action: ProfileAction, targetView: UIView) {
        switch action {
        case .createGroup:
            bringUpConversationCreationFlow()
        case .mute(let isMuted):
            updateMute(enableNotifications: isMuted)
        case .manageNotifications:
            presentNotificationsOptions(from: targetView)
        case .archive:
            archiveConversation()
        case .deleteContents:
            presentDeleteConfirmationPrompt(from: targetView)
        case .block:
            presentBlockRequest(from: targetView)
        case .openOneToOne:
            openOneToOneConversation()
        case .removeFromGroup:
            presentRemoveUserMenuSheetController(from: targetView)
        case .connect:
            sendConnectionRequest()
        case .cancelConnectionRequest:
            bringUpCancelConnectionRequestSheet(from: targetView)
        }
    }

    // MARK: - Helpers

    private func transitionToListAndEnqueue(_ block: @escaping () -> Void) {
        ZClientViewController.shared()?.transitionToList(animated: true) {
            ZMUserSession.shared()?.enqueueChanges(block)
        }
    }

    /// Presents an alert as a popover if needed.
    @objc(presentAlert:fromTargetView:)
    func presentAlert(_ alert: UIAlertController, targetView: UIView) {
        let buttonFrame = view.convert(targetView.frame, from: targetView.superview).insetBy(dx: 8, dy: 8)
        alert.popoverPresentationController?.sourceView = targetView
        alert.popoverPresentationController?.sourceRect = buttonFrame
        present(alert, animated: true)
    }

    // MARK: - Action Handlers

    private func archiveConversation() {
        transitionToListAndEnqueue {
            self.conversation.isArchived.toggle()
        }
    }

    // MARK: Connect

    private func sendConnectionRequest() {
        guard let user = self.fullUser() else { return }
        ZMUserSession.shared()?.enqueueChanges {
            let messageText = "missive.connection_request.default_message".localized(args: user.displayName, self.viewer.name ?? "")
            user.connect(message: messageText)
            // update the footer view to display the cancel request button
            self.updateFooterView()
        }
    }

    // MARK: Block

    private func presentBlockRequest(from targetView: UIView) {
        let controller = UIAlertController(title: BlockResult.title(for: bareUser), message: nil, preferredStyle: .actionSheet)
        BlockResult.all(isBlocked: bareUser.isBlocked).map { $0.action(handleBlockResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }

    private func handleBlockResult(_ result: BlockResult) {
        guard case .block = result else { return }
        transitionToListAndEnqueue {
            self.fullUser()?.toggleBlocked()
        }
    }

    // MARK: Notifications

    private func updateMute(enableNotifications: Bool) {
        ZMUserSession.shared()?.enqueueChanges {
            self.conversation.mutedMessageTypes = enableNotifications ? .none : .all
            // update the footer view to display the correct mute/unmute button
            self.updateFooterView()
        }
    }

    private func presentNotificationsOptions(from targetView: UIView) {
        let title = "\(conversation.displayName) • \(NotificationResult.title)"
        let controller = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        NotificationResult.allCases.map { $0.action(for: conversation, handler: handleNotificationResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }

    func handleNotificationResult(_ result: NotificationResult) {
        if let mutedMessageTypes = result.mutedMessageTypes {
            ZMUserSession.shared()?.performChanges {
                self.conversation.mutedMessageTypes = mutedMessageTypes
            }
        }
    }

    // MARK: Delete Contents

    private func presentDeleteConfirmationPrompt(from targetView: UIView) {
        let controller = UIAlertController(title: DeleteResult.title, message: nil, preferredStyle: .actionSheet)
        DeleteResult.options(for: conversation) .map { $0.action(handleDeleteResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }

    func handleDeleteResult(_ result: DeleteResult) {
        guard case .delete(leave: let leave) = result else { return }
        transitionToListAndEnqueue {
            self.conversation.clearMessageHistory()
            if leave {
                self.conversation.removeOrShowError(participnant: .selfUser())
            }
        }
    }

    // MARK: Remove User

    private func presentRemoveUserMenuSheetController(from view: UIView) {
        guard let otherUser = self.fullUser() else {
            return
        }

        let controller = UIAlertController.remove(otherUser) { [weak self] remove in
            guard let `self` = self, remove else { return }

            self.conversation.removeOrShowError(participnant: otherUser) { result in
                switch result {
                case .success:
                    self.dismiss(animated: true, completion: nil)
                case .failure(_):
                    break
                }
            }
        }

        presentAlert(controller, targetView: view)
    }

}
