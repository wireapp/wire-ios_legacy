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
import WireSyncEngine

enum ChangeEmailFlowType {
    case changeExistingEmail
    case setInitialEmail
}

struct ChangeEmailState {
    let flowType: ChangeEmailFlowType
    let currentEmail: String?
    var newEmail: String?
    var newPassword: String?

    var emailValidationError: TextFieldValidator.ValidationError?
    var passwordValidationError: TextFieldValidator.ValidationError?
    var isEmailPasswordInputValid: Bool

    var visibleEmail: String? {
        return newEmail ?? currentEmail
    }

    var validatedEmail: String? {
        guard let newEmail = self.newEmail else { return nil }

        switch flowType {
        case .changeExistingEmail:
            guard case .none = emailValidationError else {
                return nil
            }

            return newEmail

        case .setInitialEmail:
            return isEmailPasswordInputValid ? newEmail : nil
        }
    }

    var validatedPassword: String? {
        guard let newPassword = self.newPassword else { return nil }
        return isEmailPasswordInputValid ? newPassword : nil
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
            return isEmailPasswordInputValid
        }
    }

    init(currentEmail: String?) {
        self.currentEmail = currentEmail
        flowType = currentEmail != nil ? .changeExistingEmail : .setInitialEmail
        emailValidationError = currentEmail != nil ? nil : .tooShort(kind: .email)
        isEmailPasswordInputValid = false
    }

}

final class ChangeEmailViewController: SettingsBaseTableViewController {

    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    var state: ChangeEmailState
    private var observerToken: Any?

    let emailCell = AccessoryTextFieldCell(style: .default, reuseIdentifier: nil)
    let emailPasswordCell = EmailPasswordTextFieldCell(style: .default, reuseIdentifier: nil)
    let validationCell = ValueValidationCell(initialValidation: .info(PasswordRuleSet.localizedErrorMessage))

    init(user: UserType) {
        state = ChangeEmailState(currentEmail: user.emailAddress)
        super.init(style: .grouped)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observerToken = userProfile?.add(observer: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        _ = emailCell.textField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        observerToken = nil
    }

    private func setupViews() {
        title = "self.settings.account_section.email.change.title".localized(uppercased: true)
        view.backgroundColor = .clear
        tableView.isScrollEnabled = false

        emailCell.textField.kind = .email
        emailCell.textField.showConfirmButton = false
        emailCell.textField.backgroundColor = .clear
        emailCell.textField.textColor = .white
        emailCell.textField.accessibilityIdentifier = "EmailField"
        emailCell.textField.textFieldValidationDelegate = self
        emailCell.textField.addTarget(self, action: #selector(emailTextFieldEditingChanged), for: .editingChanged)

        emailPasswordCell.textField.emailField.showConfirmButton = false
        emailPasswordCell.textField.passwordField.showConfirmButton = false
        emailPasswordCell.textField.delegate = self

        emailPasswordCell.textField.setBackgroundColor(.clear)
        emailPasswordCell.textField.setTextColor(.white)
        emailPasswordCell.textField.setSeparatorColor(.white)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.account_section.email.change.save".localized(uppercased: true),
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )

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
        if let passwordError = state.passwordValidationError {
            validationCell.updateValidation(.error(passwordError, showVisualFeedback: true))
            emailPasswordCell.textField.passwordField.showGuidanceDot()
            return
        }

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
            navigationController?.isLoadingViewVisible = showLoadingView
        } catch { }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state.flowType {
        case .changeExistingEmail:
            return 1

        case .setInitialEmail:
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch state.flowType {
        case .changeExistingEmail:
            emailCell.textField.text = state.visibleEmail
            return emailCell

        case .setInitialEmail:
            if indexPath.row == 0 {
                return emailPasswordCell
            } else {
                return validationCell
            }
        }
    }

}

extension ChangeEmailViewController: UserProfileUpdateObserver {

    func emailUpdateDidFail(_ error: Error!) {
        navigationController?.isLoadingViewVisible = false
        updateSaveButtonState()
        showAlert(for: error)
    }

    func didSendVerificationEmail() {
        navigationController?.isLoadingViewVisible = false
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

extension ChangeEmailViewController: TextFieldValidationDelegate {

    @objc func emailTextFieldEditingChanged(sender: AccessoryTextField) {
        state.newEmail = sender.input.trimmingCharacters(in: .whitespacesAndNewlines)
        sender.validateInput()
    }

    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        state.emailValidationError = error
        updateSaveButtonState()
    }

}

extension ChangeEmailViewController: EmailPasswordTextFieldDelegate {

    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String)) {
        // no-op: n
    }

    func textFieldDidUpdateText(_ textField: EmailPasswordTextField) {
        // Update the state
        state.newEmail = textField.emailField.input.trimmingCharacters(in: .whitespacesAndNewlines)
        state.newPassword = textField.passwordField.input
        state.emailValidationError = textField.emailValidationError
        state.passwordValidationError = textField.passwordValidationError
        state.isEmailPasswordInputValid = textField.emailField.isInputValid && !textField.isPasswordEmpty

        // Re-enable the buttons if needed
        updateSaveButtonState()
        validationCell.updateValidation(nil)
        textField.passwordField.hideGuidanceDot()
    }

    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField) {
        // no-op: ever called, we disable the confirm button
    }

}
