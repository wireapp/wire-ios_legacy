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

extension NoHistoryViewController {
    static let WireBackupUTI = "com.wire.ios-backup"
    
    @objc public func createRestoreButton() {
        let restoreBackupButton = UIButton(type: .custom)
        restoreBackupButton.translatesAutoresizingMaskIntoConstraints = false
        restoreBackupButton.setTitle("registration.no_history.restore_backup".localized.uppercased(),
                                     for: .normal)
        restoreBackupButton.titleLabel?.font = FontSpec(.small, .regular).font
    
        restoreBackupButton.addCallback(for: .touchUpInside) { [unowned self] _ in
            self.showWarningMessage()
        }
    
        contentView.addSubview(restoreBackupButton)
    
        NSLayoutConstraint.activate([
            restoreBackupButton.topAnchor.constraint(equalTo: safeTopAnchor),
            restoreBackupButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28)
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
        let picker = UIDocumentMenuViewController(documentTypes: [NoHistoryViewController.WireBackupUTI],
                                                  in: .`import`)
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    fileprivate func showRestoreError(_ error: Error) {
        let alert = UIAlertController(title: "registration.no_history.restore_backup_failed.title".localized,
                                      message: "registration.no_history.restore_backup_failed.message".localized,
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
}

extension NoHistoryViewController: UIDocumentMenuDelegate, UIDocumentPickerDelegate {
    public func documentMenu(_ documentMenu: UIDocumentMenuViewController,
                             didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        self.present(documentPicker, animated: true)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {

        self.showLoadingView = true
        // todo: read UUID()
        SessionManager.shared?.restoreFromBackup(at: url) { result in
            switch result {
            case .failure(let error):
                BackupEvent.importFailed.track()
                self.showRestoreError(error)
            case .success:
                BackupEvent.importSucceeded.track()
                self.formStepDelegate.didCompleteFormStep(self)
            }
            
        }
    }

}
