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

    static let headlineFont = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.light)
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

    let contentView = UIView()

    let topStack: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.axis = .vertical

        return stackView
    }()

    let logoView: UIImageView = {
        let image = UIImage(named: "wire-logo-black")
        let imageView = UIImageView(image: image)
        imageView.accessibilityIdentifier = "WireLogo"
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.Team.textColor
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return imageView
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel(key: "landing.welcome_message".localized(args: BackendEnvironment.shared.title), size: .large, weight: .light, color: .textForeground, variant: .light)
        label.font = LandingViewController.headlineFont
        label.textAlignment = .center
        label.numberOfLines = 2
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return label
    }()
    
    let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        return stackView
    }()
    
    let enterpriseLoginButton: Button = {
        let button = Button(style: .fullMonochrome, variant: .light)
        button.setBackgroundImageColor(UIColor.lightGraphiteAlpha24, for: .normal)
        button.accessibilityIdentifier = "Enterprise Login"
        button.setTitle("landing.login.enterprise.button.title".localized, for: .normal)
        button.addTarget(self, action: #selector(LandingViewController.enterpriseLoginButtonTapped(_:)
            ), for: .touchUpInside)
        
        return button
    }()

    let loginButton: Button = {
        let button = Button(style: .empty, variant: .light)
        button.accessibilityIdentifier = "Login"
        button.setTitle("landing.login.button.title".localized, for: .normal)
        button.addTarget(self, action: #selector(LandingViewController.loginButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }()
    
    let loginWithEmailButton: Button = {
        let button = Button(style: .full, variant: .light)
        button.accessibilityIdentifier = "Login with email"
        button.setTitle("landing.login.email.button.title".localized, for: .normal)
        button.addTarget(self, action: #selector(LandingViewController.loginButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }()
    
    let loginWithSSOButton: Button = {
        let button = Button(style: .empty, variant: .light)
        button.accessibilityIdentifier = "Log in with SSO"
        button.setTitle("landing.login.sso.button.title".localized, for: .normal)
        button.addTarget(self, action: #selector(LandingViewController.ssoLoginButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }()

    let createAccountButton: Button = {
        let button = Button(style: .full, variant: .light)
        button.accessibilityIdentifier = "Create An Account"
        button.setTitle("landing.create_account.title".localized, for: .normal)
        button.addTarget(self, action: #selector(LandingViewController.createAccountButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    let loginButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.axis = .vertical
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        return stackView
    }()
    
    let customBackendTitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "ConfigurationTitle"
        label.textAlignment = .center
        label.font = FontSpec(.normal, .bold).font!
        label.textColor = UIColor.Team.textColor
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    let customBackendSubtitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "ConfigurationLink"
        label.font = FontSpec(.small, .semibold).font!
        label.textColor = UIColor.Team.placeholderColor
        return label
    }()
    
    let customBackendSubtitleButton: UIButton = {
        let button = UIButton()
        button.setTitle("landing.custom_backend.more_info.button.title".localized.uppercased(), for: .normal)
        button.accessibilityIdentifier = "ShowMoreButton"
        button.setTitleColor(UIColor.Team.activeButton, for: .normal)
        button.titleLabel?.font = FontSpec(.small, .semibold).font!
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(LandingViewController.showCustomBackendLink(_:)), for: .touchUpInside)
        return button
    }()
    
    let customBackendSubtitleStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        return stackView
    }()
    
    let customBackendStack: UIStackView = {
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
        createConstraints()
        configureAccessibilityElements()

        updateBarButtonItem()
        disableTrackingIfNeeded()
        updateButtons()
        updateCustomBackendLabels()

        NotificationCenter.default.addObserver(
            forName: AccountManagerDidUpdateAccountsNotificationName,
            object: SessionManager.shared?.accountManager,
            queue: .main) { _ in
                self.updateBarButtonItem()
                self.disableTrackingIfNeeded()
        }
        
        NotificationCenter.default.addObserver(forName: BackendEnvironment.backendSwitchNotification, object: nil, queue: .main) { _ in
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

        contentView.addSubview(topStack)

        contentView.addSubview(messageLabel)
        buttonStackView.addArrangedSubview(createAccountButton)
        buttonStackView.addArrangedSubview(loginButton)
        buttonStackView.addArrangedSubview(loginWithEmailButton)
        buttonStackView.addArrangedSubview(loginWithSSOButton)
        contentView.addSubview(buttonStackView)
        contentView.addSubview(enterpriseLoginButton)

        view.addSubview(contentView)
    }

    private func createConstraints() {
        disableAutoresizingMaskTranslation(for: [
            topStack,
            contentView,
            buttonStackView,
            enterpriseLoginButton,
            messageLabel
        ])
        
        let widthConstraint = contentView.widthAnchor.constraint(equalToConstant: 375)
        widthConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            // content view
            widthConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 375),
            contentView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            
            // top stack view
            topStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            topStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // message label
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -40),
            
            // buttons stack view
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            createAccountButton.heightAnchor.constraint(equalToConstant: 48),
            loginButton.heightAnchor.constraint(equalToConstant: 48),
            loginWithEmailButton.heightAnchor.constraint(equalToConstant: 48),
            loginWithSSOButton.heightAnchor.constraint(equalToConstant: 48),
            
            // enterprise login stack view
            enterpriseLoginButton.heightAnchor.constraint(equalToConstant: 48),
            enterpriseLoginButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -17),
            enterpriseLoginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            enterpriseLoginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // logoView
            logoView.heightAnchor.constraint(lessThanOrEqualToConstant: 31)
        ])
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
            messageLabel.text = "landing.welcome_message".localized(args: productName)
        case .custom(url: let url):
            messageLabel.text = "landing.welcome_message".localized(args: BackendEnvironment.shared.title)
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
