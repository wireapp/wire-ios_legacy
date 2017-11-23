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

class TeamNameStepViewController: UIViewController {
    // MARK:- UI styles

    static let headlineFont = FontSpec(.large, .light, .largeTitle).font!
    static let subheadlineFont = FontSpec(.normal, .regular).font!
    static let textButtonFont = FontSpec(.small, .semibold).font!

    let containerView = UIView()

    let headline: UILabel = {
        let label = UILabel()
        label.text = "team.name.headline".localized
        label.font = TeamNameStepViewController.headlineFont
        label.textColor = .textColor
        label.textAlignment = .center

        return label
    }()

    let subheadline: UILabel = {
        let label = UILabel()
        label.text = "team.name.subheadline".localized
        label.font = TeamNameStepViewController.subheadlineFont
        label.textColor = .subtitleColor
        label.textAlignment = .center

        return label
    }()

    let teamNameTextField: AccessoryTextField = {
        let accssoryTextField = AccessoryTextField(textFieldType: .name)
        accssoryTextField.placeholder = "team.name.textfield.placeholder".localized

        return accssoryTextField
    }()


    let errorLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = TeamNameStepViewController.textButtonFont
        label.textColor = .errorMessageColor
        label.textAlignment = .center

        return label
    }()

    ///TODO: clickable
    let linkTappable: UILabel = {
        let label = UILabel()
        label.text = "team.name.whatiswireforteams".localized.uppercased()
        label.font = TeamNameStepViewController.textButtonFont
        label.textColor = .textColor
        label.textAlignment = .center

        return label
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        teamNameTextField.accessoryTextFieldDelegate = self

        self.view.backgroundColor = .background

        [containerView].forEach(view.addSubview)

        [headline, subheadline, teamNameTextField, errorLabel, linkTappable].forEach(containerView.addSubview)

        self.createConstraints()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIApplication.shared.wr_setStatusBarHidden(false, with: .fade)

        if let navigationController = self.navigationController as! NavigationController? {
            navigationController.backButton.setIconColor(.textColor, for: .normal) ///TODO: no change?
            navigationController.backButton.tintColor = .textColor
            navigationController.backButtonEnabled = true
        }

    }

    private func createConstraints() {

        constrain(self.view, containerView) { selfView, containerView in
            ///FIXME: ipad width = 375
            containerView.width == selfView.width
            containerView.centerX == selfView.centerX
            containerView.centerY == selfView.centerY
        }

        constrain(containerView, headline, subheadline, teamNameTextField, linkTappable) {
            containerView, headline, subheadline, teamNameTextField, linkTappable in

            align(centerX: containerView, headline, subheadline, teamNameTextField, linkTappable)
            align(left: containerView, headline, subheadline, teamNameTextField, linkTappable)
            align(right: containerView, headline, subheadline, teamNameTextField, linkTappable)

            subheadline.top == headline.bottom + 24

            teamNameTextField.top == subheadline.bottom + 24
            teamNameTextField.height == 56
            teamNameTextField.centerY == containerView.centerY
        }

        constrain(containerView, errorLabel, teamNameTextField, linkTappable) { containerView, errorLabel, teamNameTextField, linkTappable in
            align(centerX: containerView, errorLabel)
            align(left: containerView, errorLabel)
            align(right: containerView, errorLabel)

            errorLabel.top == teamNameTextField.bottom + 16

            linkTappable.top == errorLabel.bottom + 16

            linkTappable.bottom == containerView.bottom + 24
        }
    }

    @objc public func confrimButtonTapped(_ sender: AnyObject!) {
//        delegate?.
        ///FIXME
    }

    @objc public func whatIsWireTapped(_ sender: AnyObject!) {
        //        delegate?.
        ///FIXME
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

}

extension TeamNameStepViewController: AccessoryTextFieldDelegate {
    func validationSucceed(accessoryTextField: AccessoryTextField, length: Int?) {
        errorLabel.text = nil
    }


    func validationErrorDidOccur(accessoryTextField: AccessoryTextField, error: TextFieldValidationError?) {
        if let error = error {
        switch error {
        case .tooLong:
            errorLabel.text = "name.guidance.toolong".localized
        case .tooShort:
            errorLabel.text = "name.guidance.tooshort".localized
        default:
            errorLabel.text = "unknown error".localized
            break
        }
        }
    }

}
