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

@objc protocol LandingViewControllerDelegate {
    func landingViewControllerDidChooseCreateAccount()
    func landingViewControllerDidChooseCreateTeam()
    func landingViewControllerDidChooseLogin()
}

/// Landing screen for choosing how to authenticate.
class LandingViewController: AuthenticationStepViewController {

    // MARK: - State

    weak var authenticationCoordinator: AuthenticationCoordinator?

    var delegate: LandingViewControllerDelegate? {
        return authenticationCoordinator
    }

    // MARK: - UI Styles

    static let semiboldFont = FontSpec(.large, .semibold).font!
    static let regularFont = FontSpec(.normal, .regular).font!

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

    // MARK: - Adaptive Constraints

    private var loginHintAlignTop: NSLayoutConstraint!
    private var loginButtonAlignBottom: NSLayoutConstraint!

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
        let label = UILabel(key: "Welcome to Wire", size: .large, weight: .medium, color: .textForeground, variant: .light)
        label.textAlignment = .center
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
        button.setBackgroundImageColor(UIColor.from(scheme: .secondaryAction), for: .normal)
        button.accessibilityIdentifier = "EnterpriseLoginButton"
        button.setTitle("landing.enterprise.login.button.title".localized, for: .normal)
        button.titleLabel?.font = UIFont.smallSemiboldFont
        button.addTarget(self, action: #selector(LandingViewController.enterpriseLoginButtonTapped(_:)
            ), for: .touchUpInside)
        
        return button
    }()
    
    let personalLoginButton: Button = {
        let button = Button(style: .empty, variant: .light)
        button.accessibilityIdentifier = "LoginButton"
        button.setTitle("landing.login.button.title".localized, for: .normal)
        button.titleLabel?.font = UIFont.smallSemiboldFont
        button.addTarget(self, action: #selector(LandingViewController.loginButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }()

    let createAccountButton: Button = {
        let button = Button(style: .full, variant: .light)
        button.accessibilityIdentifier = "CreateAccountButton"
        button.setTitle("landing.create_account.title".localized, for: .normal)
        button.titleLabel?.font = UIFont.smallSemiboldFont
        button.addTarget(self, action: #selector(LandingViewController.createAccountButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    let createTeamButton: LandingButton = {
        let button = LandingButton(title: createTeamButtonTitle, icon: .team, iconBackgroundColor: UIColor.Team.createAccountBlue)
        button.accessibilityIdentifier = "CreateTeamButton"
        button.addTapTarget(self, action: #selector(LandingViewController.createTeamButtonTapped(_:)))
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)

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
        updateCustomBackendLabel()

        NotificationCenter.default.addObserver(
            forName: AccountManagerDidUpdateAccountsNotificationName,
            object: SessionManager.shared?.accountManager,
            queue: .main) { _ in
                self.updateBarButtonItem()
                self.disableTrackingIfNeeded()
        }
        
        NotificationCenter.default.addObserver(forName: BackendEnvironment.backendSwitchNotification, object: nil, queue: .main) { _ in
            self.updateCustomBackendLabel()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: logoView)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private func configureSubviews() {
        if #available(iOS 11, *) {
            additionalSafeAreaInsets.top = -44
        }

        customBackendSubtitleStack.addArrangedSubview(customBackendSubtitleLabel)
        customBackendSubtitleStack.addArrangedSubview(customBackendSubtitleButton)

        customBackendStack.addArrangedSubview(customBackendTitleLabel)
        customBackendStack.addArrangedSubview(customBackendSubtitleStack)

        topStack.addArrangedSubview(logoView)
        topStack.addArrangedSubview(customBackendStack)
        contentView.addSubview(topStack)

        buttonStackView.addArrangedSubview(messageLabel)
        buttonStackView.addArrangedSubview(createAccountButton)
        buttonStackView.addArrangedSubview(personalLoginButton)
        buttonStackView.addArrangedSubview(createTeamButton)
        contentView.addSubview(buttonStackView)
        contentView.addSubview(enterpriseLoginButton)
        
        // Hide team creation for now
        createTeamButton.isHidden = true

        view.addSubview(contentView)
    }

    private func createConstraints() {
        topStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        enterpriseLoginButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // content view
            contentView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // top stack view
            topStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            topStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // buttons stack view
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            createAccountButton.heightAnchor.constraint(equalToConstant: 48),
            personalLoginButton.heightAnchor.constraint(equalToConstant: 48),
            createTeamButton.widthAnchor.constraint(lessThanOrEqualToConstant: 256),
            
            // enterprise login stack view
            enterpriseLoginButton.heightAnchor.constraint(equalToConstant: 48),
            enterpriseLoginButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -17),
            enterpriseLoginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            enterpriseLoginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // logoView
            logoView.heightAnchor.constraint(lessThanOrEqualToConstant: 31)
        ])
    }

    // MARK: - Adaptivity Events
    
    private func updateLogoView() {
        logoView.isHidden = isCustomBackend
    }
    
    var isCustomBackend: Bool {
        switch BackendEnvironment.shared.environmentType.value {
        case .production, .staging:
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
    
    private func updateCustomBackendLabel() {
        switch BackendEnvironment.shared.environmentType.value {
        case .production, .staging:
            customBackendStack.isHidden = true
            buttonStackView.alpha = 1
        case .custom(url: let url):
            customBackendTitleLabel.text = "landing.custom_backend.title".localized(args: BackendEnvironment.shared.title)
            customBackendSubtitleLabel.text = url.absoluteString.uppercased()
            customBackendStack.isHidden = false
            buttonStackView.alpha = 0
            createTeamButton.isHidden = false
        }
        updateLogoView()
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

    private static let createAccountButtonTitle: NSAttributedString = {
        let title = "landing.create_account.title".localized && LandingViewController.buttonTitleAttribute
        let subtitle = ("\n" + "landing.create_account.subtitle".localized) && LandingViewController.buttonSubtitleAttribute

        return title + subtitle
    }()

    private static let createTeamButtonTitle: NSAttributedString = {
        let title = "landing.create_team.title".localized && LandingViewController.buttonTitleAttribute
        let subtitle = ("\n" + "landing.create_team.subtitle".localized) && LandingViewController.buttonSubtitleAttribute

        return title + subtitle
    }()

    override func accessibilityPerformEscape() -> Bool {
        guard SessionManager.shared?.firstAuthenticatedAccount != nil else {
            return false
        }

        cancelButtonTapped()
        return true
    }

    // MARK: - Button tapped target
    
    @objc public func showCustomBackendLink(_ sender: AnyObject!) {
        let backendTitle = BackendEnvironment.shared.title
        let jsonURL = customBackendSubtitleLabel.text?.lowercased() ?? ""
        let alert = UIAlertController(title: "landing.custom_backend.more_info.alert.title".localized(args: backendTitle), message: "\(jsonURL)", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "general.ok".localized, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc public func createAccountButtonTapped(_ sender: AnyObject!) {
        Analytics.shared().tagOpenedUserRegistration(context: "email")
        delegate?.landingViewControllerDidChooseCreateAccount()
    }

    @objc public func createTeamButtonTapped(_ sender: AnyObject!) {
        Analytics.shared().tagOpenedTeamCreation(context: "email")
        delegate?.landingViewControllerDidChooseCreateTeam()
    }

    @objc public func loginButtonTapped(_ sender: AnyObject!) {
        Analytics.shared().tagOpenedLogin(context: "email")
        delegate?.landingViewControllerDidChooseLogin()
    }
    
    @objc public func enterpriseLoginButtonTapped(_ sender: AnyObject!) {
        // TODO: Show enterprise login popup
    }
    
    @objc public func cancelButtonTapped() {
        guard let account = SessionManager.shared?.firstAuthenticatedAccount else { return }
        SessionManager.shared!.select(account)
    }

}
