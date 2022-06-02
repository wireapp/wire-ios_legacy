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
import WireSyncEngine

enum BlockerViewControllerContext {
    case blacklist
    case jailbroken
    case databaseFailure
    case backendNotSupported
}

final class BlockerViewController: LaunchImageViewController {

    private var context: BlockerViewControllerContext = .blacklist
    private var sessionManager: SessionManager?

    init(context: BlockerViewControllerContext, sessionManager: SessionManager? = nil) {
        self.context = context
        self.sessionManager = sessionManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        showAlert()
    }

    func showAlert() {
        switch context {
        case .blacklist:
            showBlacklistMessage()
        case .jailbroken:
            showJailbrokenMessage()
        case .databaseFailure:
            showDatabaseFailureMessage()
        case .backendNotSupported:
            showBackendNotSupportedMessage()
        }
    }

    func showBackendNotSupportedMessage() {
        typealias BackendNotSupported = L10n.Localizable.BackendNotSupported.Alert

        presentAlertWithOKButton(
            title: BackendNotSupported.title,
            message: BackendNotSupported.message
        )
    }

    func showBlacklistMessage() {

        presentAlertWithOKButton(title: L10n.Localizable.Force.Update.title,
                                 message: L10n.Localizable.Force.Update.message) { _ in
            UIApplication.shared.open(URL.wr_wireAppOnItunes)
        }
    }

    func showJailbrokenMessage() {
        presentAlertWithOKButton(title: L10n.Localizable.Jailbrokendevice.Alert.title,
                                 message: L10n.Localizable.Jailbrokendevice.Alert.message)
    }

    func showDatabaseFailureMessage() {

        let databaseFailureAlert = UIAlertController(
            title: L10n.Localizable.Databaseloadingfailure.Alert.title,
            message: L10n.Localizable.Databaseloadingfailure.Alert.message,
            preferredStyle: .alert
        )

        let settingsAction = UIAlertAction(
            title: L10n.Localizable.Databaseloadingfailure.Alert.settings,
            style: .default,
            handler: { _ in
                UIApplication.shared.openSettings()
            }
        )

        databaseFailureAlert.addAction(settingsAction)

        let deleteDatabaseAction = UIAlertAction(
            title: L10n.Localizable.Databaseloadingfailure.Alert.deleteDatabase,
            style: .destructive,
            handler: { [weak self] _ in
                self?.dismiss(animated: true, completion: {
                    self?.showConfirmationDatabaseDeletionAlert()
                })
            }
        )

        databaseFailureAlert.addAction(deleteDatabaseAction)
        present(databaseFailureAlert, animated: true)
    }

    func showConfirmationDatabaseDeletionAlert() {
        let deleteDatabaseConfirmationAlert = UIAlertController(
            title: L10n.Localizable.Databaseloadingfailure.Alert.deleteDatabase,
            message: L10n.Localizable.Databaseloadingfailure.Alert.DeleteDatabase.message,
            preferredStyle: .alert
        )

        let continueAction = UIAlertAction(
            title: L10n.Localizable.Databaseloadingfailure.Alert.DeleteDatabase.continue,
            style: .destructive,
            handler: { [weak self] _ in
                self?.sessionManager?.removeDatabaseFromDisk()
            }
        )

        deleteDatabaseConfirmationAlert.addAction(continueAction)

        let cancelAction = UIAlertAction(
            title: L10n.Localizable.General.cancel,
            style: .default,
            handler: nil)

        deleteDatabaseConfirmationAlert.addAction(cancelAction)
        present(deleteDatabaseConfirmationAlert, animated: true)
    }
}
