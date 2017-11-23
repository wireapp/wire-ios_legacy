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
final class LandingViewController: UIViewController {
    var signInError: Error? // TODO: use it
    weak var delegate: LandingViewControllerDelegate?

    //MARK:- UI styles

    static let semiboldFont = FontSpec(.large, .semibold).font!
    static let regularFont = FontSpec(.normal, .regular).font!

    static let buttonTitleAttribute: [String : Any] = {
        let alignCenterStyle = NSMutableParagraphStyle()
        alignCenterStyle.alignment = NSTextAlignment.center

        let semiboldFont = FontSpec(.large, .semibold).font!

        return [NSForegroundColorAttributeName: UIColor.textColor, NSParagraphStyleAttributeName: alignCenterStyle, NSFontAttributeName:semiboldFont]
    }()

    static let buttonSubtitleAttribute: [String : Any] = {
        let alignCenterStyle = NSMutableParagraphStyle()
        alignCenterStyle.alignment = NSTextAlignment.center

        let lightFont = FontSpec(.large, .light).font!

        return [NSForegroundColorAttributeName: UIColor.textColor, NSParagraphStyleAttributeName: alignCenterStyle, NSFontAttributeName:lightFont]
    }()

    //MARK:- subviews

    let logoView: UIImageView = {
        let image = UIImage(named: "wire-logo-black")!
        let imageView = UIImageView(image: image)
        imageView.contentMode = .center
        imageView.tintColor = UIColor.textColor
        return imageView
    }()

    let headline: UILabel = {
        let label = UILabel()
        label.text = "landing.title".localized
        label.font = LandingViewController.regularFont
        label.textColor = .subtitleColor

        return label
    }()

    let createAccountButton: LandingButton = {
        let title = "landing.create_account.title".localized && LandingViewController.buttonTitleAttribute
        let subtitle = ("\n" + "landing.create_account.subtitle".localized) && LandingViewController.buttonSubtitleAttribute
        let twoLineTitle = title + subtitle

        let button = LandingButton(title: twoLineTitle, icon: .selfProfile, iconBackgroundColor: .createAccountBlue)

        button.addTarget(self, action: #selector(LandingViewController.createAccountButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    let createTeamButton: LandingButton = {
        let alignCenterStyle = NSMutableParagraphStyle()
        alignCenterStyle.alignment = NSTextAlignment.center

        let title = "landing.create_team.title".localized && LandingViewController.buttonTitleAttribute
        let subtitle = ("\n" + "landing.create_team.subtitle".localized) && LandingViewController.buttonSubtitleAttribute

        let button = LandingButton(title: title + subtitle, icon: .team, iconBackgroundColor: .createTeamGreen)

        button.addTarget(self, action: #selector(LandingViewController.createTeamButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    let containerView = UIView()
    let headerContainerView = UIView()

    let loginHintsLabel: UILabel = {
        let label = UILabel()
        label.text = "landing.login.hints".localized
        label.font = LandingViewController.regularFont
        label.textColor = .subtitleColor

        return label
    }()

    let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("landing.login.button.title".localized, for: .normal)
        button.setTitleColor(.textColor, for: .normal)
        button.titleLabel?.font = LandingViewController.semiboldFont

        button.addTarget(self, action: #selector(LandingViewController.loginButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .background

        [headerContainerView, containerView, loginHintsLabel, loginButton].forEach(view.addSubview)

        [logoView, headline].forEach(headerContainerView.addSubview)

        [createAccountButton, createTeamButton].forEach(containerView.addSubview)

        self.createConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.wr_setStatusBarHidden(true, with: .fade)
    }

    private func createConstraints() {

        constrain(logoView, headline, headerContainerView) { logoView, headline, headerContainerView in
            ///reserver space for status bar(20pt)
            logoView.top >= headerContainerView.top + (16 + 20)
            logoView.top == headerContainerView.top + 72 ~ LayoutPriority(500)
            logoView.centerX == headerContainerView.centerX
            logoView.width == 96
            logoView.height == 31

            headline.top == logoView.bottom + 16
            headline.centerX == headerContainerView.centerX
            headline.height >= 18
            headline.bottom <= headerContainerView.bottom - 16

        }

        constrain(self.view, headerContainerView, containerView) { selfView, headerContainerView, containerView in


            headerContainerView.width == selfView.width
            headerContainerView.centerX == selfView.centerX
            headerContainerView.top == selfView.top

            containerView.width == selfView.width
            containerView.centerX == selfView.centerX
            containerView.centerY == selfView.centerY

            headerContainerView.bottom == containerView.top
        }

        constrain(self.view, containerView, loginHintsLabel, loginButton) { selfView, containerView, loginHintsLabel, loginButton in
            containerView.bottom <= loginHintsLabel.top - 16

            loginHintsLabel.top == loginButton.top - 16
            loginHintsLabel.centerX == selfView.centerX

            loginButton.top == loginHintsLabel.bottom
            loginButton.centerX == selfView.centerX
            loginButton.bottom == selfView.bottomMargin - 32 ~ LayoutPriority(500)
        }

        constrain(containerView, createAccountButton, createTeamButton) { containerView, createAccountButton, createTeamtButton in

            createAccountButton.top == containerView.top
            createTeamtButton.bottom == containerView.bottom

            createAccountButton.centerX == containerView.centerX
            createAccountButton.width == containerView.width

            createTeamtButton.top == createAccountButton.bottom + 24
            createTeamtButton.centerX == containerView.centerX
            createTeamtButton.width == containerView.width

            createAccountButton.height == createTeamtButton.height
        }
    }

    // MARK:- Button tapped target

    @objc public func createAccountButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseCreateAccount()
    }

    @objc public func createTeamButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseCreateTeam()
    }

    @objc public func loginButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseLogin()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

}
