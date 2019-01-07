//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import UIKit
import Cartography

enum ChangeEmailFlowType {
    case changeExistingEmail
    case setInitialEmail
}

struct ChangeEmailState {
    let flowType: ChangeEmailFlowType
    let currentEmail: String?
    var newEmail: String?
    var newPassword: String?
    
    var visibleEmail: String? {
        return newEmail ?? currentEmail
    }
    
    var validatedEmail: String? {
        guard let newEmail = self.newEmail else { return nil }

        switch UnregisteredUser.normalizedEmailAddress(newEmail) {
        case .valid(let value):
            return value
        default:
            return nil
        }
    }

    var validatedPassword: String? {
        guard let newPassword = self.newPassword else { return nil }

        switch UnregisteredUser.normalizedPassword(newPassword) {
        case .valid(let value):
            return value
        default:
            return nil
        }
    }

    var validatedCredentials: ZMEmailCredentials? {
        guard let email = validatedEmail, let password = validatedPassword else {
            return nil
        }

        return ZMEmailCredentials(email: email, password: password)
    }
    
    var isValid: Bool {
        switch flowType {
        case .changeExistingEmail:
            return validatedEmail != nil
        case .setInitialEmail:
            return validatedCredentials != nil
        }
    }
    
    init(currentEmail: String? = ZMUser.selfUser().emailAddress) {
        self.currentEmail = currentEmail
        flowType = currentEmail != nil ? .changeExistingEmail : .setInitialEmail
    }

}

@objcMembers final class ChangeEmailViewController: SettingsBaseTableViewController {

    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    var state = ChangeEmailState()
    private var observerToken: Any?

    enum Cell: Int {
        case emailField
        case passwordField
    }

    init() {
        super.init(style: .grouped)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observerToken = userProfile?.add(observer: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observerToken = nil
    }
    
    internal func setupViews() {
        RegistrationTextFieldCell.register(in: tableView)
        
        title = "self.settings.account_section.email.change.title".localized(uppercased: true)
        view.backgroundColor = .clear
        tableView.isScrollEnabled = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.account_section.email.change.save".localized(uppercased: true),
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = UIColor.accent()
        updateSaveButtonState()
    }
    
    func updateSaveButtonState(enabled: Bool? = nil) {
        if let enabled = enabled {
            navigationItem.rightBarButtonItem?.isEnabled = enabled
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = state.isValid
        }
    }
    
    @objc func saveButtonTapped(sender: UIBarButtonItem) {
        requestEmailUpdate(showLoadingView: true)
    }

    func requestEmailUpdate(showLoadingView: Bool) {
        let updateBlock: () throws -> Void

        switch state.flowType {
        case .setInitialEmail:
            guard let credentials = state.validatedCredentials else { return }
            updateBlock = { try self.userProfile?.requestSettingEmailAndPassword(credentials: credentials) }
        case .changeExistingEmail:
            guard let email = state.validatedEmail else { return }
            updateBlock = { try self.userProfile?.requestEmailChange(email: email) }
        }

        do {
            try updateBlock()
            updateSaveButtonState(enabled: false)
            navigationController?.showLoadingView = showLoadingView
        } catch { }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state.flowType {
        case .changeExistingEmail: return 1
        case .setInitialEmail: return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationTextFieldCell.zm_reuseIdentifier, for: indexPath) as! RegistrationTextFieldCell

        switch Cell(rawValue: indexPath.row)! {
        case .emailField:
            cell.textField.accessibilityIdentifier = "EmailField"
            cell.textField.placeholder = "email.placeholder".localized
            cell.textField.text = state.visibleEmail
            cell.textField.keyboardType = .emailAddress
            cell.textField.textContentType = .emailAddress
            cell.textField.becomeFirstResponder()

        case .passwordField:
            cell.textField.accessibilityIdentifier = "PasswordField"
            cell.textField.placeholder = "password.placeholder".localized
            cell.textField.isSecureTextEntry = true
            cell.textField.text = nil

            if #available(iOS 12, *) {
                cell.textField.textContentType = .newPassword
            } else if #available(iOS 11, *) {
                cell.textField.textContentType = .password
            }
        }

        cell.delegate = self
        updateSaveButtonState()
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

}

extension ChangeEmailViewController: UserProfileUpdateObserver {
    
    func emailUpdateDidFail(_ error: Error!) {
        navigationController?.showLoadingView = false
        updateSaveButtonState()
        showAlert(forError: error)
    }
    
    func didSendVerificationEmail() {
        navigationController?.showLoadingView = false
        updateSaveButtonState()
        if let newEmail = state.newEmail {
            let confirmController = ConfirmEmailViewController(newEmail: newEmail, delegate: self)
            navigationController?.pushViewController(confirmController, animated: true)
        }
    }    
}

extension ChangeEmailViewController: ConfirmEmailDelegate {
    func didConfirmEmail(inController controller: ConfirmEmailViewController) {
        _ = navigationController?.popToPrevious(of: self)
    }
    
    func resendVerification(inController controller: ConfirmEmailViewController) {
        requestEmailUpdate(showLoadingView: false)
    }
}

extension ChangeEmailViewController: RegistrationTextFieldCellDelegate {
    func tableViewCellDidChangeText(cell: RegistrationTextFieldCell, text: String) {
        guard let index = tableView.indexPath(for: cell), let cellType = Cell(rawValue: index.row) else {
            return
        }

        switch cellType {
        case .emailField:
            state.newEmail = text
        case .passwordField:
            state.newPassword = text
        }

        updateSaveButtonState()
    }
}
