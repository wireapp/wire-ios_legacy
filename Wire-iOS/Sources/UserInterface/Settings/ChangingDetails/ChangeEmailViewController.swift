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
    
    var isValid: Bool {
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
        _ = userProfile?.removeObserver(token: token)
    }
    
    internal func setupViews() {
        RegistrationTextFieldCell.register(in: tableView)
        
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
            navigationItem.rightBarButtonItem?.isEnabled = state.isValid
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
        let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationTextFieldCell.zm_reuseIdentifier, for: indexPath) as! RegistrationTextFieldCell
        cell.textField.accessibilityIdentifier = "EmailField"
        cell.textField.keyboardType = .emailAddress
        cell.textField.text = state.visibleEmail
        cell.textField.becomeFirstResponder()
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
        _ = navigationController?.popToPrevious(of: self)
    }
    
    func resendVerification(inController controller: ConfirmEmailViewController) {
        if let validatedEmail = state.validatedEmail {
            try? userProfile?.requestEmailChange(email: validatedEmail)            
        }
    }
}

extension ChangeEmailViewController: RegistrationTextFieldCellDelegate {
    func tableViewCellDidChangeText(cell: RegistrationTextFieldCell, text: String) {
        state.newEmail = text
        updateSaveButtonState()
    }
}
