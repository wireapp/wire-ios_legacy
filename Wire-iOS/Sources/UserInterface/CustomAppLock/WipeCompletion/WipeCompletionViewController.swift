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

import Foundation
import UIKit

final class WipeCompletionViewController: UIViewController {
    let wireLogoInfoView = WireLogoInfoView(title: "wipe_database_completion.title".localized, subtitle: "wipe_database_completion.subtitle".localized)

    private lazy var loginButton: Button = {
        let button = Button(style: .full, titleLabelFont: .smallSemiboldFont)

        button.setBackgroundImageColor(.strongBlue, for: .normal)

        button.setTitle("signin.confirm".localized(uppercased: true), for: .normal)

        button.addTarget(self, action: #selector(onLoginCodeButtonPressed(sender:)), for: .touchUpInside)

        return button
    }()

    init() {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = UIColor.Team.background

        configureSubviews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func configureSubviews() {
        view.addSubview(wireLogoInfoView)

        wireLogoInfoView.contentView.addSubview(loginButton)
    }

    private func createConstraints() {
        [wireLogoInfoView,
         loginButton].disableAutoresizingMaskTranslation()

        NSLayoutConstraint.activate([
            wireLogoInfoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wireLogoInfoView.topAnchor.constraint(equalTo: view.topAnchor),
            wireLogoInfoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wireLogoInfoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // log in button
            loginButton.heightAnchor.constraint(equalToConstant: CGFloat.WipeCompletion.buttonHeight),

            loginButton.bottomAnchor.constraint(equalTo: wireLogoInfoView.contentView.bottomAnchor, constant: -24),
            loginButton.leadingAnchor.constraint(equalTo: wireLogoInfoView.contentView.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: wireLogoInfoView.contentView.trailingAnchor)
        ])
    }

    @objc
    private func onLoginCodeButtonPressed(sender: AnyObject?) {
        dismiss(animated: true)
    }

}
