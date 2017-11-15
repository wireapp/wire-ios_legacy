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

fileprivate extension UIColor {
    static let background = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.0)
    static let inactiveButton = UIColor(red:0.20, green:0.22, blue:0.23, alpha:0.16)
    static let activeButton = UIColor(red:0.14, green:0.57, blue:0.83, alpha:1.0)
    static let createAccountBlue = UIColor(for: .strongBlue)!
    static let createTeamGreen = UIColor(for: .strongLimeGreen)!
    static let textColor = UIColor(red:0.20, green:0.22, blue:0.23, alpha:1.0)
    static let subtitleColor = UIColor(red:0.20, green:0.22, blue:0.23, alpha:0.56)
}


final class LandingViewController: UIViewController {
    var signInError: Error? // TODO: use it




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
        label.text = "Secure messenger for everyone.".localized
        label.font = LandingViewController.regularFont
        label.textColor = .subtitleColor

        return label
    }()

    let createAccountButton: LandingButton = {
        let title = "Create an account".localized && LandingViewController.buttonTitleAttribute
        let subtitle = "\nfor personal use".localized && LandingViewController.buttonSubtitleAttribute
        let twoLineTitle = title + subtitle

        let button = LandingButton(title: twoLineTitle, icon: .selfProfile, iconBackgroundColor: .createAccountBlue)
        return button
    }()

    let createTeamtButton: LandingButton = {
        let alignCenterStyle = NSMutableParagraphStyle()
        alignCenterStyle.alignment = NSTextAlignment.center

        let title = "Create a team".localized && LandingViewController.buttonTitleAttribute
        let subtitle = "\nfor work".localized && LandingViewController.buttonSubtitleAttribute

        let button = LandingButton(title: title + subtitle, icon: .team, iconBackgroundColor: .createTeamGreen)
        return button
    }()

    let containerView = UIView()

    let loginHintsLabel: UILabel = {
        let label = UILabel()
        label.text = "Already have an account?".localized
        label.font = LandingViewController.regularFont
        label.textColor = .subtitleColor

        return label
    }()

    let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log in".localized, for: .normal)
        button.setTitleColor(.textColor, for: .normal)
        button.titleLabel?.font = LandingViewController.semiboldFont

        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .background

        [logoView, headline, containerView, loginHintsLabel, loginButton].forEach(view.addSubview)

        [createAccountButton, createTeamtButton].forEach(containerView.addSubview)

        self.createConstraints()
    }

    private func createConstraints() {

        constrain(self.view, logoView, headline, containerView) { selfView, logoView, headline, containerView in
            logoView.top == selfView.top + 72 ~ LayoutPriority(750)
            logoView.centerX == selfView.centerX
            logoView.width == 96
            logoView.height == 31

            headline.top == logoView.bottom + 16
            headline.centerX == selfView.centerX
//            headline.bottom >= containerView.top + 16

            containerView.centerX == selfView.centerX
            containerView.centerY == selfView.centerY
        }

        constrain(self.view, createTeamtButton, loginHintsLabel, loginButton) { selfView, createTeamtButton, loginHintsLabel, loginButton in
            loginHintsLabel.top == loginButton.top - 16
            loginHintsLabel.centerX == selfView.centerX

            loginButton.top == loginHintsLabel.bottom
            loginButton.centerX == selfView.centerX
            loginButton.bottom == selfView.bottom - 32 ~ LayoutPriority(750)
            ///TODO: save area for iPhone X
        }

        constrain(containerView, createAccountButton, createTeamtButton) { containerView, createAccountButton, createTeamtButton in

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
}
