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
import ZMUtilities
import zmessaging

fileprivate struct PhoneNumber {
    enum ValidationResult {
        case valid
        case tooLong
        case tooShort
        case containsInvalidCharacters
        case invalid
        
        init(error: Error) {
            let code = (error as NSError).code
            guard let errorCode = ZMManagedObjectValidationErrorCode(rawValue: UInt(code)) else {
                self = .invalid
                return
            }
            
            switch errorCode {
            case .objectValidationErrorCodeStringTooLong:
                self = .tooLong
            case .objectValidationErrorCodeStringTooShort:
                self = .tooShort
            case .objectValidationErrorCodePhoneNumberContainsInvalidCharacters:
                self = .containsInvalidCharacters
            default:
                self = .invalid
            }
        }
    }
    
    let countryCode: UInt
    let fullNumber: String
    let numberWithoutCode: String
    
    init(countryCode: UInt, numberWithoutCode: String) {
        self.countryCode = countryCode
        self.numberWithoutCode = numberWithoutCode
        fullNumber = NSString.phoneNumber(withE164: countryCode as NSNumber , number: numberWithoutCode)
    }
    
    init?(fullNumber: String) {
        guard let country = Country.detect(forPhoneNumber: fullNumber) else { return nil }
        countryCode = country.e164 as UInt
        let prefix = country.e164PrefixString
        numberWithoutCode = fullNumber.substring(from: prefix.endIndex)
        self.fullNumber = fullNumber
        
    }
    
    func validate() -> ValidationResult {
        var validatedNumber = fullNumber as NSString?
        let pointer = AutoreleasingUnsafeMutablePointer<NSString?>(&validatedNumber)
        do {
            try ZMUser.validatePhoneNumber(pointer)
        } catch let error {
            return ValidationResult(error: error)
        }
        
        return .valid
    }
}

extension PhoneNumber: Equatable {
    static func ==(lhs: PhoneNumber, rhs: PhoneNumber) -> Bool {
        return lhs.fullNumber == rhs.fullNumber
    }
}

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
            return phoneNumber != currentNumber
        default:
            return false
        }
    }
    
    init(currentPhoneNumber: String = ZMUser.selfUser().phoneNumber) {
        self.currentNumber = PhoneNumber(fullNumber: currentPhoneNumber)
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
    fileprivate let emailTextField = RegistrationTextField()

    fileprivate var state = ChangePhoneNumberState()
    fileprivate let userProfile = ZMUserSession.shared()?.userProfile
    fileprivate var observerToken: AnyObject?

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
    
    fileprivate func setupViews() {
        RegistrationTextFieldCell.register(in: tableView)
        SettingsButtonCell.register(in: tableView)
        title = "self.settings.account_section.phone_number.change.title".localized
        
        view.backgroundColor = .clear
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.account_section.phone_number.change.save".localized,
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
    
    func saveButtonTapped() {
        if let newNumber = state.newNumber?.fullNumber {
            userProfile?.requestPhoneVerificationCode(phoneNumber: newNumber)
            updateSaveButtonState(enabled: false)
            showLoadingView = true
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let email = ZMUser.selfUser().emailAddress, !email.isEmpty {
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
            cell.textField.keyboardType = .phonePad
            cell.textField.leftAccessoryView = .countryCode
            cell.textField.accessibilityIdentifier = "PhoneNumberField"
            if let current = state.visibleNumber {
                cell.textField.countryCode = current.countryCode
                cell.textField.text = current.numberWithoutCode
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
                self.showLoadingView = true
            })

            present(alert, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func selectCountry() {
        let countryCodeController = CountryCodeTableViewController()
        countryCodeController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: countryCodeController)
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .formSheet
        }
        
        present(navigationController, animated: true, completion: nil)
    }
}

extension ChangePhoneViewController: RegistrationTextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let registrationTextField = textField as! RegistrationTextField
        let newNumber = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? ""
        
        let number = PhoneNumber(countryCode: registrationTextField.countryCode, numberWithoutCode: newNumber)
        switch number.validate() {
        case .containsInvalidCharacters, .tooLong:
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
        state.newNumber = PhoneNumber(countryCode: country.e164 as UInt, numberWithoutCode: state.visibleNumber?.numberWithoutCode ?? "")
        updateSaveButtonState()
    }
}

extension ChangePhoneViewController: UserProfileUpdateObserver {
    func phoneNumberVerificationCodeRequestDidSucceed() {
        showLoadingView = false
        updateSaveButtonState()
        if let newNumber = state.newNumber?.fullNumber {
            let confirmController = ConfirmPhoneViewController(newNumber: newNumber, delegate: self)
            navigationController?.pushViewController(confirmController, animated: true)
        }
    }
    
    func phoneNumberVerificationCodeRequestDidFail(_ error: Error!) {
        showLoadingView = false
        updateSaveButtonState()
        showAlert(forError: error)
    }
    
    func emailUpdateDidFail(_ error: Error!) {
        showLoadingView = false
        updateSaveButtonState()
        showAlert(forError: error)
    }
    
    func phoneNumberRemovalDidFail(_ error: Error!) {
        showLoadingView = false
        updateSaveButtonState()
        showAlert(forError: error)
    }
    
    func didRemovePhoneNumber() {
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
        _ = navigationController?.popToPrevious(of: self)
    }
}
