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

import Foundation
import UIKit
import WireDataModel

extension UIAlertController {
    enum BackupFailedAction {
        case tryAgain, cancel
    }

    static func restoreBackupFailed(with error: Error, completion: @escaping (BackupFailedAction) -> Void) -> UIAlertController {
        return restoreBackupFailed(title: title(for: error), message: message(for: error), completion: completion)
    }

    private static func restoreBackupFailed(title: String, message: String, completion: @escaping (BackupFailedAction) -> Void) -> UIAlertController {
        let controller = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let tryAgainAction = UIAlertAction(
            title: "registration.no_history.restore_backup_failed.try_again".localized,
            style: .default,
            handler: { _ in completion(.tryAgain) }
        )

        controller.addAction(tryAgainAction)
        controller.addAction(.cancel { completion(.cancel) })
        return controller
    }

    private static func title(for error: Error) -> String {
        switch error {
        case
            CoreDataStack.BackupImportError.incompatibleBackup(BackupMetadata.VerificationError.backupFromNewerAppVersion):
            return "registration.no_history.restore_backup_failed.wrong_version.title".localized
        case CoreDataStack.BackupImportError.incompatibleBackup(BackupMetadata.VerificationError.userMismatch):
            return "registration.no_history.restore_backup_failed.wrong_account.title".localized
        default:
            return "registration.no_history.restore_backup_failed.title".localized
        }
    }

    private static func message(for error: Error) -> String {
        switch error {
        case CoreDataStack.BackupImportError.incompatibleBackup(BackupMetadata.VerificationError.backupFromNewerAppVersion):
            return "registration.no_history.restore_backup_failed.wrong_version.message".localized
        case CoreDataStack.BackupImportError.incompatibleBackup(BackupMetadata.VerificationError.userMismatch):
            return "registration.no_history.restore_backup_failed.wrong_account.message".localized
        default:
            return "registration.no_history.restore_backup_failed.message".localized
        }
    }

}
