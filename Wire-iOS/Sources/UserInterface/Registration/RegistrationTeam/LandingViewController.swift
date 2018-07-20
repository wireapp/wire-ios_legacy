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
import Cartography

@objc protocol LandingViewControllerDelegate {
    func landingViewControllerDidChooseCreateAccount()
    func landingViewControllerDidChooseCreateTeam()
    func landingViewControllerDidChooseLogin()
}

/// Landing screen for choosing create team or personal account
final class LandingViewController: UIViewController, CompanyLoginControllerDelegate {
    weak var delegate: LandingViewControllerDelegate?

    fileprivate var device: DeviceProtocol
    private let companyLoginController = CompanyLoginController()

    // MARK: - UI styles

    static let semiboldFont = FontSpec(.large, .semibold).font!
    static let regularFont = FontSpec(.normal, .regular).font!

    static let buttonTitleAttribute: [NSAttributedStringKey: AnyObject] = {
        let alignCenterStyle = NSMutableParagraphStyle()
        alignCenterStyle.alignment = NSTextAlignment.center

        return [.foregroundColor: UIColor.Team.textColor, .paragraphStyle: alignCenterStyle, .font: semiboldFont]
    }()

    static let buttonSubtitleAttribute: [NSAttributedStringKey: AnyObject] = {
        let alignCenterStyle = NSMutableParagraphStyle()
        alignCenterStyle.alignment = NSTextAlignment.center
        alignCenterStyle.paragraphSpacingBefore = 4

        let lightFont = FontSpec(.normal, .light).font!

        return [.foregroundColor: UIColor.Team.textColor, .paragraphStyle: alignCenterStyle, .font: lightFont]
    }()

    // MARK: - constraints for iPad

    private var logoAlignTop: NSLayoutConstraint!
    private var loginButtonAlignBottom: NSLayoutConstraint!
    private var loginHintAlignTop: NSLayoutConstraint!
    private var headlineAlignBottom: NSLayoutConstraint!

    // MARK: - subviews

    let logoView: UIImageView = {
        let image = UIImage(named: "wire-logo-black")!
        let imageView = UIImageView(image: image)
        imageView.contentMode = .center
        imageView.tintColor = UIColor.Team.textColor
        return imageView
    }()

    let headline: UILabel = {
        let label = UILabel()
        label.text = "landing.title".localized
        label.font = LandingViewController.regularFont
        label.textColor = UIColor.Team.subtitleColor
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    let headlineStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.axis = .vertical

        return stackView
    }()

    let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.spacing = 24
        stackView.axis = .vertical

