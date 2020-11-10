//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import Foundation
import UIKit
import WireSystem
import WireTransport

/**
 * The view controller to use to ask the user to enter their credentials.
 */

final class AuthenticationCredentialsViewController: AuthenticationStepController, CountryCodeTableViewControllerDelegate, EmailPasswordTextFieldDelegate, PhoneNumberInputViewDelegate, TabBarDelegate, TextFieldValidationDelegate, UITextFieldDelegate {

    /// Types of flow provided by the view controller.
    enum FlowType {
        case login(AuthenticationCredentialsType, AuthenticationPrefilledCredentials?)
        case registration(AuthenticationCredentialsType)
        case reauthentication(AuthenticationPrefilledCredentials?)
    }

    /// The type of flow presented by the view controller.
    private(set) var flowType: FlowType!

    /// The currently pre-filled credentials.
    var prefilledCredentials: AuthenticationPrefilledCredentials? {
        didSet {
            updatePrefilledCredentials()
        }
    }

    /// The type of credentials that the user is currently entering.
    var credentialsType: AuthenticationCredentialsType = .email {
        didSet {
            updateCredentialsType()
        }
    }

    /// Whether we are in the registration flow.
    var isRegistering: Bool {
        if case .registration? = flowType {
            return true
        } else {
            return false
        }
    }
    
    var isReauthenticating: Bool {
        if case .reauthentication? = flowType {
            return true
        } else {
            return false
        }
    }

    private var emailFieldValidationError: TextFieldValidator.ValidationError? = .tooShort(kind: .email)

    convenience init(flowType: FlowType) {
        switch flowType {
        case .login(let credentialsType, let credentials):
            let description = LogInStepDescription()
            self.init(description: description)
            self.credentialsType = credentials?.primaryCredentialsType ?? credentialsType
            self.prefilledCredentials = credentials
        case .reauthentication(let credentials):
            let description = ReauthenticateStepDescription(prefilledCredentials: credentials)
            self.init(description: description)
            self.credentialsType = credentials?.primaryCredentialsType ?? .email
            self.prefilledCredentials = credentials
        case .registration(let credentialsType):
            let description = PersonalRegistrationStepDescription()
            self.init(description: description)
            self.credentialsType = credentialsType
        }

        self.flowType = flowType
    }

    // MARK: - Views

    let contentStack = UIStackView()

    let emailPasswordInputField = EmailPasswordTextField()
    let emailInputField = AccessoryTextField(kind: .email)
    let phoneInputView = PhoneNumberInputView()

    let tabBar: TabBar = {
        let emailTab = UITabBarItem(title: "registration.register_by_email".localized(uppercased: true), image: nil, selectedImage: nil)
        emailTab.accessibilityIdentifier = "UseEmail"

        let passwordTab = UITabBarItem(title: "registration.register_by_phone".localized(uppercased: true), image: nil, selectedImage: nil)
        passwordTab.accessibilityIdentifier = "UsePhone"

        return TabBar(items: [emailTab, passwordTab], style: .light)
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        updateCredentialsType()
        updatePrefilledCredentials()
    }

    override var contentCenterXAnchor: NSLayoutYAxisAnchor {
        return tabBar.bottomAnchor
    }

