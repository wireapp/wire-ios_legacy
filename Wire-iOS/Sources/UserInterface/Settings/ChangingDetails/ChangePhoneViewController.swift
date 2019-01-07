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
import WireUtilities
import WireSyncEngine


fileprivate struct ChangePhoneNumberState {
    let currentNumber: PhoneNumber?
    var newNumber: PhoneNumber?
    
    var visibleNumber: PhoneNumber? {
        return newNumber ?? currentNumber
    }
    
    var isValid: Bool {
        guard let phoneNumber = visibleNumber else { return false }
        switch phoneNumber.validate() {
        case .valid:
            // No current number -> it's a valid change
            guard let current = currentNumber else { return true }
            return phoneNumber != current
        default:
            return false
        }
    }
    
    init(currentPhoneNumber: String? = ZMUser.selfUser().phoneNumber) {
        self.currentNumber = currentPhoneNumber.flatMap(PhoneNumber.init(fullNumber:))
    }
    
}

fileprivate enum Section: Int {
    static var count: Int {
        return 2
    }
    
    case phoneNumber = 0
    case remove = 1
}

final class ChangePhoneViewController: SettingsBaseTableViewController {
    fileprivate var state = ChangePhoneNumberState()
    fileprivate let userProfile = ZMUserSession.shared()?.userProfile
    fileprivate var observerToken: Any?
    
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
    
    fileprivate func setupViews() {
        RegistrationTextFieldCell.register(in: tableView)
        SettingsButtonCell.register(in: tableView)
        title = "self.settings.account_section.phone_number.change.title".localized(uppercased: true)
        
        view.backgroundColor = .clear
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.account_section.phone_number.change.save".localized(uppercased: true),
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
    }
    
    fileprivate func updateSaveButtonState(enabled: Bool? = nil) {
        if let enabled = enabled {
            navigationItem.rightBarButtonItem?.isEnabled = enabled
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = state.isValid
        }
    }
    
