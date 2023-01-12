//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSystem
import WireTransport
import WireSyncEngine
import WireCommonComponents

protocol LandingViewControllerDelegate {
    func landingViewControllerDidChooseCreateAccount()
    func landingViewControllerDidChooseLogin()
    func landingViewControllerDidChooseEnterpriseLogin()
    func landingViewControllerDidChooseSSOLogin() // to remove ?
    func landingViewControllerDidChooseInfoBackend()
}

/// Landing screen for choosing how to authenticate.
final class LandingViewController: AuthenticationStepViewController {

    var backendEnvironmentProvider: () -> BackendEnvironmentProvider

    var backendEnvironment: BackendEnvironmentProvider {
        return backendEnvironmentProvider()
    }

    init(backendEnvironmentProvider: @escaping () -> BackendEnvironmentProvider = { BackendEnvironment.shared }) {
        self.backendEnvironmentProvider = backendEnvironmentProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - State

    weak var authenticationCoordinator: AuthenticationCoordinator?

    typealias Landing = L10n.Localizable.Landing

    var delegate: LandingViewControllerDelegate? {
        return authenticationCoordinator
    }

    // MARK: - UI Elements

    private let contentView = UIView()

    private let topStack: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.axis = .vertical

        return stackView
    }()

    private let logoView: UIImageView = {
        let image = UIImage(named: "wire-logo-black")
        let imageView = UIImageView(image: image)
        imageView.accessibilityIdentifier = "WireLogo"
        imageView.contentMode = .scaleAspectFit

        imageView.tintColor = SemanticColors.Icon.foregroundDefault
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return imageView
    }()

