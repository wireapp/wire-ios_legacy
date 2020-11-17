//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireDataModel
import WireSyncEngine

protocol BackupRestoreControllerDelegate: class {
    func backupResoreControllerDidFinishRestoring(_ controller: BackupRestoreController)
}

/**
 * An object that coordinates restoring a backup.
 */

final class BackupRestoreController: NSObject {
    /// There are some external apps that users can use to transfer backup files, which can modify their attachments and change the underscore with a dash. This is the reason we accept 2 types of file extensions: 'ios_wbu' and 'ios-wbu'
    static let WireBackupUTIs = ["com.wire.backup-ios-underscore", "com.wire.backup-ios-hyphen"]

    let target: SpinnerCapableViewController
    weak var delegate: BackupRestoreControllerDelegate?

    // MARK: - Initialization

    init(target: SpinnerCapableViewController) {
        self.target = target
        super.init()
    }

    // MARK: - Flow

    func startBackupFlow() {
        let controller = UIAlertController.historyImportWarning { [showFilePicker] in
            showFilePicker()
        }

        target.present(controller, animated: true)
    }

    fileprivate func showFilePicker() {
        // Test code to verify restore
        #if arch(i386) || arch(x86_64)
        let testFilePath = "/var/tmp/backup.ios_wbu"
        if FileManager.default.fileExists(atPath: testFilePath) {
            self.restore(with: URL(fileURLWithPath: testFilePath))
            return
        }
        #endif

        let picker = UIDocumentPickerViewController(
            documentTypes: BackupRestoreController.WireBackupUTIs,
            in: .`import`)
        picker.delegate = self
        target.present(picker, animated: true)
    }

    fileprivate func restore(with url: URL) {
        requestPassword { [performRestore] password in
            performRestore(password, url)
        }
    }

    fileprivate func performRestore(using password: String, from url: URL) {
        guard let sessionManager = SessionManager.shared else { return }
        target.isLoadingViewVisible = true

        sessionManager.restoreFromBackup(at: url, password: password) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .failure(SessionManager.BackupError.decryptionError):
                self.target.isLoadingViewVisible = false
                self.showWrongPasswordAlert { _ in
                    self.restore(with: url)
                }

            case .failure(let error):
                BackupEvent.importFailed.track()
                self.showRestoreError(error)
                self.target.isLoadingViewVisible = false

            case .success:
                BackupEvent.importSucceeded.track()
                self.delegate?.backupResoreControllerDidFinishRestoring(self)
            }
        }
    }

    // MARK: - Alerts

    fileprivate func requestPassword(completion: @escaping (String) -> Void) {
        let controller = UIAlertController.requestRestorePassword { password in
            password.apply(completion)
        }

        target.present(controller, animated: true, completion: nil)
    }

    fileprivate func showWrongPasswordAlert(completion: @escaping (UIAlertAction) -> Void) {
        let controller = UIAlertController.importWrongPasswordError(completion: completion)
        target.present(controller, animated: true, completion: nil)
    }

    fileprivate func showRestoreError(_ error: Error) {
        let controller = UIAlertController.restoreBackupFailed(with: error) { [unowned self] action in
            switch action {
            case .tryAgain: self.showFilePicker()
            case .cancel: self.delegate?.backupResoreControllerDidFinishRestoring(self)
            }
        }

        target.present(controller, animated: true)
    }
}

extension BackupRestoreController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.restore(with: url)
    }
}
