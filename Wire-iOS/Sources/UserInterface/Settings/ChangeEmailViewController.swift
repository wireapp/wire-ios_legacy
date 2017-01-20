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

final class DeleteEmailTableViewCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.text = "self.settings.account_section.email.change.remove_email".localized
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
    
    init(currentEmail: String = ZMUser.selfUser().emailAddress) {
        self.currentEmail = currentEmail
    }
    
    func removeEmail(withPassword password: String) { }
    
    func changeEmail(withPassword password: String) { }
}

final class ChangeEmailViewController: SettingsBaseTableViewController {

    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    var state = ChangeEmailState()
    let passwordProvider = AccountPasswordProvider()
    
    init() {
        super.init(style: .grouped)
        CASStyler.default().styleItem(self)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func setupViews() {
        ChangeEmailTableViewCell.register(in: tableView)
        DeleteEmailTableViewCell.register(in: tableView)
        
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
    
    func toggleSaveButton() {
        navigationItem.rightBarButtonItem?.isEnabled = state.saveButtonEnabled
    }
    
    func saveButtonTapped(sender: UIBarButtonItem) {
        passwordProvider.askForAccountPassword(reason: .changingEmail, showInController: self) { [weak self] password in
            guard let `self` = self else { return }
            self.state.changeEmail(withPassword: password)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
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
            return tableView.dequeueReusableCell(withIdentifier: DeleteEmailTableViewCell.zm_reuseIdentifier, for: indexPath)
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

extension ChangeEmailViewController: ChangeEmailTableViewCellDelegate {
    func tableViewCellDidChangeText(cell: ChangeEmailTableViewCell, text: String) {
        state.newEmail = text
        toggleSaveButton()
    }
}