    private let messageLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(text: Landing.welcomeMessage,
                                     fontSpec: .bodyTwoSemibold,
                                     color: SemanticColors.Label.textDefault)

        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        return label
    }()

    private let subMessageLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(text: Landing.welcomeSubmessage,
                                     fontSpec: .mediumRegularFont,
                                     color: SemanticColors.Label.textDefault)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        return label
    }()

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        return stackView
    }()

    private lazy var loginButton: Button = {
        let button = Button(style: .primaryTextButtonStyle,
                            cornerRadius: 16,
                            fontSpec: .buttonBigSemibold)
        button.accessibilityIdentifier = "Login"
        button.setTitle(Landing.Login.Button.title, for: .normal)
        button.addTarget(self,
                         action: #selector(loginButtonTapped(_:)),
                         for: .touchUpInside)

        return button
    }()

    private lazy var enterpriseLoginButton: Button = {
        let button = Button(style: .secondaryTextButtonStyle,
                            cornerRadius: 16,
                            fontSpec: .buttonBigSemibold)
        button.accessibilityIdentifier = "Enterprise Login"
        button.setTitle(Landing.Login.Enterprise.Button.title, for: .normal)
        button.addTarget(self,
                         action: #selector(enterpriseLoginButtonTapped(_:)),
                         for: .touchUpInside)

        return button
    }()

    private lazy var loginWithEmailButton: Button = {
        let button = Button(style: .primaryTextButtonStyle,
                            cornerRadius: 16,
                            fontSpec: .buttonBigSemibold)
        button.accessibilityIdentifier = "Login with email"
        button.setTitle(Landing.Login.Email.Button.title, for: .normal)
        button.addTarget(self,
                         action: #selector(loginButtonTapped(_:)),
                         for: .touchUpInside)

        return button
    }()

    private let createAccountInfoLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(text: Landing.CreateAccount.infotitle,
                                     fontSpec: .mediumRegularFont,
                                     color: SemanticColors.Label.textDefault)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        return label
    }()

    private lazy var createAccountButton: Button = {
        let button = Button(style: .secondaryTextButtonStyle,
                            cornerRadius: 12,
                            fontSpec: .buttonSmallBold)
        button.accessibilityIdentifier = "Create An Account"
        button.setTitle(Landing.CreateAccount.title, for: .normal)
        button.addTarget(self,
                         action: #selector(createAccountButtonTapped(_:)),
                         for: .touchUpInside)

        return button
    }()

    private let loginButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.axis = .vertical
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        return stackView
    }()

    lazy var customBackendView: CustomBackendView = {
        let view = CustomBackendView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(customBackendInfoViewTapped(_:)))
        view.addGestureRecognizer(tap)
        view.accessibilityIdentifier = "Custom backend information"
        return view
    }()

    @objc
    func customBackendInfoViewTapped(_: UIGestureRecognizer) {
        delegate?.landingViewControllerDidChooseInfoBackend()
    }

    // MARK: - Constraints

    var topStackTopConstraint = NSLayoutConstraint()
    var topStackTopConstraintConstant: CGFloat {
        return traitCollection.horizontalSizeClass == .compact ? 42.0 : 200.0
    }
    var contentViewWidthConstraint = NSLayoutConstraint()
    var contentViewLeadingConstraint = NSLayoutConstraint()
    var contentViewTrailingConstraint = NSLayoutConstraint()

    var messageLabelLeadingConstraint = NSLayoutConstraint()
    var messageLabelTrailingConstraint = NSLayoutConstraint()
    var messageLabelLabelConstraintsConstant: CGFloat {
        return traitCollection.horizontalSizeClass == .compact ? 0.0 : 72.0
    }

    var subMessageLabelLeadingConstraint = NSLayoutConstraint()
    var subMessageLabelTrailingConstraint = NSLayoutConstraint()
    var subMessageLabelConstraintsConstant: CGFloat {
        return traitCollection.horizontalSizeClass == .compact ? 0.0 : 24.0
    }

    var createAccountInfoLabelTopConstraint = NSLayoutConstraint()
    var createAccountButtomBottomConstraint = NSLayoutConstraint()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SemanticColors.View.backgroundDefault

        configureSubviews()
        configureConstraints()

        configureAccessibilityElements()

        updateBarButtonItem()
        disableTrackingIfNeeded()
        updateCustomBackendLabels()

        NotificationCenter.default.addObserver(forName: AccountManagerDidUpdateAccountsNotificationName,
                                               object: SessionManager.shared?.accountManager,
                                               queue: .main) { _ in
            self.updateBarButtonItem()
            self.disableTrackingIfNeeded()
        }

        NotificationCenter.default.addObserver(forName: BackendEnvironment.backendSwitchNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            self?.updateCustomBackendLabels()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: logoView)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        activateRightConstraint()
        setConstraintsConstants()
    }

    func configure(with featureProvider: AuthenticationFeatureProvider) {
        enterpriseLoginButton.isHidden = !featureProvider.allowDirectCompanyLogin
    }

    private func configureSubviews() {
        additionalSafeAreaInsets.top = -44

        topStack.addArrangedSubview(logoView)

        view.addSubview(topStack)

        contentView.addSubview(messageLabel)
        contentView.addSubview(subMessageLabel)

        buttonStackView.addArrangedSubview(customBackendView)
        buttonStackView.addArrangedSubview(loginButton)
        buttonStackView.addArrangedSubview(enterpriseLoginButton)
        contentView.addSubview(buttonStackView)

        view.addSubview(createAccountInfoLabel)
        view.addSubview(createAccountButton)
        view.addSubview(contentView)
    }

    private func configureConstraints() {
        disableAutoresizingMaskTranslationViews()
        createAndAddConstraints()
        activateRightConstraint()
    }

    private func activateRightConstraint() {
        [contentViewLeadingConstraint,
         contentViewTrailingConstraint,
         createAccountButtomBottomConstraint].forEach {
            $0.isActive = traitCollection.horizontalSizeClass == .compact
        }

        [contentViewWidthConstraint,
         createAccountInfoLabelTopConstraint].forEach {
            $0.isActive = traitCollection.horizontalSizeClass != .compact
        }
    }

    private func setConstraintsConstants() {
        topStackTopConstraint.constant = topStackTopConstraintConstant
        messageLabelLeadingConstraint.constant = -messageLabelLabelConstraintsConstant
        messageLabelTrailingConstraint.constant = messageLabelLabelConstraintsConstant
        subMessageLabelLeadingConstraint.constant = -subMessageLabelConstraintsConstant
        subMessageLabelTrailingConstraint.constant = subMessageLabelConstraintsConstant
    }

    private func disableAutoresizingMaskTranslationViews() {
        [
            topStack,
            contentView,
            buttonStackView,
            createAccountButton,
            messageLabel,
            subMessageLabel,
            createAccountInfoLabel
        ].prepareForLayout()
    }

    private func createAndAddConstraints() {

        topStackTopConstraint = topStack.topAnchor.constraint(equalTo: view.safeTopAnchor,
                                                              constant: topStackTopConstraintConstant)

        contentViewWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: 375)
        contentViewLeadingConstraint = contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                                            constant: 24)
        contentViewTrailingConstraint = contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                                              constant: -24)

        messageLabelLeadingConstraint = messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                                              constant: -messageLabelLabelConstraintsConstant)
        messageLabelTrailingConstraint = messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                                                constant: messageLabelLabelConstraintsConstant)

        subMessageLabelLeadingConstraint = subMessageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                                                    constant: -subMessageLabelConstraintsConstant)
        subMessageLabelTrailingConstraint = subMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                                                      constant: subMessageLabelConstraintsConstant)

        createAccountInfoLabelTopConstraint = createAccountInfoLabel.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor,
                                                                                        constant: 98)

        createAccountButtomBottomConstraint = createAccountButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor,
                                                                                         constant: -35)

        NSLayoutConstraint.activate([
            // top stack view
            topStackTopConstraint,
            topStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // logoView
            logoView.heightAnchor.constraint(lessThanOrEqualToConstant: 31),

            // content view,
            contentViewWidthConstraint,
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentViewLeadingConstraint,
            contentViewTrailingConstraint,

            // message label
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageLabelLeadingConstraint,
            messageLabelTrailingConstraint,
            messageLabel.bottomAnchor.constraint(equalTo: subMessageLabel.topAnchor, constant: -16),

            // submessage label

            subMessageLabelLeadingConstraint,
            subMessageLabelTrailingConstraint,
            subMessageLabel.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -32),

            // buttons stack view
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            enterpriseLoginButton.heightAnchor.constraint(equalToConstant: 48),
            loginButton.heightAnchor.constraint(equalToConstant: 48),

            // create an label
            createAccountInfoLabelTopConstraint, // iPad
            createAccountInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            createAccountInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            createAccountInfoLabel.bottomAnchor.constraint(equalTo: createAccountButton.topAnchor, constant: -8),

            // create an button
            createAccountButton.leadingAnchor.constraint(equalTo: buttonStackView.leadingAnchor),
            createAccountButton.trailingAnchor.constraint(equalTo: buttonStackView.trailingAnchor),
            createAccountButton.heightAnchor.constraint(equalToConstant: 32),
            createAccountButtomBottomConstraint // iPhone
        ])
    }

    // MARK: - Adaptivity Events

    var isCustomBackend: Bool {
        switch backendEnvironment.environmentType.value {
        case .production, .staging, .qaDemo, .qaDemo2, .anta, .bella, .chala:
            return false
        case .custom:
            return true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isIPadRegular() || isCustomBackend {
            topStack.spacing = 32
        } else if view.frame.height <= 640 {
            topStack.spacing = view.frame.height / 8
        } else {
            topStack.spacing = view.frame.height / 6
        }
    }

    private func updateBarButtonItem() {
        if SessionManager.shared?.firstAuthenticatedAccount == nil {
            navigationItem.rightBarButtonItem = nil
        } else {
            let cancelItem = UIBarButtonItem(icon: .cross, target: self, action: #selector(cancelButtonTapped))
            cancelItem.accessibilityIdentifier = "CancelButton"
            cancelItem.accessibilityLabel = L10n.Localizable.General.cancel
            navigationItem.rightBarButtonItem = cancelItem
        }
    }

    private var productName: String {
        guard let name = Bundle.appMainBundle.infoForKey("CFBundleDisplayName") else {
            fatal("unable to access CFBundleDisplayName")
        }
        return name
    }

    private func updateCustomBackendLabels() {
        messageLabel.text = Landing.welcomeMessage
        subMessageLabel.text = Landing.welcomeSubmessage

        switch backendEnvironment.environmentType.value {
        case .custom(let url):
            guard SecurityFlags.customBackend.isEnabled else {
                return
            }
            customBackendView.isHidden = false
            customBackendView.setBackendUrl(url)
        default:
            customBackendView.isHidden = true
        }
    }

    private func disableTrackingIfNeeded() {
        if SessionManager.shared?.firstAuthenticatedAccount == nil {
            TrackingManager.shared.disableCrashSharing = true
            TrackingManager.shared.disableAnalyticsSharing = true
        }
    }

    // MARK: - Accessibility

    private func configureAccessibilityElements() {
        logoView.isAccessibilityElement = true
        logoView.accessibilityLabel = Landing.header
        logoView.accessibilityTraits.insert(.header)
    }

    override func accessibilityPerformEscape() -> Bool {
        guard SessionManager.shared?.firstAuthenticatedAccount != nil else {
            return false
        }

        cancelButtonTapped()
        return true
    }

    // MARK: - Button tapped target

    @objc
    private func createAccountButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseCreateAccount()
    }

    @objc
    private func loginButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseLogin()
    }

    @objc
    private func enterpriseLoginButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseEnterpriseLogin()
    }

    @objc
    private func cancelButtonTapped() {
        guard let account = SessionManager.shared?.firstAuthenticatedAccount else { return }
        SessionManager.shared!.select(account)
    }

    // MARK: - AuthenticationCoordinatedViewController

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        // no-op
    }

    func displayError(_ error: Error) {
        // no-op
    }
}
