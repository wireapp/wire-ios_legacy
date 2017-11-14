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
}


final class LandingViewController: UIViewController {
    var signInError: Error? // TODO: use it

    let logoView: UIImageView = {
        let image = UIImage(named: "wire-logo-long")!
        let imageView = UIImageView(image: image.withRenderingMode(.alwaysTemplate))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.textColor
        return imageView
    }()

    let headline: UILabel = {
        let label = UILabel()
        label.text = "Secure messenger for everyone.".localized

        return label
    }()

    let createAccountButton: LandingButton = {
        let title = "Create an account".localized && [NSForegroundColorAttributeName: UIColor.textColor]
        let subtitle = "\nfor personal use".localized && [NSForegroundColorAttributeName: UIColor.textColor] ///FIXME: thin font
        let twoLineTitle = title + subtitle

        let button = LandingButton(title: twoLineTitle, icon: .selfProfile, iconBackgroundColor: .createAccountBlue)
        return button
    }()

    let createTeamtButton: LandingButton = {
        let title = "Create team".localized && [NSForegroundColorAttributeName: UIColor.textColor]
        let subtitle = "\nfor work".localized && [NSForegroundColorAttributeName: UIColor.textColor] ///FIXME: thin font

        let button = LandingButton(title: title + subtitle, icon: .team, iconBackgroundColor: .createTeamGreen)
        return button
    }()

    let loginHintsLabel: UILabel = {
        let label = UILabel()
        label.text = "Already have an account?".localized

        return label
    }()

    let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("LOGIN".localized, for: .normal)
        button.setTitleColor(.textColor, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .background

        [logoView, headline, createAccountButton, createTeamtButton, loginHintsLabel, loginButton].forEach(view.addSubview)

        self.createConstraints()
    }

    private func createConstraints() {
        let inset: CGFloat = 32

        constrain(self.view, logoView, headline, createAccountButton, createTeamtButton) { selfView, logoView, headline, createAccountButton, createTeamtButton in
            logoView.top == selfView.top + inset ~ LayoutPriority(750)
            logoView.centerX == selfView.centerX

            headline.top == logoView.bottom + inset
            headline.centerX == selfView.centerX

            createAccountButton.top == headline.bottom + inset
            createAccountButton.centerX == selfView.centerX

            createTeamtButton.top == createAccountButton.bottom + inset
            createTeamtButton.centerX == selfView.centerX

            createAccountButton.height == createTeamtButton.height
        }

        constrain(self.view, createTeamtButton, loginHintsLabel, loginButton) { selfView, createTeamtButton, loginHintsLabel, loginButton in
            loginHintsLabel.top == createTeamtButton.bottom + inset
            loginHintsLabel.centerX == selfView.centerX

            loginButton.top == loginHintsLabel.bottom
            loginButton.centerX == selfView.centerX
            loginButton.bottom == selfView.bottom - inset
        }
    }
}
