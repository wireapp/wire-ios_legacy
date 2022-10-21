//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireCommonComponents

protocol PermissionDeniedViewControllerDelegate: AnyObject {
    func continueWithoutPermission(_ viewController: PermissionDeniedViewController)
}

final class PermissionDeniedViewController: UIViewController {

    weak var delegate: PermissionDeniedViewControllerDelegate?

    private var initialConstraintsCreated = false
    private let heroLabel: UILabel = UILabel.createHeroLabel()
    private var settingsButton: LegacyButton!
    private var laterButton: UIButton!

    class func addressBookAccessDeniedViewController() -> PermissionDeniedViewController {
        let vc = PermissionDeniedViewController()
        let title = "registration.address_book_access_denied.hero.title".localized
        let paragraph1 = "registration.address_book_access_denied.hero.paragraph1".localized
        let paragraph2 = "registration.address_book_access_denied.hero.paragraph2".localized

        let text = [title, paragraph1, paragraph2].joined(separator: "\u{2029}")

        let attributedText = text.withCustomParagraphSpacing()

        attributedText.addAttributes([
            NSAttributedString.Key.font: FontSpec.largeThinFont.font!
            ], range: (text as NSString).range(of: [paragraph1, paragraph2].joined(separator: "\u{2029}")))
        attributedText.addAttributes([
            NSAttributedString.Key.font: FontSpec.largeSemiboldFont.font!
            ], range: (text as NSString).range(of: title))
        vc.heroLabel.attributedText = attributedText

        vc.settingsButton.setTitle("registration.address_book_access_denied.settings_button.title".localized.uppercased(), for: .normal)

        vc.laterButton.setTitle("registration.address_book_access_denied.maybe_later_button.title".localized.uppercased(), for: .normal)

        return vc
    }

    class func pushDeniedViewController() -> PermissionDeniedViewController {
        let vc = PermissionDeniedViewController()
        let title = "registration.push_access_denied.hero.title".localized
        let paragraph1 = "registration.push_access_denied.hero.paragraph1".localized

        let text = [title, paragraph1].joined(separator: "\u{2029}")

        let attributedText = text.withCustomParagraphSpacing()

        attributedText.addAttributes([
            NSAttributedString.Key.font: FontSpec.largeThinFont.font!
            ], range: (text as NSString).range(of: paragraph1))
        attributedText.addAttributes([
            NSAttributedString.Key.font: FontSpec.largeSemiboldFont.font!
            ], range: (text as NSString).range(of: title))
        vc.heroLabel.attributedText = attributedText

        vc.settingsButton.setTitle("registration.push_access_denied.settings_button.title".localized.uppercased(), for: .normal)

        vc.laterButton.setTitle("registration.push_access_denied.maybe_later_button.title".localized.uppercased(), for: .normal)

        return vc
    }

    required init() {
        super.init(nibName: nil, bundle: nil)

        view.addSubview(heroLabel)
        createSettingsButton()
        createLaterButton()

        updateViewConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createSettingsButton() {
        settingsButton = Button(style: .accentColorTextButtonStyle, cornerRadius: 16, fontSpec: .normalSemiboldFont)
        settingsButton.addTarget(self, action: #selector(openSettings(_:)), for: .touchUpInside)

        view.addSubview(settingsButton)
    }

    private func createLaterButton() {
        laterButton = Button(style: .secondaryTextButtonStyle, cornerRadius: 16, fontSpec: .normalSemiboldFont)
        laterButton.addTarget(self, action: #selector(continueWithoutAccess(_:)), for: .touchUpInside)

        view.addSubview(laterButton)
    }

    // MARK: - Actions
    @objc
    private func openSettings(_ sender: Any?) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @objc
    private func continueWithoutAccess(_ sender: Any?) {
        delegate?.continueWithoutPermission(self)
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        guard !initialConstraintsCreated else { return }

        initialConstraintsCreated = true

        [heroLabel, settingsButton, laterButton].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }

        var constraints = [heroLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
                           heroLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28)]

        constraints += [settingsButton.topAnchor.constraint(equalTo: heroLabel.bottomAnchor, constant: 28),
                        settingsButton.heightAnchor.constraint(equalToConstant: 56)]

        constraints += [settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
                        settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28)]

        constraints += [laterButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 28),
                        laterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -28),
                        laterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        laterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
                        laterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
                        laterButton.heightAnchor.constraint(equalToConstant: 56)]

        NSLayoutConstraint.activate(constraints)

    }
}
