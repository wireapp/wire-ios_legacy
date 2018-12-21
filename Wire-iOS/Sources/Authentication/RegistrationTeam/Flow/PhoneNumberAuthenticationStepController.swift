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

import UIKit

/**
 * A phone number for displaying a phone number input view as the main view instead of the one
 * provided by the step description.
 */

class PhoneNumberAuthenticationStepController: AuthenticationStepController, PhoneNumberInputViewDelegate, CountryCodeTableViewControllerDelegate {

    let phoneInputView = PhoneNumberInputView()

    override func createMainView() -> UIView {
        phoneInputView.delegate = self
        phoneInputView.tintColor = .black
        return phoneInputView
    }

    // MARK: - Events

    func phoneNumberInputViewDidRequestCountryPicker(_ phoneNumberInput: PhoneNumberInputView) {
        let countryCodePicker = CountryCodeTableViewController()
        countryCodePicker.delegate = self
        countryCodePicker.modalPresentationStyle = .formSheet

        let navigationController = countryCodePicker.wrapInNavigationController()
        present(navigationController, animated: true)
    }

    func phoneNumberInputView(_ inputView: PhoneNumberInputView, didPickPhoneNumber phoneNumber: String) {
        valueSubmitted(phoneNumber)
    }

    func countryCodeTableViewController(_ viewController: UIViewController!, didSelect country: Country!) {
        phoneInputView.selectCountry(country)
        viewController.dismiss(animated: true)
    }

}
