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

final class ShortLabelTableViewCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let clearView = UIView()
        clearView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        selectedBackgroundView = clearView
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ChangeEmailState {
    let currentEmail: String
    var newEmail: String?
    
    var saveButtonEnabled: Bool {
        guard let email = newEmail else { return false }
        if email.isEmpty { return false }
        return email != currentEmail
    }
    
    var removeEmailAllowed: Bool {
        if let phoneNumber = ZMUser.selfUser().phoneNumber, !phoneNumber.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    init(currentEmail: String = ZMUser.selfUser().emailAddress) {
        self.currentEmail = currentEmail
    }
    
    func removeEmail(withPassword password: String) { }

}

final class ChangeEmailViewController: SettingsBaseTableViewController {

    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    var state = ChangeEmailState()
    let passwordProvider = AccountPasswordProvider()
    private var observerToken: AnyObject?

    init() {
        super.init(style: .grouped)
        CASStyler.default().styleItem(self)
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
        ShortLabelTableViewCell.register(in: tableView)
        
        title = "self.settings.account_section.email.change.title".localized
        view.backgroundColor = .clear
        tableView.isScrollEnabled = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.account_section.email.change.save".localized,
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
        toggleSaveButton()
    }
    
    func toggleSaveButton(enabled: Bool? = nil) {
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
            toggleSaveButton(enabled: false)
            showLoadingView = true
        } catch { }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return state.removeEmailAllowed ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: ChangeEmailTableViewCell.zm_reuseIdentifier, for: indexPath) as! ChangeEmailTableViewCell
            cell.emailTextField.text = state.currentEmail
            cell.emailTextField.becomeFirstResponder()
            cell.emailTextField.selectAll(nil)
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ShortLabelTableViewCell.zm_reuseIdentifier, for: indexPath)
            cell.textLabel?.text = "self.settings.account_section.email.change.remove_email".localized
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            passwordProvider.askForAccountPassword(reason: .removingEmail, showInController: self) { [weak self] password in
                guard let `self` = self else { return }
                self.state.removeEmail(withPassword: password)
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

}

extension ChangeEmailViewController: UserProfileUpdateObserver {
    
    func emailUpdateDidFail(_ error: Error!) {
        showLoadingView = false
        toggleSaveButton()
        presentFailureAlert()
    }
    
    func didSentVerificationEmail() {
        showLoadingView = false
        toggleSaveButton()
        if let newEmail = state.newEmail {
            let confirmController = ConfirmEmailViewController(newEmail: newEmail, delegate: self)
            navigationController?.pushViewController(confirmController, animated: true)
        }
    }
    
    private func presentFailureAlert() {
        let alert = UIAlertController(
            title: "self.settings.account_section.email.change.failure_alert.title".localized,
            message: "self.settings.account_section.email.change.failure_alert.message".localized,
            preferredStyle: .alert
        )
        
        alert.addAction(.init(title: "general.ok".localized, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension ChangeEmailViewController: ConfirmEmailDelegate {
    func didConfirmEmail(inController controller: ConfirmEmailViewController) {
        if let viewControllers = navigationController?.viewControllers, viewControllers.count > 2 {
            let accountController = viewControllers[1]
            _ = navigationController?.popToViewController(accountController, animated: true)
        }
    }
}

extension ChangeEmailViewController: ChangeEmailTableViewCellDelegate {
    func tableViewCellDidChangeText(cell: ChangeEmailTableViewCell, text: String) {
        state.newEmail = text
        toggleSaveButton()
    }
}
