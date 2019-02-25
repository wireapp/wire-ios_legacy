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

import Foundation
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

    fileprivate var device: DeviceProtocol

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

        let lightFont = FontSpec(.normal, .light).font!

        return [.foregroundColor: UIColor.Team.textColor, .paragraphStyle: alignCenterStyle, .font: lightFont]
    }()

    // MARK: - Adaptive Constraints

    private var loginHintAlignTop: NSLayoutConstraint!
    private var loginButtonAlignBottom: NSLayoutConstraint!

    // MARK: - UI Elements

    let logoView: UIImageView = {
        let image = UIImage(named: "wire-logo-black")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .center
        imageView.tintColor = UIColor.Team.textColor
        return imageView
    }()
    
    let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.spacing = 24
        stackView.axis = .vertical

        return stackView
    }()

    let createAccountButton: LandingButton = {
        let button = LandingButton(title: createAccountButtonTitle, icon: .selfProfile, iconBackgroundColor: UIColor.Team.createTeamGreen)
        button.accessibilityIdentifier = "CreateAccountButton"
        button.addTarget(self, action: #selector(LandingViewController.createAccountButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    let createTeamButton: LandingButton = {
        let button = LandingButton(title: createTeamButtonTitle, icon: .team, iconBackgroundColor: UIColor.Team.createAccountBlue)
        button.accessibilityIdentifier = "CreateTeamButton"
        button.addTarget(self, action: #selector(LandingViewController.createTeamButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    let headerContainerView = UIView()

    let loginHintsLabel: UILabel = {
        let label = UILabel()
        label.text = "landing.login.hints".localized
        label.font = LandingViewController.regularFont
        label.textColor = UIColor.Team.subtitleColor

        return label
    }()

    let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("landing.login.button.title".localized, for: .normal)
        button.accessibilityIdentifier = "LoginButton"
        button.setTitleColor(UIColor.Team.textColor, for: .normal)
        button.titleLabel?.font = LandingViewController.semiboldFont

        button.addTarget(self, action: #selector(LandingViewController.loginButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    // MARK: - Initialization

    /// Init method for injecting a mock device.
    /// - parameter device: Provide this param for testing only
    init(device: DeviceProtocol = UIDevice.current) {
        self.device = device

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        Analytics.shared().tagOpenedLandingScreen(context: "email")

        [headerContainerView, buttonStackView, loginHintsLabel, loginButton].forEach(view.addSubview)
        headerContainerView.addSubview(logoView)

        [createAccountButton, createTeamButton].forEach { button in
            buttonStackView.addArrangedSubview(button)
        }

        self.view.backgroundColor = UIColor.Team.background

        self.createConstraints()
        self.configureAccessibilityElements()

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
        UIAccessibility.post(notification: .screenChanged, argument: headerContainerView)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let isRegular = traitCollection.horizontalSizeClass == .regular
        updateForCurrentSizeClass(isRegular: isRegular)
    }

    private func createConstraints() {
        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
        logoView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        loginHintsLabel.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        loginHintAlignTop = loginHintsLabel.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 80)
        loginButtonAlignBottom = loginButton.bottomAnchor.constraint(equalTo: safeBottomAnchor, constant: -32)

        NSLayoutConstraint.activate([
            // headerContainerView
            headerContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            headerContainerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            headerContainerView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor),
            headerContainerView.topAnchor.constraint(equalTo: view.topAnchor),

            // logoView
            logoView.centerXAnchor.constraint(equalTo: headerContainerView.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 96),
            logoView.heightAnchor.constraint(equalToConstant: 31),

            // buttonStackView
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // loginHintsLabel
            loginHintsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginHintsLabel.bottomAnchor.constraint(equalTo: loginButton.topAnchor, constant: -16),
            loginHintsLabel.topAnchor.constraint(greaterThanOrEqualTo: buttonStackView.bottomAnchor, constant: 16),

            // loginButton
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

        ])

        [createAccountButton, createTeamButton].forEach() { button in
            button.setContentCompressionResistancePriority(.required, for: .vertical)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }

    // MARK: - Adaptivity Events

    func updateForCurrentSizeClass(isRegular: Bool) {
        updateConstraints(isRegular: isRegular)
        updateStackViewAxis(isRegular: isRegular)
    }

    private func updateConstraints(isRegular: Bool) {
        if isRegular {
            loginButtonAlignBottom.isActive = false
            loginHintAlignTop.isActive = true
        } else {
            loginHintAlignTop.isActive = false
            loginButtonAlignBottom.isActive = true
        }
    }

    private func updateStackViewAxis(isRegular: Bool) {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            buttonStackView.axis = .horizontal
        default:
            buttonStackView.axis = .vertical
        }
    }

    private func updateBarButtonItem() {
        if SessionManager.shared?.firstAuthenticatedAccount == nil {
            navigationItem.rightBarButtonItem = nil
        } else {
            let cancelItem = UIBarButtonItem(icon: .cancel, target: self, action: #selector(cancelButtonTapped))
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
        logoView.isAccessibilityElement = false

        headerContainerView.isAccessibilityElement = true
        headerContainerView.accessibilityLabel = "landing.header".localized
        headerContainerView.accessibilityTraits.insert(.header)
        headerContainerView.shouldGroupAccessibilityChildren = true
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
