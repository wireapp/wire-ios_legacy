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

    @objc func setupFooterView() {
        let factory = ProfileActionsFactory(user: bareUser, viewer: viewer, conversation: self.conversation)
        let actions = factory.makeActionsList()

        guard !actions.isEmpty else {
            return profileFooterView.isHidden = true
        }

        profileFooterView.delegate = self
        profileFooterView.configure(with: actions)
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
        dump(action)
        // no-op yet
    }

    private func presentAlert(_ alert: UIAlertController, targetView: UIView) {
        let buttonFrame = view.convert(targetView.frame, from: targetView.superview).insetBy(dx: 8, dy: 8)
        alert.popoverPresentationController?.sourceView = targetView
        alert.popoverPresentationController?.sourceRect = buttonFrame
        present(alert, animated: true)
    }

//    func footerView(_ view: ProfileFooterView, performs action: ProfileFooterView.Action) {
//        switch action {
//        case .addPeople:
//            presentAddParticipantsViewController()
//        case .presentMenu:
//            presentMenuSheetController()
//        case .openConversation:
//            openOneToOneConversation()
//        case .removePeople:
//            presentRemoveUserMenuSheetController()
//        case .acceptConnectionRequest:
//            bringUpConnectionRequestSheet()
//        case .cancelConnectionRequest:
//            bringUpCancelConnectionRequestSheet()
//        default:
//            break
//        }
//    }

    @objc func presentMenuSheetController() {
        actionsController = ConversationActionController(conversation: conversation, target: self)
        actionsController.presentMenu(from: profileFooterView, showConverationNameInMenuTitle: false)
    }
    
    @objc func presentRemoveUserMenuSheetController() {
        actionsController = RemoveUserActionController(conversation: conversation,
                                                       participant: fullUser(),
                                                       dismisser: viewControllerDismisser,
                                                       target: self)
        
        actionsController.presentMenu(from: profileFooterView, showConverationNameInMenuTitle: false)
    }
}
