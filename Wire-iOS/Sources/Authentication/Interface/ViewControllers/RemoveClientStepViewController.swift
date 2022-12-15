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
import UIKit
import WireDataModel
import WireSyncEngine

final class RemoveClientStepViewController: UIViewController, AuthenticationCoordinatedViewController {

    var authenticationCoordinator: AuthenticationCoordinator?
    let clientListController: ClientListViewController
    var userInterfaceSizeClass: (UITraitEnvironment) -> UIUserInterfaceSizeClass = {traitEnvironment in
       return traitEnvironment.traitCollection.horizontalSizeClass
    }

    private var contentViewWidthRegular: NSLayoutConstraint!
    private var contentViewWidthCompact: NSLayoutConstraint!

    // MARK: - Initialization

    init(clients: [UserClient],
         credentials: ZMCredentials?) {
        let emailCredentials: ZMEmailCredentials? = credentials.flatMap {
            guard let email = $0.email, let password = $0.password else {
                return nil
            }

            return ZMEmailCredentials(email: email, password: password)
        }

        clientListController = ClientListViewController(clientsList: clients,
                                                        credentials: emailCredentials,
                                                        showTemporary: false,
                                                        showLegalHold: false,
                                                        variant: .light)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setupNavigationBarTitle(title: L10n.Localizable.Registration.Signin.TooManyDevices.ManageScreen.title.capitalized)
        configureSubviews()
        configureConstraints()
        updateBackButton()
    }

    private func configureSubviews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault

        clientListController.view.backgroundColor = .clear
        clientListController.editingList = true
        clientListController.delegate = self
        addToSelf(clientListController)
    }

    private func configureConstraints() {
        clientListController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            clientListController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clientListController.view.topAnchor.constraint(equalTo: safeTopAnchor),
            clientListController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Adaptive Constraints
        contentViewWidthRegular = clientListController.view.widthAnchor.constraint(equalToConstant: 375)
        contentViewWidthCompact = clientListController.view.widthAnchor.constraint(equalTo: view.widthAnchor)

        toggleConstraints()
    }

    // MARK: - Back Button

    private func updateBackButton() {
        guard navigationController?.viewControllers.count > 1 else {
            return
        }

        let button = AuthenticationNavigationBar.makeBackButton()
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Adaptive UI

    func toggleConstraints() {
        userInterfaceSizeClass(self).toggle(compactConstraints: [contentViewWidthCompact],
               regularConstraints: [contentViewWidthRegular])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        toggleConstraints()
    }

    // MARK: - AuthenticationCoordinatedViewController

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        // no-op
    }

    func displayError(_ error: Error) {
        // no-op
    }
}

// MARK: - ClientListViewControllerDelegate

extension RemoveClientStepViewController: ClientListViewControllerDelegate {

    func finishedDeleting(_ clientListViewController: ClientListViewController) {
        authenticationCoordinator?.executeActions([.unwindState(withInterface: true), .showLoadingView])
    }

}
