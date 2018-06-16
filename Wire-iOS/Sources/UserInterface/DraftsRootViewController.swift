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


import Foundation
import WireExtensionComponents


final class DraftsRootViewController: UISplitViewController {

    let persistence: MessageDraftStorage = .shared

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        let navigationController = DraftNavigationController(rootViewController: DraftListViewController(persistence: persistence))
        viewControllers = [navigationController]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if persistence.numberOfStoredDrafts() == 0 || traitCollection.horizontalSizeClass != .compact {
            let initialComposeViewController = MessageComposeViewController(draft: nil, persistence: persistence)
            initialComposeViewController.delegate = self
            let detail = DraftNavigationController(rootViewController: initialComposeViewController)
            UIView.performWithoutAnimation {
                showDetailViewController(detail, sender: nil)
            }
        }
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.wr_setStatusBarStyle(.lightContent, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

}


extension DraftsRootViewController: MessageComposeViewControllerDelegate, UIAdaptivePresentationControllerDelegate {

    func composeViewControllerWantsToDismiss(_ controller: MessageComposeViewController) {
        view.window?.endEditing(true)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func composeViewController(_ controller: MessageComposeViewController, wantsToSendDraft draft: MessageDraft) {
        view.window?.endEditing(true)
        let conversations = ZMConversationList.conversationsIncludingArchived(inUserSession: ZMUserSession.shared()!).shareableConversations()
        let shareViewController = ShareViewController(shareable: draft, destinations: conversations, showPreview: false)
        let keyboardAvoiding = KeyboardAvoidingViewController(viewController: shareViewController)

        keyboardAvoiding.modalPresentationStyle = .formSheet
        keyboardAvoiding.presentationController?.delegate = self

        shareViewController.onDismiss = { [weak self] (controller, success) in
            if success {
                self?.persistence.enqueue(
                    block: { $0.delete(draft) },
                    completion: { self?.presentingViewController?.dismiss(animated: true, completion: nil) }
                )
            } else {
                controller.presentingViewController?.dismiss(animated: true) {
                    UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
                }
            }
        }

        present(keyboardAvoiding, animated: true) {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true, onlyFullScreen: false)
        }
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .regular ? .formSheet : .overFullScreen
    }

}

