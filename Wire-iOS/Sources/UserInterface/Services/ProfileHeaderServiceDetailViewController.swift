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

import UIKit
import Cartography

final class ProfileHeaderServiceDetailViewController: UIViewController {

    public weak var navigationControllerDelegate: ProfileNavigationControllerDelegate?
    public weak var profileViewControllerDelegate: ProfileViewControllerDelegate?

    var headerView: ProfileHeaderView!
    var serviceDetailViewController: ServiceDetailViewController!
    let serviceUser: ServiceUser
    let conversation: ZMConversation

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(serviceUser: ServiceUser, conversation: ZMConversation) {
        self.serviceUser = serviceUser
        self.conversation = conversation

        super.init(nibName: nil, bundle: nil)

        self.navigationController?.delegate = self.navigationControllerDelegate
        self.view.backgroundColor = .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupHeader()
        setupServiceDetailViewController(serviceUser: serviceUser)
        createConstraints()
    }

    private func createConstraints() {
        var topMargin = UIScreen.safeArea.top
        if UIScreen.hasNotch {
            topMargin -= 20.0;
        }

        constrain(view, self.headerView, self.serviceDetailViewController.view) { view, headerView, serviceDetailView in
            headerView.top == view.top + topMargin
            headerView.right == view.right
            headerView.left == view.left

            serviceDetailView.top == headerView.bottom
            serviceDetailView.right == view.right
            serviceDetailView.left == view.left
            serviceDetailView.bottom == view.bottom
        }
    }

    func setupHeader() {
        var headerStyle: ProfileHeaderStyle = .cancelButton
        if UIDevice.current.userInterfaceIdiom == .pad && navigationController?.viewControllers.count > 1 {
            headerStyle = .backButton
        }
        headerView = ProfileHeaderView(with: headerStyle)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.dismissButton.addTarget(self, action: #selector(self.dismissButtonClicked), for: .touchUpInside)
        view.addSubview(headerView)
    }

    func dismissButtonClicked() {
        requestDismissal(withCompletion: nil)
    }

    func requestDismissal(withCompletion completion: (() -> ())?) {
        profileViewControllerDelegate?.profileViewControllerWants(toBeDismissed: self, completion: completion)
    }

    func presentRemoveFromConversationDialogue(user: ZMUser) {
        if let actionSheetController = ActionSheetController.dialog(forRemoving: serviceUser as! ZMUser, from: conversation, style: ActionSheetController.defaultStyle(), completion: {(_ canceled: Bool) -> Void in
            self.dismiss(animated: true, completion: {() -> Void in
                if canceled {
                    return
                }
                ZMUserSession.shared()?.enqueueChanges({() -> Void in
                    self.conversation.removeParticipant(user)
                }, completionHandler: {() -> Void in
                    self.profileViewControllerDelegate?.profileViewControllerWants(toBeDismissed: self, completion: nil)
                })
            })
        }) {
            present(actionSheetController, animated: true)
        }
        MediaManagerPlayAlert()
    }

    func setupServiceDetailViewController(serviceUser: ServiceUser) {

        let buttonCallback: Callback<Button> = { [weak self] _ in
            guard let weakSelf = self else { return }
            guard weakSelf.serviceUser.isKind(of: ZMUser.self)  else { return }

            weakSelf.presentRemoveFromConversationDialogue(user: weakSelf.serviceUser as! ZMUser)
        }

        serviceDetailViewController = ServiceDetailViewController(serviceUser: serviceUser,
            confirmButton: Buttonfactory.removeServicebutton(),
            forceShowNavigationBarWhenviewWillAppear: false,
            variant: .light,
            buttonCallback: buttonCallback)

        self.addToSelf(serviceDetailViewController)

    }
}

