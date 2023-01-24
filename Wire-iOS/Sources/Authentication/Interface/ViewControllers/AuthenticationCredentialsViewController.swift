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
    typealias TabBarStrings = L10n.Accessibility.TabBar
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

    var backendEnvironmentProvider: (() -> BackendEnvironmentProvider)!

    var backendEnvironment: BackendEnvironmentProvider {
        return backendEnvironmentProvider()
    }

    var isProxyCredentialsRequired: Bool {
        backendEnvironment.proxy?.needsAuthentication == true
    }

    private var emailFieldValidationError: TextFieldValidator.ValidationError? = .tooShort(kind: .email)
    private var shouldUseScrollView = false
    private var loginActiveField: UIResponder? // used for login proxy case

    convenience init(flowType: FlowType, backendEnvironmentProvider: @escaping () -> BackendEnvironmentProvider = { BackendEnvironment.shared }) {
        switch flowType {
        case .login(let credentialsType, let credentials):
            let description = LogInStepDescription()
            self.init(description: description, contentCenterConstraintActivation: false)
            self.credentialsType = credentials?.primaryCredentialsType ?? credentialsType
            self.prefilledCredentials = credentials
            self.shouldUseScrollView = true
        case .reauthentication(let credentials):
            let description = ReauthenticateStepDescription(prefilledCredentials: credentials)
            self.init(description: description, contentCenterConstraintActivation: false)
            self.credentialsType = credentials?.primaryCredentialsType ?? .email
            self.prefilledCredentials = credentials
            self.shouldUseScrollView = true
        case .registration:
            let description = PersonalRegistrationStepDescription()
            self.init(description: description, contentCenterConstraintActivation: true)
            self.credentialsType = .email
            self.shouldUseScrollView = false
        }

        self.backendEnvironmentProvider = backendEnvironmentProvider
        self.flowType = flowType
    }

    // MARK: - Views

    let contentStack = UIStackView()

    let emailPasswordInputField = EmailPasswordTextField()
    let emailInputField = ValidatedTextField(kind: .email, style: .default)
    let phoneInputView = PhoneNumberInputView()
    let loginButton = Button(style: .accentColorTextButtonStyle,
                             cornerRadius: 16,
                             fontSpec: .buttonBigSemibold)

    lazy var proxyCredentialsViewController = {
        ProxyCredentialsViewController(backendURL: backendEnvironment.backendURL,
                                       textFieldDidUpdateText: { [weak self] _ in
            self?.updateLoginButtonState()
        },
                                       activeFieldChange: { [weak self] textField in
            self?.loginActiveField = textField
        })
    }()

    let tabBar: TabBar = {
        let emailTab = UITabBarItem(title: Registration.registerByEmail.capitalized,
                                    image: nil,
                                    selectedImage: nil)
        emailTab.accessibilityIdentifier = "UseEmail"
        emailTab.accessibilityLabel = TabBarStrings.Email.description

        let passwordTab = UITabBarItem(title: Registration.registerByPhone.capitalized,
                                       image: nil,
                                       selectedImage: nil)
        passwordTab.accessibilityIdentifier = "UsePhone"
        passwordTab.accessibilityLabel = TabBarStrings.Phone.description

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
        button.accessibilityLabel = L10n.Accessibility.Authentication.ForgotPasswordButton.description
        button.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)

        return button
    }()

    // MARK: - Lifecycle

    override func loadView() {
        if shouldUseScrollView {
            view = UIScrollView()
        } else {
            view = UIView()
        }
        // avoid constraint breaking on layout pass
        view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        updateCredentialsType()
        updatePrefilledCredentials()

        if case .login = flowType {
            updateViewsForProxy()
        }

        (view as? UIScrollView)?.keyboardDismissMode = .onDrag
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loginActiveField = contextualFirstResponder
    }

    override var contentCenterYAnchor: NSLayoutYAxisAnchor {
        return tabBar.bottomAnchor
    }

    private func setupProxyView() {
        let verticalSpacing: CGFloat = 24
        let horizontalMargin: CGFloat = 31

        let innerTopStackView = UIStackView()
        innerTopStackView.axis = .vertical
        innerTopStackView.spacing = verticalSpacing

        addCustomBackendViewIfNeeded(to: innerTopStackView, space: 66)

        innerTopStackView.addArrangedSubview(tabBar)
        innerTopStackView.addArrangedSubview(emailInputField)
        innerTopStackView.addArrangedSubview(emailPasswordInputField)
        innerTopStackView.addArrangedSubview(phoneInputView)
        innerTopStackView.addArrangedSubview(forgotPasswordButton)
        innerTopStackView.setCustomSpacing(40, after: forgotPasswordButton)

        let innerBottomStackView = UIStackView()
        innerBottomStackView.axis = .vertical
        innerBottomStackView.addArrangedSubview(loginButton)

        innerTopStackView.isLayoutMarginsRelativeArrangement = true
        innerTopStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: horizontalMargin, bottom: 0, trailing: horizontalMargin)

        innerBottomStackView.isLayoutMarginsRelativeArrangement = true
        innerBottomStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: isProxyCredentialsRequired ? 40 : 0, leading: horizontalMargin, bottom: 32, trailing: horizontalMargin)

        contentStack.addArrangedSubview(innerTopStackView)
        if isProxyCredentialsRequired {
            addProxyCredentialsSection()
        }
        contentStack.addArrangedSubview(innerBottomStackView)

        contentStack.setCustomSpacing(40, after: innerTopStackView)
    }

    private func setupDefaultView() {
        let horizontalMargin: CGFloat = 31
        let emptyView = UIView()
        contentStack.spacing = 24

        addCustomBackendViewIfNeeded(to: contentStack, space: 0)

        if stepDescription.subtext == nil && shouldUseScrollView {
            contentStack.addArrangedSubview(emptyView)
            contentStack.setCustomSpacing(56, after: emptyView)
        }
        contentStack.addArrangedSubview(tabBar)
        contentStack.addArrangedSubview(emailInputField)
        contentStack.addArrangedSubview(emailPasswordInputField)
        contentStack.addArrangedSubview(phoneInputView)
        contentStack.addArrangedSubview(forgotPasswordButton)
        contentStack.addArrangedSubview(loginButton)

        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0,
                                                                        leading: horizontalMargin,
                                                                        bottom: 0,
                                                                        trailing: horizontalMargin)
    }

    private func addCustomBackendViewIfNeeded(to uiStackView: UIStackView, space: CGFloat) {
        guard let infoView = customBackendInfo() else { return }
        uiStackView.addArrangedSubview(infoView)
        uiStackView.setCustomSpacing(space, after: infoView)
    }

    override func createMainView() -> UIView {
        contentStack.axis = .vertical
        contentStack.distribution = .fill

        // log in button
        loginButton.setTitle(L10n.Localizable.Landing.Login.Button.title.capitalized, for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        updateLoginButtonState()

        // Phone Number View
        phoneInputView.delegate = self
        phoneInputView.tintColor = .black
        phoneInputView.allowEditingPrefilledValue = !isReauthenticating

        // Email Password Input View
        emailPasswordInputField.allowEditingPrefilledValue = !isReauthenticating
        emailPasswordInputField.delegate = self
        emailPasswordInputField.passwordField.addRevealButton(delegate: self)

        // Email input view
        emailInputField.delegate = self
        emailInputField.textFieldValidationDelegate = self
        emailInputField.placeholder = L10n.Localizable.Email.placeholder.capitalized
        emailInputField.addTarget(self, action: #selector(emailTextInputDidChange), for: .editingChanged)
        emailInputField.confirmButton.addTarget(self, action: #selector(emailConfirmButtonTapped), for: .touchUpInside)
        emailInputField.enableConfirmButton = { [weak self] in
            self?.emailFieldValidationError == nil
        }

        if isProxyCredentialsRequired {
            setupProxyView()
        } else {
            setupDefaultView()
        }
        return contentStack
    }

    @objc
    func loginButtonTapped(sender: UIButton) {
        guard isProxyCredentialsRequired else {
            emailPasswordInputField.confirmButtonTapped()
            return
        }

        let input: (EmailPasswordInput, AuthenticationProxyCredentialsInput?) = (
            .init(email: emailPasswordInputField.emailField.input,
                  password: emailPasswordInputField.passwordField.input),
            .init(username: proxyCredentialsViewController.usernameInput.input,
                  password: proxyCredentialsViewController.passwordInput.input)
        )
        valueSubmitted(input)
    }

    @objc
    func forgotPasswordTapped(sender: UIButton) {
        actioner?.executeAction(.openURL(.wr_passwordReset))
    }

    override func createConstraints() {
        super.createConstraints()
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        if shouldUseScrollView {
            NSLayoutConstraint.activate([
                contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
                contentStack.trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor),
                contentStack.widthAnchor.constraint(equalToConstant: 375),
                contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                contentStack.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 86)
            ])
        }
    }

    override func updateKeyboard(with keyboardFrame: CGRect) {
        guard let scrollView = view as? UIScrollView else {
            return super.updateKeyboard(with: keyboardFrame)
        }

        guard let activeField = loginActiveField as? UIView else {
            scrollView.contentInset.bottom = 0
            scrollView.verticalScrollIndicatorInsets.bottom = 0
            return
        }
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0)
        scrollView.contentInset = contentInsets
        scrollView.verticalScrollIndicatorInsets = contentInsets

        let activeRect = activeField.convert(activeField.bounds, to: scrollView)
        scrollView.scrollRectToVisible(activeRect, animated: true)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    func updateViewsForProxy() {
        if case .custom = backendEnvironment.environmentType.value {
            tabBar.isHidden = true
        }
    }

    func configure(with featureProvider: AuthenticationFeatureProvider) {
        if isRegistering {
            // Only email registration is allowed.
            tabBar.isHidden = true
        } else if case .reauthentication? = flowType {
            tabBar.isHidden = prefilledCredentials != nil
        } else if case .custom = backendEnvironment.environmentType.value {
            tabBar.isHidden = true
        } else {
            tabBar.isHidden = featureProvider.allowOnlyEmailLogin
        }
    }

    @objc
    func customBackendInfoViewTapped(sender: UITapGestureRecognizer) {
        let intent = AuthenticationShowCustomBackendInfoHandler.Intent.showCustomBackendInfo
        authenticationCoordinator?.eventResponderChain.handleEvent(ofType: .userInput(intent))
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
        guard !isProxyCredentialsRequired else {
            proxyCredentialsViewController.usernameInput.becomeFirstResponder()
            return
        }
        let input: (EmailPasswordInput, AuthenticationProxyCredentialsInput?) = (EmailPasswordInput(email: credentials.0, password: credentials.1), nil)
        valueSubmitted(input)
    }

    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField) {
        guard !isProxyCredentialsRequired, !textField.isPasswordEmpty else {
            proxyCredentialsViewController.usernameInput.becomeFirstResponder()
            return
        }
        // no-op: we do not update the UI depending on the validity of the input
    }

    private func updateLoginButtonState() {
        guard isProxyCredentialsRequired else {
            loginButton.isEnabled = emailPasswordInputField.hasValidInput
            return
        }
        let validEmailPassword = emailPasswordInputField.emailValidationError == nil && emailPasswordInputField.passwordValidationError == nil
        let validProxyCredentials = proxyCredentialsViewController.usernameInput.isInputValid && proxyCredentialsViewController.passwordInput.isInputValid
        loginButton.isEnabled = validEmailPassword &&
        ((isProxyCredentialsRequired && validProxyCredentials) || !isProxyCredentialsRequired)
    }

    // MARK: - Proxy Credentials

    private func customBackendInfo() -> CustomBackendView? {
        guard let url = backendEnvironment.environmentType.customUrl else {
            return nil
        }
        let info = CustomBackendView()
        info.setBackendUrl(url)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(customBackendInfoViewTapped(sender:)))
        info.addGestureRecognizer(tapGesture)
        info.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return info
    }

    private func addProxyCredentialsSection() {
        guard proxyCredentialsViewController.parent == nil else { return }
        addChild(proxyCredentialsViewController)
        contentStack.addArrangedSubview(proxyCredentialsViewController.view)
        proxyCredentialsViewController.didMove(toParent: self)
    }

    func textFieldDidUpdateText(_ textField: ValidatedTextField) {
        updateLoginButtonState()
    }

    func textField(_ textField: UITextField, editing: Bool) {
        loginActiveField = editing ? textField : nil
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

extension AuthenticationCredentialsViewController: ValidatedTextFieldDelegate {
    func buttonPressed(_ sender: UIButton) {
        emailPasswordInputField.passwordField.isSecureTextEntry.toggle()
        emailPasswordInputField.passwordField.updatePasscodeIcon()
    }
}

extension ValidatedTextField {
    func addRevealButton(delegate: ValidatedTextFieldDelegate) {
        showConfirmButton = true
        validatedTextFieldDelegate = delegate
        overrideButtonIcon = StyleKitIcon.AppLock.reveal
    }
}
