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

class RemoveClientStepViewController: UIViewController, AuthenticationCoordinatedViewController {

    var authenticationCoordinator: AuthenticationCoordinator?
    let clientListController: ClientListViewController

    private var contentViewWidthRegular: NSLayoutConstraint!
    private var contentViewWidthCompact: NSLayoutConstraint!

    // MARK: - Initialization

    init(clients: [UserClient], credentials: ZMCredentials?) {
        let emailCredentials: ZMEmailCredentials? = credentials.flatMap {
            guard let email = $0.email, let password = $0.password else {
                return nil
            }

            return ZMEmailCredentials(email: email, password: password)
        }

        clientListController = ClientListViewController(clientsList: clients,
                                                        credentials: emailCredentials,
                                                        showTemporary: false,
                                                        variant: .light)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "registration.signin.too_many_devices.manage_screen.title".localized(uppercased: true)
        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {
        view.backgroundColor = UIColor.Team.background

        clientListController.editingList = true
        clientListController.delegate = self
        addToSelf(clientListController)
    }

    private func configureConstraints() {
        clientListController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            clientListController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clientListController.view.topAnchor.constraint(equalTo: safeTopAnchor),
            clientListController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Adaptive Constraints
        contentViewWidthCompact = clientListController.view.widthAnchor.constraint(equalToConstant: 375)
        contentViewWidthCompact = clientListController.view.widthAnchor.constraint(equalTo: view.widthAnchor)

        updateConstraints(forRegularLayout: traitCollection.horizontalSizeClass == .regular)
    }

    // MARK: - Adaptive UI

    func updateConstraints(forRegularLayout isRegular: Bool) {
        if isRegular {
            contentViewWidthCompact.isActive = false
            contentViewWidthRegular.isActive = true
        } else {
            contentViewWidthCompact.isActive = false
            contentViewWidthCompact.isActive = true
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateConstraints(forRegularLayout: traitCollection.horizontalSizeClass == .regular)
    }

}

// MARK: - ClientListViewControllerDelegate

extension RemoveClientStepViewController: ClientListViewControllerDelegate {

    func finishedDeleting(_ clientListViewController: ClientListViewController) {
        authenticationCoordinator?.executeActions([.unwindState(withInterface: true), .showLoadingView])
    }

}
