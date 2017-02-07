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
import Classy
import Cartography

protocol ChangeEmailTableViewCellDelegate: class {
    func tableViewCellDidChangeText(cell: ChangeEmailTableViewCell, text: String)
}

final class ChangeEmailTableViewCell: UITableViewCell {
    
    let emailTextField = RegistrationTextField()
    weak var delegate: ChangeEmailTableViewCellDelegate?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        addSubview(emailTextField)
        emailTextField.accessibilityIdentifier = "EmailField"
        emailTextField.keyboardType = .emailAddress
        emailTextField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }
    
    func createConstraints() {
        constrain(self, emailTextField) { view, emailTextField in
            emailTextField.top == view.top
            emailTextField.bottom == view.bottom
            emailTextField.trailing == view.trailing - 8
            emailTextField.leading == view.leading + 8
        }
    }
    
    func editingChanged(textField: UITextField) {
        let lowercase = textField.text?.lowercased() ?? ""
        let noSpaces = lowercase.components(separatedBy: .whitespacesAndNewlines).joined()
        textField.text = noSpaces
        delegate?.tableViewCellDidChangeText(cell: self, text: noSpaces)
    }
}

struct ChangeEmailState {
    let currentEmail: String
    var newEmail: String?
    
    var visibleEmail: String {
        return newEmail ?? currentEmail
    }
    
    var validatedEmail: String? {
        var validatedEmail = newEmail as AnyObject?
        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&validatedEmail)
        do {
            try ZMUser.editableSelf().validateValue(pointer, forKey: #keyPath(ZMUser.emailAddress))
            return validatedEmail as? String
        } catch {
            return nil
        }
    }
    
    var saveButtonEnabled: Bool {
        guard let email = validatedEmail, !email.isEmpty else { return false }
        return email != currentEmail
    }
    
    init(currentEmail: String = ZMUser.selfUser().emailAddress) {
        self.currentEmail = currentEmail
    }

}

final class ChangeEmailViewController: SettingsBaseTableViewController {

    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    var state = ChangeEmailState()
    private var observerToken: AnyObject?

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
        guard let token = observerToken else { return }
        userProfile?.removeObserver(token: token)
    }
    
    internal func setupViews() {
        ChangeEmailTableViewCell.register(in: tableView)
        
        title = "self.settings.account_section.email.change.title".localized
        view.backgroundColor = .clear
        tableView.isScrollEnabled = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.account_section.email.change.save".localized,
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
            navigationItem.rightBarButtonItem?.isEnabled = state.saveButtonEnabled
        }
    }
    
    func saveButtonTapped(sender: UIBarButtonItem) {
        guard let email = state.newEmail else { return }
        do {
            try userProfile?.requestEmailChange(email: email)
            updateSaveButtonState(enabled: false)
            showLoadingView = true
        } catch { }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChangeEmailTableViewCell.zm_reuseIdentifier, for: indexPath) as! ChangeEmailTableViewCell
        
        cell.emailTextField.text = state.visibleEmail
        cell.emailTextField.becomeFirstResponder()
        cell.delegate = self
        updateSaveButtonState()
        return cell
    }

}

extension ChangeEmailViewController: UserProfileUpdateObserver {
    
    func emailUpdateDidFail(_ error: Error!) {
        showLoadingView = false
        updateSaveButtonState()
        showAlert(forError: error)
    }
    
    func didSentVerificationEmail() {
        showLoadingView = false
        updateSaveButtonState()
        if let newEmail = state.newEmail {
            let confirmController = ConfirmEmailViewController(newEmail: newEmail, delegate: self)
            navigationController?.pushViewController(confirmController, animated: true)
        }
    }    
}

extension ChangeEmailViewController: ConfirmEmailDelegate {
    func didConfirmEmail(inController controller: ConfirmEmailViewController) {
        if let viewControllers = navigationController?.viewControllers, let currentIdx = viewControllers.index(of: self) {
            // We want to pop to previous view controller
            let previousIdx = currentIdx - 1
            if viewControllers.count > previousIdx {
                let previousController = viewControllers[previousIdx]
                _ = navigationController?.popToViewController(previousController, animated: true)
            }
        }
    }
    
    func resendVerification(inController controller: ConfirmEmailViewController) {
        if let validatedEmail = state.validatedEmail {
            try? userProfile?.requestEmailChange(email: validatedEmail)
            
            let message = String(format: "self.settings.account_section.email.change.resend.message".localized, validatedEmail)
            let alert = UIAlertController(
                title: "self.settings.account_section.email.change.resend.title".localized,
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(.init(title: "general.ok".localized, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}

extension ChangeEmailViewController: ChangeEmailTableViewCellDelegate {
    func tableViewCellDidChangeText(cell: ChangeEmailTableViewCell, text: String) {
        state.newEmail = text
        updateSaveButtonState()
    }
}
