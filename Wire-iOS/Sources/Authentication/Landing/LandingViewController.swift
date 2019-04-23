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

    let contentStack: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.axis = .vertical

        return stackView
    }()

    let logoView: UIImageView = {
        let image = UIImage(named: "wire-logo-black")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.Team.textColor
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return imageView
    }()
    
    let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        return stackView
    }()

    let createAccountButton: LandingButton = {
        let button = LandingButton(title: createAccountButtonTitle, icon: .personalProfile, iconBackgroundColor: UIColor.Team.createTeamGreen)
        button.accessibilityIdentifier = "CreateAccountButton"
        button.addTapTarget(self, action: #selector(LandingViewController.createAccountButtonTapped(_:)))
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)

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

    let loginHintsLabel: UILabel = {
        let label = UILabel()
        label.text = "landing.login.hints".localized
        label.font = LandingViewController.regularFont
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.Team.subtitleColor
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("landing.login.button.title".localized, for: .normal)
        button.accessibilityIdentifier = "LoginButton"
        button.setTitleColor(UIColor.Team.textColor, for: .normal)
        button.titleLabel?.font = LandingViewController.semiboldFont
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)

        button.addTarget(self, action: #selector(LandingViewController.loginButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        Analytics.shared().tagOpenedLandingScreen(context: "email")
        self.view.backgroundColor = UIColor.Team.background

        configureSubviews()
        createConstraints()
        configureAccessibilityElements()

        updateForCurrentSizeClass(isRegular: traitCollection.horizontalSizeClass == .regular)
        updateBarButtonItem()
        disableTrackingIfNeeded()

        NotificationCenter.default.addObserver(
            forName: AccountManagerDidUpdateAccountsNotificationName,
            object: SessionManager.shared?.accountManager,
            queue: nil) { _ in
                self.updateBarButtonItem()
                self.disableTrackingIfNeeded()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: logoView)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let isRegular = traitCollection.horizontalSizeClass == .regular
        updateForCurrentSizeClass(isRegular: isRegular)
    }

    private func configureSubviews() {
        if #available(iOS 11, *) {
            additionalSafeAreaInsets.top = -44
        }

        contentStack.addArrangedSubview(logoView)

        buttonStackView.addArrangedSubview(createAccountButton)
        buttonStackView.addArrangedSubview(createTeamButton)
        contentStack.addArrangedSubview(buttonStackView)

        loginButtonsStackView.addArrangedSubview(loginHintsLabel)
        loginButtonsStackView.addArrangedSubview(loginButton)
        contentStack.addArrangedSubview(loginButtonsStackView)

        view.addSubview(contentStack)
    }

    private func createConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // contentStack
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: safeTopAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: safeBottomAnchor, constant: -12),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            contentStack.centerYAnchor.constraint(equalTo: safeCenterYAnchor),

            // buttons width
            createAccountButton.widthAnchor.constraint(lessThanOrEqualToConstant: 256),
            createTeamButton.widthAnchor.constraint(lessThanOrEqualToConstant: 256),
            loginButtonsStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 256),

            // logoView
            logoView.heightAnchor.constraint(lessThanOrEqualToConstant: 31)
        ])
    }

    // MARK: - Adaptivity Events

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.frame.height <= 640 {
            // Small-height devices
            logoView.isHidden = true
            contentStack.spacing = 24
            buttonStackView.spacing = 24

            if #available(iOS 11, *) {
                contentStack.setCustomSpacing(0, after: logoView)
            }

        } else {
            // Normal-height devices
            logoView.isHidden = false
            contentStack.spacing = 32
            buttonStackView.spacing = 32

            if #available(iOS 11, *) {
                contentStack.setCustomSpacing(40, after: logoView)
            }
        }
    }

    func updateForCurrentSizeClass(isRegular: Bool) {
        updateStackViewAxis(isRegular: isRegular)
    }

    private func updateStackViewAxis(isRegular: Bool) {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            buttonStackView.axis = .horizontal
            buttonStackView.alignment = .top

        default:
            buttonStackView.axis = .vertical
            buttonStackView.alignment = .center
        }
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
    
    @objc public func cancelButtonTapped() {
        guard let account = SessionManager.shared?.firstAuthenticatedAccount else { return }
        SessionManager.shared!.select(account)
    }

}
