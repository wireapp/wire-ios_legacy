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
import WireCommonComponents

/**
 * The view controller to use to ask the user to enter their credentials.
 */

final class AuthenticationCredentialsViewController: AuthenticationStepController,
                                                     CountryCodeTableViewControllerDelegate,
                                                     EmailPasswordTextFieldDelegate,
                                                     PhoneNumberInputViewDelegate,
                                                     TabBarDelegate,
                                                     TextFieldValidationDelegate,
                                                     UITextFieldDelegate {

    typealias Registration = L10n.Localizable.Registration
    weak var actioner: AuthenticationActioner?

    /// Types of flow provided by the view controller.
    enum FlowType {
        case login(AuthenticationCredentialsType, AuthenticationPrefilledCredentials?)
        case registration
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

    weak override var authenticationCoordinator: AuthenticationCoordinator? {
        didSet {
            actioner = authenticationCoordinator
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
        case .registration:
            let description = PersonalRegistrationStepDescription()
            self.init(description: description)
            self.credentialsType = .email
        }

        self.flowType = flowType
    }

    // MARK: - Views

    let contentStack = UIStackView()

    let emailPasswordInputField = EmailPasswordTextField()
    let emailInputField = ValidatedTextField(kind: .email, style: .default)
    let phoneInputView = PhoneNumberInputView()
    let loginButton = Button(style: .accentColorTextButtonStyle,
                             cornerRadius: 16,
                             fontSpec: .normalSemiboldFont)

    let tabBar: TabBar = {
        let emailTab = UITabBarItem(title: Registration.registerByEmail.capitalized,
                                    image: nil,
                                    selectedImage: nil)
        emailTab.accessibilityIdentifier = "UseEmail"

        let passwordTab = UITabBarItem(title: Registration.registerByPhone.capitalized,
                                       image: nil,
                                       selectedImage: nil)
        passwordTab.accessibilityIdentifier = "UsePhone"

        return TabBar(items: [emailTab, passwordTab])
    }()

    lazy var forgotPasswordButton: Button = {
        let button = Button(fontSpec: .smallLightFont)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: FontSpec.smallSemiboldFont.font!,
            .foregroundColor: SemanticColors.Button.textUnderlineEnabled,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let attributeString = NSMutableAttributedString(
            string: L10n.Localizable.Signin.forgotPassword.capitalized,
            attributes: attributes
        )

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(attributeString, for: .normal)
        button.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)

        return button
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
        contentStack.addArrangedSubview(forgotPasswordButton)
        contentStack.addArrangedSubview(loginButton)

        // log in button
        loginButton.setTitle(L10n.Localizable.Landing.Login.Button.title.capitalized, for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        updateLoginButtonState()
        createConstraints()

        // Phone Number View
        phoneInputView.delegate = self
        phoneInputView.tintColor = .black
        phoneInputView.allowEditingPrefilledValue = !isReauthenticating

        // Email Password Input View
        emailPasswordInputField.allowEditingPrefilledValue = !isReauthenticating
        emailPasswordInputField.passwordField.showConfirmButton = false
        emailPasswordInputField.delegate = self

        // Email input view
        emailInputField.delegate = self
        emailInputField.textFieldValidationDelegate = self
        emailInputField.placeholder = L10n.Localizable.Email.placeholder.capitalized
        emailInputField.addTarget(self, action: #selector(emailTextInputDidChange), for: .editingChanged)
        emailInputField.confirmButton.addTarget(self, action: #selector(emailConfirmButtonTapped), for: .touchUpInside)

        emailInputField.enableConfirmButton = { [weak self] in
            self?.emailFieldValidationError == nil
        }

        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 31, bottom: 0, trailing: 31)

        if isRegistering {
            contentStack.isLayoutMarginsRelativeArrangement = true
            contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 31, bottom: 0, trailing: 31)
        }
        return contentStack
    }

    func createConstraints() {
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc
    func loginButtonTapped(sender: UIButton) {
        emailPasswordInputField.confirmButtonTapped()
    }

    @objc
    func forgotPasswordTapped(sender: UIButton) {
        actioner?.executeAction(.openURL(.wr_passwordReset))
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    func configure(with featureProvider: AuthenticationFeatureProvider) {
        if isRegistering {
            // Only email registration is allowed.
            tabBar.isHidden = true
        } else if case .reauthentication? = flowType {
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
            return emailInputField
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
            loginButton.isHidden = isRegistering
            forgotPasswordButton.isHidden = isRegistering
            phoneInputView.isHidden = true
            tabBar.setSelectedIndex(0, animated: false)
            setSecondaryViewHidden(false)

        case .phone:
            phoneInputView.isHidden = false
            loginButton.isHidden = true
            forgotPasswordButton.isHidden = true
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

    @objc private func emailTextInputDidChange(sender: ValidatedTextField) {
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
        updateLoginButtonState()
    }

    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String)) {
        valueSubmitted(credentials)
    }

    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField) {

    }

    private func updateLoginButtonState() {
        loginButton.isEnabled = emailPasswordInputField.hasValidInput
    }

    // MARK: - Phone Number Input

    func phoneNumberInputViewDidRequestCountryPicker(_ phoneNumberInput: PhoneNumberInputView) {
        let countryCodePicker = CountryCodeTableViewController()
        countryCodePicker.delegate = self
        countryCodePicker.modalPresentationStyle = .formSheet

        let navigationController = countryCodePicker.wrapInNavigationController(navigationBarClass: DefaultNavigationBar.self, setBackgroundColor: true)
        present(navigationController, animated: true)
    }

    func phoneNumberInputView(_ inputView: PhoneNumberInputView, didPickPhoneNumber phoneNumber: PhoneNumber) {
        valueSubmitted(phoneNumber)
    }

    func phoneNumberInputView(_ inputView: PhoneNumberInputView, didValidatePhoneNumber phoneNumber: PhoneNumber, withResult validationError: TextFieldValidator.ValidationError?) {
        phoneInputView.loginButton.isEnabled = validationError == nil
    }

    func countryCodeTableViewController(_ viewController: UIViewController, didSelect country: Country) {
        phoneInputView.selectCountry(country)
        viewController.dismiss(animated: true)
    }

}
