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

struct PhoneNumber {
    let countryCode: UInt
    let fullNumber: String
    let numberWithoutCode: String
    
    init(countryCode: UInt, numberWithoutCode: String) {
        self.countryCode = countryCode
        self.numberWithoutCode = numberWithoutCode
        fullNumber = "+\(countryCode)\(numberWithoutCode)"
    }
    
    init?(fullNumber: String) {
        guard let country = Country.detect(forPhoneNumber: fullNumber) else { return nil }
        countryCode = country.e164 as UInt
        let prefix = country.e164PrefixString
        numberWithoutCode = fullNumber.substring(from: prefix.endIndex)
        self.fullNumber = fullNumber
    }
}

extension PhoneNumber: Equatable {
    static func ==(lhs: PhoneNumber, rhs: PhoneNumber) -> Bool {
        return lhs.fullNumber == rhs.fullNumber
    }
}

struct ChangePhoneNumberState {
    let currentNumber: PhoneNumber?
    var newNumber: PhoneNumber?
    
    var visibleNumber: PhoneNumber? {
        return newNumber ?? currentNumber
    }
    
    var validatedPhoneNumber: PhoneNumber? {
        var validatedEmail = newNumber?.fullNumber as AnyObject?
        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&validatedEmail)
        do {
            try ZMUser.editableSelf().validateValue(pointer, forKey: #keyPath(ZMUser.phoneNumber))
            guard let fullNumber = validatedEmail as? String else { return nil }
            return PhoneNumber(fullNumber: fullNumber)
        } catch {
            return nil
        }
    }
    
    var saveButtonEnabled: Bool {
        guard let phoneNumber = validatedPhoneNumber else { return false }
        return phoneNumber != currentNumber
    }
    
    init(currentPhoneNumber: String = ZMUser.selfUser().phoneNumber) {
        self.currentNumber = PhoneNumber(fullNumber: currentPhoneNumber)
    }
    
}

final class ChangePhoneViewController: SettingsBaseTableViewController {
    let emailTextField = RegistrationTextField()

    var state = ChangePhoneNumberState()

    init() {
        super.init(style: .grouped)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        RegistrationTextFieldCell.register(in: tableView)
        title = "self.settings.account_section.phone_number.change.title".localized
        
        view.backgroundColor = .clear
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.account_section.phone_number.change.save".localized,
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
    }
    
    func updateSaveButtonState(enabled: Bool? = nil) {
        if let enabled = enabled {
            navigationItem.rightBarButtonItem?.isEnabled = enabled
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = state.saveButtonEnabled
        }
    }
    
    func saveButtonTapped() {
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationTextFieldCell.zm_reuseIdentifier, for: indexPath) as! RegistrationTextFieldCell
        cell.textField.keyboardType = .phonePad
        cell.textField.leftAccessoryView = .countryCode
        cell.textField.accessibilityIdentifier = "PhoneNumberField"
        if let current = state.visibleNumber {
            cell.textField.countryCode = current.countryCode
            cell.textField.text = current.numberWithoutCode
        }
        cell.textField.becomeFirstResponder()
        cell.delegate = self
        updateSaveButtonState()
        return cell
    }
}

extension ChangePhoneViewController: RegistrationTextFieldCellDelegate {
        func tableViewCellDidChangeText(cell: RegistrationTextFieldCell, text: String) {
            let textField = cell.textField
            state.newNumber = PhoneNumber(countryCode: textField.countryCode, numberWithoutCode: textField.text ?? "")
            updateSaveButtonState()
        }
}
