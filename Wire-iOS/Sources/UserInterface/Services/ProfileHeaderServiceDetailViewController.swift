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


/// A container UIViewController with a ProfileHeaderView and a ServiceDetailViewController.
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
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.delegate = self.navigationControllerDelegate

        setupHeader()
        setupServiceDetailViewController(serviceUser: serviceUser)
        createConstraints()
    }

    private func createConstraints() {

        /// align to ParticipantsViewController's "X" button y position
        var topMargin = -UIScreen.safeArea.top + 20
        if UIScreen.hasNotch {
            topMargin -= 20.0
        }

        self.serviceDetailViewController.view.translatesAutoresizingMaskIntoConstraints = false

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

    // MARK: - header view

    func headerViewModel(with user: ZMBareUser) -> ProfileHeaderViewModel {
        var headerStyle: ProfileHeaderStyle = .cancelButton
        /// TODO: It is possible that headerStyle changes in run time, e.g. iPad changes its size class. Rewrite ProfileHeaderView to handle size class changing.
        if UIApplication.shared.keyWindow?.traitCollection.horizontalSizeClass == .regular {
            headerStyle = .backButton
        }
        return ProfileHeaderViewModel(user: user, fallbackName: user.displayName, addressBookName: nil, style: headerStyle)
    }

    func setupHeader() {
        let viewModel = headerViewModel(with: serviceUser)

        headerView = ProfileHeaderView(with: viewModel)

        headerView.dismissButton.addTarget(self, action: #selector(self.dismissButtonClicked), for: .touchUpInside)
        view.addSubview(headerView)
    }

    func dismissButtonClicked() {
        requestDismissal(withCompletion: nil)
    }

    func requestDismissal(withCompletion completion: (() -> Void)?) {
        profileViewControllerDelegate?.profileViewControllerWants(toBeDismissed: self, completion: completion)
    }

    func setupServiceDetailViewController(serviceUser: ServiceUser) {
        serviceDetailViewController = ServiceDetailViewController(serviceUser: serviceUser,
                                                                  actionButton: Button.createDestructiveServiceButton(),
                                                                  actionType: .removeService,
                                                                  forceShowNavigationBar: false,
                                                                  variant: .light)

        self.addToSelf(serviceDetailViewController)

    }
}