    override func createMainView() -> UIView {
        contentStack.axis = .vertical
        contentStack.spacing = 24

        contentStack.addArrangedSubview(tabBar)
        contentStack.addArrangedSubview(emailInputField)
        contentStack.addArrangedSubview(emailPasswordInputField)
        contentStack.addArrangedSubview(phoneInputView)

        // Phone Number View
        phoneInputView.delegate = self
        phoneInputView.tintColor = .black
        phoneInputView.allowEditingPrefilledValue = !isReauthenticating

        // Email Password Input View
        emailPasswordInputField.allowEditingPrefilledValue = !isReauthenticating
        emailPasswordInputField.delegate = self

        // Email input view
        emailInputField.delegate = self
        emailInputField.textFieldValidationDelegate = self
        emailInputField.placeholder = "email.placeholder".localized(uppercased: true)
        emailInputField.addTarget(self, action: #selector(emailTextInputDidChange), for: .editingChanged)
        emailInputField.confirmButton.addTarget(self, action: #selector(emailConfirmButtonTapped), for: .touchUpInside)

        emailInputField.enableConfirmButton = { [weak self] in
            self?.emailFieldValidationError == nil
        }

        return contentStack
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    func configure(with featureProvider: AuthenticationFeatureProvider) {
        if case .reauthentication? = flowType {
            tabBar.isHidden = prefilledCredentials != nil
        } else if case .custom = BackendEnvironment.shared.environmentType.value {
            tabBar.isHidden = true
        } else {
            tabBar.isHidden = featureProvider.allowOnlyEmailLogin
        }
    }

    private var contextualFirstResponder: UIResponder? {
        switch flowType {
        case .login?:
            switch credentialsType {
            case .phone: return phoneInputView
            case .email: return emailPasswordInputField
            }
        case .registration?:
            switch credentialsType {
            case .phone: return phoneInputView
            case .email: return emailInputField
            }
        case .reauthentication?:
            switch credentialsType {
            case .phone: return phoneInputView
            case .email: return emailPasswordInputField
            }
        default:
            return nil
        }
    }

    override func showKeyboard() {
        contextualFirstResponder?.becomeFirstResponderIfPossible()
    }

    override func dismissKeyboard() {
        contextualFirstResponder?.resignFirstResponder()
    }

    // MARK: - Tab Bar

    func tabBar(_ tabBar: TabBar, didSelectItemAt index: Int) {
        switch index {
        case 0:
            credentialsType = .email
        case 1:
            credentialsType = .phone
        default:
            fatal("Unknown tab index: \(index)")
        }

        showKeyboard()
    }

    private func updateCredentialsType() {
        clearError()

        switch credentialsType {
        case .email:
            emailPasswordInputField.isHidden = isRegistering
            emailInputField.isHidden = !isRegistering
            phoneInputView.isHidden = true
            tabBar.setSelectedIndex(0, animated: false)
            setSecondaryViewHidden(false)

        case .phone:
            phoneInputView.isHidden = false
            emailPasswordInputField.isHidden = true
            emailInputField.isHidden = true
            tabBar.setSelectedIndex(1, animated: false)
            setSecondaryViewHidden(true)
        }
    }

    private func updatePrefilledCredentials() {
        guard let prefilledCredentials = self.prefilledCredentials else {
            return
        }

        switch prefilledCredentials.primaryCredentialsType {
        case .email:
            emailPasswordInputField.prefill(email: prefilledCredentials.credentials.emailAddress)
        case .phone:
            if let phoneNumber = prefilledCredentials.credentials.phoneNumber.flatMap(PhoneNumber.init(fullNumber:)) {
                phoneInputView.setPhoneNumber(phoneNumber)
            }
        }
    }

    override func clearInputFields() {
        phoneInputView.text = nil
        emailInputField.text = nil
        emailPasswordInputField.emailField.text = nil
        emailPasswordInputField.passwordField.text = nil
        showKeyboard()
    }

    // MARK: - Events

    override func accessibilityPerformMagicTap() -> Bool {
        return (contextualFirstResponder as? MagicTappable)?.performMagicTap() == true
    }

    @objc private func emailConfirmButtonTapped(sender: IconButton) {
        valueSubmitted(emailInputField.input)
    }

    @objc private func emailTextInputDidChange(sender: AccessoryTextField) {
        sender.validateInput()
    }

    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        emailFieldValidationError = error
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField == self.emailInputField, self.emailInputField.isInputValid else {
            return false
        }

        valueSubmitted(emailInputField.input)
        return true
    }

    // MARK: - Email / Password Input

    func textFieldDidUpdateText(_ textField: EmailPasswordTextField) {
        // no-op: we do not update the UI depending on the validity of the input
    }

    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String)) {
        valueSubmitted(credentials)
    }

    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField) {
        // no-op: we do not update the UI depending on the validity of the input
    }

    // MARK: - Phone Number Input

    func phoneNumberInputViewDidRequestCountryPicker(_ phoneNumberInput: PhoneNumberInputView) {
        let countryCodePicker = CountryCodeTableViewController()
        countryCodePicker.delegate = self
        countryCodePicker.modalPresentationStyle = .formSheet

        let navigationController = countryCodePicker.wrapInNavigationController(navigationBarClass: LightNavigationBar.self)
        present(navigationController, animated: true)
    }

    func phoneNumberInputView(_ inputView: PhoneNumberInputView, didPickPhoneNumber phoneNumber: PhoneNumber) {
        valueSubmitted(phoneNumber)
    }

    func phoneNumberInputView(_ inputView: PhoneNumberInputView, didValidatePhoneNumber phoneNumber: PhoneNumber, withResult validationError: TextFieldValidator.ValidationError?) {
        // no-op: handled by the input view directly
    }

    func countryCodeTableViewController(_ viewController: UIViewController, didSelect country: Country) {
        phoneInputView.selectCountry(country)
        viewController.dismiss(animated: true)
    }

}