    @objc func saveButtonTapped() {
        if let newNumber = state.newNumber?.fullNumber {
            userProfile?.requestPhoneVerificationCode(phoneNumber: newNumber)
            updateSaveButtonState(enabled: false)
            navigationController?.showLoadingView = true
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if ZMUser.selfUser()?.phoneNumber == nil {
            return 1
        } else if let email = ZMUser.selfUser().emailAddress, !email.isEmpty {
            return Section.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .phoneNumber:
            let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationTextFieldCell.zm_reuseIdentifier, for: indexPath) as! RegistrationTextFieldCell
            cell.textField.isPhoneNumberMode = true
            cell.textField.leftAccessoryView = .countryCode
            cell.textField.accessibilityIdentifier = "PhoneNumberField"
            cell.textField.placeholder = "registration.enter_phone_number.placeholder".localized
            if let current = state.visibleNumber {
                cell.textField.countryCode = current.countryCode
                cell.textField.text = current.numberWithoutCode
            } else {
                cell.textField.countryCode = Country.default.e164.uintValue
            }
            cell.textField.becomeFirstResponder()
            cell.textField.delegate = self
            cell.textField.countryCodeButton.addTarget(self, action: #selector(selectCountry), for: .touchUpInside)
            updateSaveButtonState()
            return cell
        case .remove:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsButtonCell.zm_reuseIdentifier, for: indexPath) as! SettingsButtonCell
            cell.titleText = "self.settings.account_section.phone_number.change.remove".localized
            cell.titleColor = .white
            cell.selectionStyle = .default
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .phoneNumber:
            break
        case .remove:
            let alert = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .actionSheet
            )
            
            alert.addAction(.init(title: "general.cancel".localized, style: .cancel, handler: nil))
            alert.addAction(.init(title: "self.settings.account_section.phone_number.change.remove.action".localized, style: .destructive) { [weak self] _ in
                guard let `self` = self else { return }
                self.userProfile?.requestPhoneNumberRemoval()
                self.updateSaveButtonState(enabled: false)
                self.navigationController?.showLoadingView = true
                })
            
            present(alert, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    @objc func selectCountry() {
        let countryCodeController = CountryCodeTableViewController()
        countryCodeController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: countryCodeController)
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .formSheet
        }
        
        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - RegistrationTextFieldDelegate
extension ChangePhoneViewController: RegistrationTextFieldDelegate {
    func textField(_ textField: UITextField, shouldPasteCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let registrationTextField = textField as? RegistrationTextField else { return false }
        
        return insert(phoneNumber: string, registrationTextField: registrationTextField)
    }


    /// Insert a phone number to a RegistrationTextField or return true if it is not a valide number to insert.
    ///
    /// - Parameters:
    ///   - phoneNumber: the phone number to insert
    ///   - registrationTextField: the RegistrationTextField to insert the phone number
    /// - Returns: return false if the phone number is inserted manually in this method. Otherwise return true.
    func insert(phoneNumber: String, registrationTextField: RegistrationTextField) -> Bool {

        guard let (_, phoneNumberWithoutCountryCode) = registrationTextField.insert(phoneNumber: phoneNumber) else {
            return true
        }

        let number = PhoneNumber(countryCode: registrationTextField.countryCode, numberWithoutCode: phoneNumberWithoutCountryCode)
        state.newNumber = number
        updateSaveButtonState()

        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let registrationTextField = textField as? RegistrationTextField else { return false }
        guard let newString = (registrationTextField.text as NSString?)?.replacingCharacters(in: range, with: string) else { return false }

        ///If the textField is empty and a replacementString with longer than 1 char, it is likely to insert from autoFill.
        if textField.text?.count == 0 && newString.count > 1 {
            return insert(phoneNumber: newString, registrationTextField: registrationTextField)
        }
        
        let number = PhoneNumber(countryCode: registrationTextField.countryCode, numberWithoutCode: newString)
        switch number.validate() {
        case .containsInvalidCharacters,
             .tooLong:
            return false
        default:
            break
        }
        
        state.newNumber = number
        updateSaveButtonState()

        return true
    }
}

extension ChangePhoneViewController: CountryCodeTableViewControllerDelegate {
    func countryCodeTableViewController(_ viewController: UIViewController!, didSelect country: Country!) {
        viewController.dismiss(animated: true, completion: nil)
        state.newNumber = PhoneNumber(countryCode: country.e164.uintValue, numberWithoutCode: state.visibleNumber?.numberWithoutCode ?? "")
        updateSaveButtonState()
    }
}

extension ChangePhoneViewController: UserProfileUpdateObserver {
    func phoneNumberVerificationCodeRequestDidSucceed() {
        navigationController?.showLoadingView = false
        updateSaveButtonState()
        if let newNumber = state.newNumber?.fullNumber {
            let confirmController = ConfirmPhoneViewController(newNumber: newNumber, delegate: self)
            navigationController?.pushViewController(confirmController, animated: true)
        }
    }
    
    func phoneNumberVerificationCodeRequestDidFail(_ error: Error!) {
        navigationController?.showLoadingView = false
        updateSaveButtonState()
        showAlert(forError: error)
    }
    
    func emailUpdateDidFail(_ error: Error!) {
        navigationController?.showLoadingView = false
        updateSaveButtonState()
        showAlert(forError: error)
    }
    
    func phoneNumberRemovalDidFail(_ error: Error!) {
        navigationController?.showLoadingView = false
        updateSaveButtonState()
        showAlert(forError: error)
    }
    
    func didRemovePhoneNumber() {
        navigationController?.showLoadingView = false
        _ = navigationController?.popToPrevious(of: self)
    }
    
}

extension ChangePhoneViewController: ConfirmPhoneDelegate {
    func resendVerificationCode(inController controller: ConfirmPhoneViewController) {
        if let newNumber = state.newNumber?.fullNumber {
            userProfile?.requestPhoneVerificationCode(phoneNumber: newNumber)
        }
    }
    
    func didConfirmPhone(inController controller: ConfirmPhoneViewController) {
        self.navigationController?.showLoadingView = false
        _ = navigationController?.popToPrevious(of: self)
    }
}
