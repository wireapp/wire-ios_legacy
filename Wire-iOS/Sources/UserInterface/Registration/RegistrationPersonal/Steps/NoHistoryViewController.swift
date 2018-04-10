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
import WireDataModel


extension NoHistoryViewController {
    static let WireBackupUTI = "com.wire.backup-ios"
    
    @objc public func createButtons() {
        let restoreBackupButton = Button(style: .emptyMonochrome)
        restoreBackupButton.translatesAutoresizingMaskIntoConstraints = false
        restoreBackupButton.setTitle("registration.no_history.restore_backup".localized.uppercased(),
                                     for: .normal)
        
        restoreBackupButton.addCallback(for: .touchUpInside) { [unowned self] _ in
            if self.contextType == .loggedOut {
                self.showWarningMessage()
            }
            else {
                self.showFilePicker()
            }
        }
        
        restoreBackupButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        stackView.addArrangedSubview(restoreBackupButton)
    
    
        let okButton = Button(style: .fullMonochrome)
        okButton.translatesAutoresizingMaskIntoConstraints = false
        let gotItText = self.localizableString(forPart: "got_it")!
        okButton.setTitle(gotItText.localized, for: .normal)
        okButton.addCallback(for: .touchUpInside) { [unowned self] _ in
            self.showLoadingView = true
            self.formStepDelegate.didCompleteFormStep(self)
        }
        
        okButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        stackView.addArrangedSubview(okButton)
    }
    
    @objc public func createContentViewConstraints() {
        if self.traitCollection.horizontalSizeClass == .regular {
            NSLayoutConstraint.activate([
                contentView.widthAnchor.constraint(equalToConstant: parent!.maximumFormSize.width),
                contentView.heightAnchor.constraint(equalToConstant: parent!.maximumFormSize.height),
                contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
        else {
            contentView.fitInSuperview()
        }
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -28 - UIScreen.safeArea.bottom),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28)
        ])
    }

    fileprivate func showWarningMessage() {
        let alert = UIAlertController(title: "registration.no_history.restore_backup_warning.title".localized,
                                      message: "registration.no_history.restore_backup_warning.message".localized,
                                      cancelButtonTitle: "general.cancel".localized)
        
        let proceedAction = UIAlertAction(title: "registration.no_history.restore_backup_warning.proceed".localized,
                                          style: .default) { [unowned self] _ in
             self.showFilePicker()
        }
        alert.addAction(proceedAction)
        
        self.present(alert, animated: true)
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
        
        let picker = UIDocumentPickerViewController(documentTypes: [NoHistoryViewController.WireBackupUTI],
                                                  in: .`import`)
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    private func errorMessage(for error: Error) -> String {
        switch error {
        case StorageStack.BackupImportError.incompatibleBackup(let underlyingError):
            switch underlyingError {
            case BackupMetadata.VerificationError.backupFromNewerAppVersion:
                return "registration.no_history.restore_backup_failed.wrong_version.message".localized
            case BackupMetadata.VerificationError.userMismatch:
                return "registration.no_history.restore_backup_failed.wrong_account.message".localized
            default:
                return "registration.no_history.restore_backup_failed.message".localized
            }
            
        default:
            return "registration.no_history.restore_backup_failed.message".localized
        }
    }

    fileprivate func showRestoreError(_ error: Error) {
        
        let alert = UIAlertController(title: "registration.no_history.restore_backup_failed.title".localized,
                                      message: errorMessage(for: error),
                                      preferredStyle: .alert)
        
        let tryAgainAction = UIAlertAction(title: "registration.no_history.restore_backup_failed.try_again".localized,
                                          style: .default) { [unowned self] _ in
                                            self.showFilePicker()
        }
        alert.addAction(tryAgainAction)
        
        let cancelAction = UIAlertAction(title: "general.cancel".localized,
                                           style: .cancel) { [unowned self] _ in
            self.formStepDelegate.didCompleteFormStep(self)
        }
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
    }
    
    fileprivate func restore(with url: URL) {
        guard let sessionManager = SessionManager.shared else {
            return
        }
        
        self.showLoadingView = true
        sessionManager.restoreFromBackup(at: url) { result in
            switch result {
            case .failure(let error):
                BackupEvent.importFailed.track()
                self.showRestoreError(error)
                self.showLoadingView = false
            case .success:
                BackupEvent.importSucceeded.track()
                self.indicateLoadingSuccessRemovingCheckmark(false) {
                    self.formStepDelegate.didCompleteFormStep(self)
                }
            }
        }
    }
}

extension NoHistoryViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.restore(with: url)
    }
}
