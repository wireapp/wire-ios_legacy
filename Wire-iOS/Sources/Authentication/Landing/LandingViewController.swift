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

protocol LandingViewControllerDelegate {
    func landingViewControllerDidChooseCreateAccount()
    func landingViewControllerDidChooseCreateTeam()
    func landingViewControllerDidChooseLogin()
    func landingViewControllerDidChooseEnterpriseLogin()
    func landingViewControllerDidChooseSSOLogin()
}

/// Landing screen for choosing how to authenticate.
final class LandingViewController: AuthenticationStepViewController {

    // MARK: - State

    weak var authenticationCoordinator: AuthenticationCoordinator?

    var delegate: LandingViewControllerDelegate? {
        return authenticationCoordinator
    }

    // MARK: - UI Styles

    static let semiboldFont = FontSpec(.large, .semibold).font!

    static let buttonTitleAttribute: [NSAttributedString.Key: AnyObject] = {
        let alignCenterStyle = NSMutableParagraphStyle()
        alignCenterStyle.alignment = .center

        return [.foregroundColor: UIColor.Team.textColor, .paragraphStyle: alignCenterStyle, .font: semiboldFont]
    }()

    static let buttonSubtitleAttribute: [NSAttributedString.Key: AnyObject] = {
        let alignCenterStyle = NSMutableParagraphStyle()
        alignCenterStyle.alignment = .center
        alignCenterStyle.paragraphSpacingBefore = 4
        alignCenterStyle.lineSpacing = 4

        let lightFont = FontSpec(.normal, .light).font!

        return [.foregroundColor: UIColor.Team.textColor, .paragraphStyle: alignCenterStyle, .font: lightFont]
    }()

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
        imageView.tintColor = UIColor.Team.textColor
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return imageView
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel(key: "landing.welcome_message".localized,
                            size: .normal,
                            weight: .bold,
                            color: .landingScreen,
                            variant: .light)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return label
    }()
    
    private let subMessageLabel: UILabel = {
        let label = UILabel(key: "landing.welcome_submessage".localized,
                            size: .normal,
                            weight: .regular,
                            color: .landingScreen,
                            variant: .light)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return label
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        return stackView
    }()
    
    private let loginButton: Button = {
        let button = Button(style: .full, variant: .light)
        button.accessibilityIdentifier = "Login"
        button.setTitle("landing.login.button.title".localized, for: .normal)
        button.addTarget(self,
                         action: #selector(loginButtonTapped(_:)),
                         for: .touchUpInside)
        
        return button
    }()
    
    private let enterpriseLoginButton: Button = {
        let button = Button(style: .empty,
                            variant: .light,
                            titleLabelFont: .smallSemiboldFont)
        button.accessibilityIdentifier = "Enterprise Login"
        button.setTitle("landing.login.enterprise.button.title".localized, for: .normal)
        button.addTarget(self,
                         action: #selector(enterpriseLoginButtonTapped(_:)),
                         for: .touchUpInside)
        
        return button
    }()
    
    private let loginWithEmailButton: Button = {
        let button = Button(style: .full, variant: .light)
        button.accessibilityIdentifier = "Login with email"
        button.setTitle("landing.login.email.button.title".localized, for: .normal)
        button.addTarget(self,
                         action: #selector(loginButtonTapped(_:)),
                         for: .touchUpInside)
        
        return button
    }()
    
    private let loginWithSSOButton: Button = {
        let button = Button(style: .empty, variant: .light)
        button.accessibilityIdentifier = "Log in with SSO"
        button.setTitle("landing.login.sso.button.title".localized, for: .normal)
        button.addTarget(self,
                         action: #selector(ssoLoginButtonTapped(_:)),
                         for: .touchUpInside)
        
        return button
    }()

    private let createAccoutInfoLabel: UILabel = {
        let label = UILabel(key: "landing.create_account.infotitle".localized,
                            size: .small,
                            weight: .regular,
                            color: .landingScreen,
                            variant: .light)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return label
    }()
    
    private let createAccountButton: Button = {
        let button = Button(style: .empty,
                            variant: .light,
                            titleLabelFont: .smallSemiboldFont)
        button.setBorderColor(UIColor(white: 1.0, alpha: 0.0), for: .normal)
        button.setBorderColor(UIColor(white: 1.0, alpha: 0.0), for: .highlighted)
        button.accessibilityIdentifier = "Create An Account"
        button.setTitle("landing.create_account.title".localized, for: .normal)
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
    
    private let customBackendTitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "ConfigurationTitle"
        label.textAlignment = .center
        label.font = FontSpec(.normal, .bold).font!
        label.textColor = UIColor.Team.textColor
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private let customBackendSubtitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "ConfigurationLink"
        label.font = FontSpec(.small, .semibold).font!
        label.textColor = UIColor.Team.placeholderColor
        return label
    }()
    
    private let customBackendSubtitleButton: UIButton = {
        let button = UIButton()
        button.setTitle("landing.custom_backend.more_info.button.title".localized.uppercased(), for: .normal)
        button.accessibilityIdentifier = "ShowMoreButton"
        button.setTitleColor(UIColor.Team.activeButton, for: .normal)
        button.titleLabel?.font = FontSpec(.small, .semibold).font!
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self,
                         action: #selector(showCustomBackendLink(_:)),
                         for: .touchUpInside)
        return button
    }()
    
    private let customBackendSubtitleStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        return stackView
    }()
    
    private let customBackendStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return stackView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        Analytics.shared().tagOpenedLandingScreen(context: "email")
        self.view.backgroundColor = UIColor.Team.background

        configureSubviews()
        
        traitCollection.horizontalSizeClass == .compact
            ? ()
            : configureRegularSizeClassFont()
        
        traitCollection.horizontalSizeClass == .compact
            ? createCompactSizeClassConstraints()
            : createRegularSizeClassConstraints()
        
        configureAccessibilityElements()

        updateBarButtonItem()
        disableTrackingIfNeeded()
        updateButtons()
        updateCustomBackendLabels()

        NotificationCenter.default.addObserver(forName: AccountManagerDidUpdateAccountsNotificationName,
                                               object: SessionManager.shared?.accountManager,
                                               queue: .main) { _ in
                self.updateBarButtonItem()
                self.disableTrackingIfNeeded()
        }
        
        NotificationCenter.default.addObserver(forName: BackendEnvironment.backendSwitchNotification,
                                               object: nil,
                                               queue: .main) { _ in
            self.updateCustomBackendLabels()
            self.updateButtons()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: logoView)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .compatibleDarkContent
    }

    func configure(with featureProvider: AuthenticationFeatureProvider) {
        enterpriseLoginButton.isHidden = !featureProvider.allowDirectCompanyLogin
    }
    
    private func configureSubviews() {
        if #available(iOS 11, *) {
            additionalSafeAreaInsets.top = -44
        }

        topStack.addArrangedSubview(logoView)
        
        if SecurityFlags.customBackend.isEnabled {
            customBackendSubtitleStack.addArrangedSubview(customBackendSubtitleLabel)
            customBackendSubtitleStack.addArrangedSubview(customBackendSubtitleButton)

            customBackendStack.addArrangedSubview(customBackendTitleLabel)
            customBackendStack.addArrangedSubview(customBackendSubtitleStack)
            topStack.addArrangedSubview(customBackendStack)
        }

        view.addSubview(topStack)

        contentView.addSubview(messageLabel)
        contentView.addSubview(subMessageLabel)
        buttonStackView.addArrangedSubview(loginButton)
        buttonStackView.addArrangedSubview(enterpriseLoginButton)
        buttonStackView.addArrangedSubview(loginWithEmailButton)
        buttonStackView.addArrangedSubview(loginWithSSOButton)
        contentView.addSubview(buttonStackView)

        view.addSubview(createAccoutInfoLabel)
        view.addSubview(createAccountButton)
        view.addSubview(contentView)
    }

    private func disableAutoresizingMaskTranslationViews() {
        disableAutoresizingMaskTranslation(for: [
            topStack,
            contentView,
            buttonStackView,
            createAccountButton,
            messageLabel,
            subMessageLabel,
            createAccoutInfoLabel
        ])
    }
    
    private func createCompactSizeClassConstraints() {
        disableAutoresizingMaskTranslationViews()
        
        NSLayoutConstraint.activate([
            // top stack view
            topStack.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 42),
            topStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // logoView
            logoView.heightAnchor.constraint(lessThanOrEqualToConstant: 31),
            
            // content view,
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // message label
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: subMessageLabel.topAnchor, constant: -16),
            
            // submessage label
            
            subMessageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            subMessageLabel.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -48),
            
            // buttons stack view
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            enterpriseLoginButton.heightAnchor.constraint(equalToConstant: 48),
            loginButton.heightAnchor.constraint(equalToConstant: 48),
            loginWithEmailButton.heightAnchor.constraint(equalToConstant: 48),
            loginWithSSOButton.heightAnchor.constraint(equalToConstant: 48),
            
            // create an label
            createAccoutInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createAccoutInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createAccoutInfoLabel.bottomAnchor.constraint(equalTo: createAccountButton.topAnchor),
            
            // create an button
            createAccountButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createAccountButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createAccountButton.heightAnchor.constraint(equalToConstant: 24),
            createAccountButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -35),
        ])
    }
    
    private func createRegularSizeClassConstraints() {
        disableAutoresizingMaskTranslationViews()
        
        NSLayoutConstraint.activate([
            // top stack view
            topStack.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 200),
            topStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // logoView
            logoView.heightAnchor.constraint(lessThanOrEqualToConstant: 31),
            
            // content view,
            contentView.widthAnchor.constraint(equalToConstant: 375),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // message label
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -72),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 72),
            messageLabel.bottomAnchor.constraint(equalTo: subMessageLabel.topAnchor, constant: -16),
            
            // submessage label
            
            subMessageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -24),
            subMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 24),
            subMessageLabel.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -48),
            
            // buttons stack view
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            enterpriseLoginButton.heightAnchor.constraint(equalToConstant: 48),
            loginButton.heightAnchor.constraint(equalToConstant: 48),
            loginWithEmailButton.heightAnchor.constraint(equalToConstant: 48),
            loginWithSSOButton.heightAnchor.constraint(equalToConstant: 48),
            
            // create an label
            createAccoutInfoLabel.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 98),
            createAccoutInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createAccoutInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createAccoutInfoLabel.bottomAnchor.constraint(equalTo: createAccountButton.topAnchor),
            
            // create an button
            createAccountButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createAccountButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createAccountButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
    
    private func configureRegularSizeClassFont() {
        messageLabel.font = UIFont.boldSystemFont(ofSize: 24)
        subMessageLabel.font = FontSpec(.normal, .regular).font
        createAccoutInfoLabel.font = UIFont.systemFont(ofSize: 14)
        createAccountButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    }
    
    private func disableAutoresizingMaskTranslation(for views: [UIView]) {
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    // MARK: - Adaptivity Events
    
    private func updateLogoView() {
        logoView.isHidden = isCustomBackend
    }
    
    var isCustomBackend: Bool {
        switch BackendEnvironment.shared.environmentType.value {
        case .production, .staging, .qaDemo, .qaDemo2:
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

        updateLogoView()
    }
    
    private func updateBarButtonItem() {
        if SessionManager.shared?.firstAuthenticatedAccount == nil {
            navigationItem.rightBarButtonItem = nil
        } else {
            let cancelItem = UIBarButtonItem(icon: .cross, target: self, action: #selector(cancelButtonTapped))
            cancelItem.accessibilityIdentifier = "CancelButton"
            cancelItem.accessibilityLabel = "general.cancel".localized
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
        switch BackendEnvironment.shared.environmentType.value {
        case .production, .staging, .qaDemo, .qaDemo2:
            customBackendStack.isHidden = true
            messageLabel.text = "landing.welcome_message".localized
            subMessageLabel.text = "landing.welcome_submessage".localized
        case .custom(url: let url):
            messageLabel.text = "landing.welcome_message".localized
            subMessageLabel.text = "landing.welcome_submessage".localized
            customBackendTitleLabel.text = "landing.custom_backend.title".localized(args: BackendEnvironment.shared.title)
            customBackendSubtitleLabel.text = url.absoluteString.uppercased()
            customBackendStack.isHidden = false
        }
        updateLogoView()
    }
    
    private func updateButtons() {
        enterpriseLoginButton.isHidden = isCustomBackend
        loginButton.isHidden = isCustomBackend
        createAccountButton.isHidden = isCustomBackend
        loginWithSSOButton.isHidden = !isCustomBackend
        loginWithEmailButton.isHidden = !isCustomBackend
    }
    
    private func disableTrackingIfNeeded() {
        if SessionManager.shared?.firstAuthenticatedAccount == nil {
            TrackingManager.shared.disableCrashAndAnalyticsSharing = true
        }
    }

    // MARK: - Accessibility

    private func configureAccessibilityElements() {
        logoView.isAccessibilityElement = true
        logoView.accessibilityLabel = "landing.header".localized
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
    func showCustomBackendLink(_ sender: AnyObject!) {
        let backendTitle = BackendEnvironment.shared.title
        let jsonURL = customBackendSubtitleLabel.text?.lowercased() ?? ""
        let alert = UIAlertController(title: "landing.custom_backend.more_info.alert.title".localized(args: backendTitle), message: "\(jsonURL)", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "general.ok".localized, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc func createAccountButtonTapped(_ sender: AnyObject!) {
        Analytics.shared().tagOpenedUserRegistration(context: "email")
        delegate?.landingViewControllerDidChooseCreateAccount()
    }

    @objc func createTeamButtonTapped(_ sender: AnyObject!) {
        Analytics.shared().tagOpenedTeamCreation(context: "email")
        delegate?.landingViewControllerDidChooseCreateTeam()
    }

    @objc func loginButtonTapped(_ sender: AnyObject!) {
        Analytics.shared().tagOpenedLogin(context: "email")
        delegate?.landingViewControllerDidChooseLogin()
    }
    
    @objc func enterpriseLoginButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseEnterpriseLogin()
    }
    
    @objc func ssoLoginButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseSSOLogin()
    }
    
    @objc func cancelButtonTapped() {
        guard let account = SessionManager.shared?.firstAuthenticatedAccount else { return }
        SessionManager.shared!.select(account)
    }


    // MARK: - AuthenticationCoordinatedViewController
    
    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        //no-op
    }
    
    func displayError(_ error: Error) {
        //no-op
    }
}
