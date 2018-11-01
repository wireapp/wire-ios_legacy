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
        restoreBackupButton.setTitle("registration.no_history.restore_backup".localized.uppercased(), for: .normal)
        
        restoreBackupButton.addCallback(for: .touchUpInside) { [showWarningMessage] _ in
            showWarningMessage()
        }
        
        restoreBackupButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        stackView.addArrangedSubview(restoreBackupButton)
    
        let okButton = Button(style: .fullMonochrome)
        okButton.translatesAutoresizingMaskIntoConstraints = false
        let gotItText = self.localizableString(forPart: "got_it")!
        okButton.setTitle(gotItText.localized, for: .normal)
        okButton.addCallback(for: .touchUpInside) { [unowned self] _ in
            self.authenticationCoordinator?.completeBackupStep()
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
    
    fileprivate func showFilePicker() {
        // Test code to verify restore
        #if arch(i386) || arch(x86_64)
            let testFilePath = "/var/tmp/backup.ios_wbu"
            if FileManager.default.fileExists(atPath: testFilePath) {
                self.restore(with: URL(fileURLWithPath: testFilePath))
                return
            }
        #endif
        
        let picker = UIDocumentPickerViewController(documentTypes: [NoHistoryViewController.WireBackupUTI], in: .`import`)
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    fileprivate func restore(with url: URL) {
        requestPassword { [performRestore] password in
            performRestore(password, url)
        }
    }
    
    fileprivate func performRestore(using password: String, from url: URL) {
        guard let sessionManager = SessionManager.shared else { return }
        spinnerView.subtitle = "registration.no_history.restore_backup.restoring".localized.uppercased()
        showLoadingView = true
        
        sessionManager.restoreFromBackup(at: url, password: password) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .failure(SessionManager.BackupError.decryptionError):
                self.showLoadingView = false
                self.showWrongPasswordAlert {
                    self.restore(with: url)
                }
            case .failure(let error):
                BackupEvent.importFailed.track()
                self.showRestoreError(error)
                self.showLoadingView = false
            case .success:
                BackupEvent.importSucceeded.track()
                self.spinnerView.subtitle = "registration.no_history.restore_backup.completed".localized.uppercased()
                self.indicateLoadingSuccessRemovingCheckmark(false) {
                    self.authenticationCoordinator?.completeBackupStep()
                }
            }
        }
    }
    
    // MARK: - Alerts
    
    fileprivate func showWarningMessage() {
        let controller = UIAlertController.historyImportWarning { [showFilePicker] in
            showFilePicker()
        }
        present(controller, animated: true)
    }
    
    fileprivate func requestPassword(completion: @escaping (String) -> Void) {
        let controller = UIAlertController.requestRestorePassword { password in
            password.apply(completion)
        }
        present(controller, animated: true, completion: nil)
    }
    
    fileprivate func showWrongPasswordAlert(completion: @escaping () -> Void) {
        let controller = UIAlertController.importWrongPasswordError(completion: completion)
        present(controller, animated: true, completion: nil)
    }
    
    fileprivate func showRestoreError(_ error: Error) {
        let controller = UIAlertController.restoreBackupFailed(with: error) { [unowned self] action in
            switch action {
            case .tryAgain: self.showFilePicker()
            case .cancel: self.authenticationCoordinator?.completeBackupStep()
            }
        }
        present(controller, animated: true)
    }
}

extension NoHistoryViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.restore(with: url)
    }
}