        return stackView
    }()

    let createAccountButton: LandingButton = {
        let button = LandingButton(title: createAccountButtonTitle, icon: .selfProfile, iconBackgroundColor: UIColor.Team.createAccountBlue)
        button.accessibilityIdentifier = "CreateAccountButton"
        button.addTarget(self, action: #selector(LandingViewController.createAccountButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    let createTeamButton: LandingButton = {
        let button = LandingButton(title: createTeamButtonTitle, icon: .team, iconBackgroundColor: UIColor.Team.createTeamGreen)
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

    let navigationBar: UINavigationBar = {
        let bar = UINavigationBar()
        bar.shadowImage = UIImage()
        bar.setBackgroundImage(UIImage(), for: .default)
        return bar
    }()

    /// init method for injecting mock device
    ///
    /// - Parameter device: Provide this param for testing only
    init(device: DeviceProtocol = UIDevice.current) {
        self.device = device

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Analytics.shared().tagOpenedLandingScreen(context: "email")

        [headerContainerView, buttonStackView, loginHintsLabel, loginButton].forEach(view.addSubview)
        [logoView, headline].forEach(headlineStackView.addArrangedSubview)
        headerContainerView.addSubview(headlineStackView)
        
        [createAccountButton, createTeamButton].forEach { button in
            buttonStackView.addArrangedSubview(button)
        }

        self.view.backgroundColor = UIColor.Team.background
        navigationBar.pushItem(navigationItem, animated: false)
        navigationBar.tintColor = .black
        view.addSubview(navigationBar)
        companyLoginController.delegate = self

        self.createConstraints()
        self.configureAccessibilityElements()

        updateStackViewAxis()
        updateConstraintsForIPad()
        updateBarButtonItem()

        NotificationCenter.default.addObserver(
            forName: AccountManagerDidUpdateAccountsNotificationName,
            object: SessionManager.shared?.accountManager,
            queue: nil) { _ in self.updateBarButtonItem()  }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        companyLoginController.isAutoDetectionEnabled = true
        companyLoginController.detectLoginCode()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        companyLoginController.isAutoDetectionEnabled = false
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateStackViewAxis()
        updateConstraintsForIPad()
    }

    private func createConstraints() {

        let safeArea = view.safeAreaLayoutGuideOrFallback
        navigationBar.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true

        constrain(view, navigationBar) { selfView, navigationBar in
            navigationBar.left == selfView.left
            navigationBar.right == selfView.right
        }

        constrain(headlineStackView, logoView, headline, headerContainerView) {
            headlineStackView, logoView, headline, headerContainerView in

            ///reserver space for status bar(20pt)
            headlineStackView.top >= headerContainerView.top + 36
            logoAlignTop = headlineStackView.top == headerContainerView.top + 72 ~ 500.0
            headlineStackView.centerX == headerContainerView.centerX
            logoView.width == 96
            logoView.height == 31

            headline.height >= 18
            headlineStackView.bottom <= headerContainerView.bottom - 16

            if UIDevice.current.userInterfaceIdiom == .pad {
                headlineAlignBottom = headlineStackView.bottom == headerContainerView.bottom - 80
            }
        }

        constrain(self.view, headerContainerView, buttonStackView) { selfView, headerContainerView, buttonStackView in

            headerContainerView.width == selfView.width
            headerContainerView.centerX == selfView.centerX
            headerContainerView.top == selfView.top

            buttonStackView.centerX == selfView.centerX
            buttonStackView.centerY == selfView.centerY

            headerContainerView.bottom == buttonStackView.top
        }

        constrain(self.view, buttonStackView, loginHintsLabel, loginButton) {
            selfView, buttonStackView, loginHintsLabel, loginButton in
            buttonStackView.bottom <= loginHintsLabel.top - 16

            loginHintsLabel.bottom == loginButton.top - 16
            loginHintsLabel.centerX == selfView.centerX
            if UIDevice.current.userInterfaceIdiom == .pad {
                loginHintAlignTop = loginHintsLabel.top == buttonStackView.bottom + 80
            }


            loginButton.top == loginHintsLabel.bottom + 4
            loginButton.centerX == selfView.centerX
            loginButton.height >= 44
            loginButton.width >= 44
            loginButtonAlignBottom = loginButton.bottom == selfView.bottomMargin - 32 ~ 500.0
        }

        [createAccountButton, createTeamButton].forEach() { button in
            button.setContentCompressionResistancePriority(.required, for: .vertical)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }

    fileprivate func updateConstraintsForIPad() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }

        switch self.traitCollection.horizontalSizeClass {
        case .compact:
            loginHintAlignTop.isActive = false
            headlineAlignBottom.isActive = false
            logoAlignTop.isActive = true
            loginButtonAlignBottom.isActive = true
        default:
            logoAlignTop.isActive = false
            loginButtonAlignBottom.isActive = false
            loginHintAlignTop.isActive = true
            headlineAlignBottom.isActive = true
        }
    }

    func updateStackViewAxis() {
        let userInterfaceIdiom = device.userInterfaceIdiom
        guard userInterfaceIdiom == .pad else { return }

        switch self.traitCollection.horizontalSizeClass {
        case .regular:
            buttonStackView.axis = .horizontal
        default:
            buttonStackView.axis = .vertical
        }
    }

    private func updateBarButtonItem() {

        if SessionManager.shared?.firstAuthenticatedAccount == nil {
            navigationBar.topItem?.rightBarButtonItem = nil
        } else {
            let cancelItem = UIBarButtonItem(icon: .cancel, target: self, action: #selector(cancelButtonTapped))
            cancelItem.accessibilityIdentifier = "CancelButton"
            cancelItem.accessibilityLabel = "general.cancel".localized
            navigationBar.topItem?.rightBarButtonItem = cancelItem
        }

    }

    // MARK: - Accessibility

    private func configureAccessibilityElements() {
        logoView.isAccessibilityElement = false
        headline.isAccessibilityElement = false

        headlineStackView.isAccessibilityElement = true
        headlineStackView.accessibilityLabel = "landing.app_name".localized + "\n" + "landing.title".localized
        headlineStackView.accessibilityTraits = UIAccessibilityTraitHeader
        headlineStackView.shouldGroupAccessibilityChildren = true

        headerContainerView.accessibilityElements = [headlineStackView]
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

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - CompanyLoginControllerDelegate
    
    func controller(_ controller: CompanyLoginController, presentAlert alert: UIAlertController) {
        present(alert, animated: true)
    }
    
}

