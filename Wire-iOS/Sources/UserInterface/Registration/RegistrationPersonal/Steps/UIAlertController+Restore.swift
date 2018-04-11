//
//  UIAlertController+Restore.swift
//  Wire-iOS
//
//  Created by Zeta on 11.04.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation

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
        case StorageStack.BackupImportError.incompatibleBackup(BackupMetadata.VerificationError.backupFromNewerAppVersion):
            return "registration.no_history.restore_backup_failed.wrong_version.title".localized
        case StorageStack.BackupImportError.incompatibleBackup(BackupMetadata.VerificationError.userMismatch):
            return "registration.no_history.restore_backup_failed.wrong_account.title".localized
        default:
            return "registration.no_history.restore_backup_failed.title".localized
        }
    }
    
    private static func message(for error: Error) -> String {
        switch error {
        case StorageStack.BackupImportError.incompatibleBackup(BackupMetadata.VerificationError.backupFromNewerAppVersion):
            return "registration.no_history.restore_backup_failed.wrong_version.message".localized
        case StorageStack.BackupImportError.incompatibleBackup(BackupMetadata.VerificationError.userMismatch):
            return "registration.no_history.restore_backup_failed.wrong_account.message".localized
        default:
            return "registration.no_history.restore_backup_failed.message".localized
        }
    }
    
}
