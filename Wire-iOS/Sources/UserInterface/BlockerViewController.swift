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
}

final class BlockerViewController: LaunchImageViewController {

    private var context: BlockerViewControllerContext = .blacklist
    private var sessionManager: SessionManager?

    init(context: BlockerViewControllerContext, sessionManager: SessionManager? = nil) {
        self.context = context
        self.sessionManager = sessionManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        }
    }

    func showBlacklistMessage() {
        presentAlertWithOKButton(title: "force.update.title".localized,
                                 message: "force.update.message".localized) { _ in
            UIApplication.shared.open(URL.wr_wireAppOnItunes)
        }
    }

    func showJailbrokenMessage() {
        presentAlertWithOKButton(title: "jailbrokendevice.alert.title".localized,
                                 message: "jailbrokendevice.alert.message".localized)
    }

    func showDatabaseFailureMessage() {
        let databaseFailureAlert = UIAlertController(
            title: "databaseloadingfailure.alert.title".localized,
            message: "databaseloadingfailure.alert.message".localized,
            preferredStyle: .alert
        )

        let settingsAction = UIAlertAction(
            title: "databaseloadingfailure.alert.settings".localized,
            style: .default,
            handler: { _ in
                UIApplication.shared.openSettings()
            }
        )

        databaseFailureAlert.addAction(settingsAction)

        let deleteDatabaseAction = UIAlertAction(
            title: "databaseloadingfailure.alert.delete_database".localized,
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
            title: "databaseloadingfailure.alert.delete_database".localized,
            message: "databaseloadingfailure.alert.delete_database.message".localized,
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(
            title: "general.cancel".localized,
            style: .cancel,
            handler: nil)

        deleteDatabaseConfirmationAlert.addAction(cancelAction)

        let continueAction = UIAlertAction(
            title: "databaseloadingfailure.alert.delete_database.continue".localized,
            style: .destructive,
            handler: { [weak self] _ in
                self?.sessionManager?.removeDatabaseFromDisk()
            }
        )

        deleteDatabaseConfirmationAlert.addAction(continueAction)
        present(deleteDatabaseConfirmationAlert, animated: true)
    }
}
