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

protocol ShareContactsViewControllerDelegate: class {
    func shareDidSkip(_ viewController: UIViewController)
    func shareDidFinish(_ viewController: UIViewController)
}

extension String {
    func withCustomParagraphSpacing() -> NSMutableAttributedString {
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 10

        let attributedText = NSMutableAttributedString(string: self,
                                                       attributes: [
                                                        NSAttributedString.Key.paragraphStyle: paragraphStyle])

        return attributedText
    }
}

extension UILabel {
    static func createHeroLabel() -> UILabel {
        let heroLabel = UILabel()
        heroLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        heroLabel.numberOfLines = 0

        return heroLabel
    }
}

extension UIVisualEffectView {
    static func createBackgroundBlurView() -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    }
}

final class ShareContactsViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    weak var delegate: ShareContactsViewControllerDelegate?
    var uploadAddressBookImmediately = false
    var backgroundBlurDisabled = false
    var notNowButtonHidden = false
    private(set) var showingAddressBookAccessDeniedViewController = false

    private let notNowButton: UIButton = {
        let notNowButton = UIButton(type: .custom)
        notNowButton.titleLabel?.font = UIFont.smallLightFont
        notNowButton.setTitleColor(UIColor.from(scheme: .buttonFaded, variant: .dark), for: .normal)
        notNowButton.setTitleColor(UIColor.from(scheme: .buttonFaded, variant: .dark).withAlphaComponent(0.2), for: .highlighted)
        notNowButton.setTitle("registration.share_contacts.skip_button.title".localized.uppercased(), for: .normal)
        notNowButton.addTarget(self, action: #selector(shareContactsLater(_:)), for: .touchUpInside)

        return notNowButton
    }()

    private let heroLabel: UILabel = {
        let heroLabel = UILabel.createHeroLabel()
        heroLabel.font = UIFont.largeSemiboldFont
        heroLabel.attributedText = ShareContactsViewController.attributedHeroText

        return heroLabel
    }()

    private let shareContactsButton: Button = {
        let shareContactsButton = Button(style: .full)
        shareContactsButton.setTitle("registration.share_contacts.find_friends_button.title".localized.uppercased(), for: .normal)

        return shareContactsButton
    }()

    private let shareContactsContainerView: UIView = UIView()
    private let addressBookAccessDeniedViewController: PermissionDeniedViewController = {
        let addressBookAccessDeniedViewController = PermissionDeniedViewController.addressBookAccessDeniedViewController()

        return addressBookAccessDeniedViewController
    }()

    private let backgroundBlurView: UIVisualEffectView = UIVisualEffectView.createBackgroundBlurView()

    private static var attributedHeroText: NSAttributedString {
        let title = "registration.share_contacts.hero.title".localized
        let paragraph = "registration.share_contacts.hero.paragraph".localized

        let text = [title, paragraph].joined(separator: "\u{2029}")

        let attributedText = text.withCustomParagraphSpacing()

        attributedText.addAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.from(scheme: .textForeground, variant: .dark),
            NSAttributedString.Key.font: UIFont.largeThinFont
            ], range: (text as NSString).range(of: paragraph))

        return attributedText
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        createConstraints()

        if AddressBookHelper.sharedHelper.isAddressBookAccessDisabled {
            displayContactsAccessDeniedMessage(animated: false)
        }
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(backgroundBlurView)
        backgroundBlurView.isHidden = backgroundBlurDisabled

        view.addSubview(shareContactsContainerView)

        shareContactsContainerView.addSubview(heroLabel)

        notNowButton.isHidden = notNowButtonHidden
        shareContactsContainerView.addSubview(notNowButton)

        shareContactsButton.addTarget(self, action: #selector(shareContacts(_:)), for: .touchUpInside)

        shareContactsContainerView.addSubview(shareContactsButton)

        addToSelf(addressBookAccessDeniedViewController)
        addressBookAccessDeniedViewController.delegate = self
        addressBookAccessDeniedViewController.backgroundBlurDisabled = backgroundBlurDisabled
        addressBookAccessDeniedViewController.view.isHidden = true
    }

    private func createConstraints() {
        [backgroundBlurView,
         shareContactsContainerView,
         addressBookAccessDeniedViewController.view,
         heroLabel,
         shareContactsButton].prepareForLayout()

        let constraints: [NSLayoutConstraint] = [
            shareContactsContainerView.topAnchor.constraint(equalTo: shareContactsContainerView.superview!.topAnchor),
            shareContactsContainerView.bottomAnchor.constraint(equalTo: shareContactsContainerView.superview!.bottomAnchor),
            shareContactsContainerView.leadingAnchor.constraint(equalTo: shareContactsContainerView.superview!.leadingAnchor),
            shareContactsContainerView.trailingAnchor.constraint(equalTo: shareContactsContainerView.superview!.trailingAnchor),

            backgroundBlurView.topAnchor.constraint(equalTo: backgroundBlurView.superview!.topAnchor),
            backgroundBlurView.bottomAnchor.constraint(equalTo: backgroundBlurView.superview!.bottomAnchor),
            backgroundBlurView.leadingAnchor.constraint(equalTo: backgroundBlurView.superview!.leadingAnchor),
            backgroundBlurView.trailingAnchor.constraint(equalTo: backgroundBlurView.superview!.trailingAnchor),

            addressBookAccessDeniedViewController.view.topAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.topAnchor),
            addressBookAccessDeniedViewController.view.bottomAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.bottomAnchor),
            addressBookAccessDeniedViewController.view.leadingAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.leadingAnchor),
            addressBookAccessDeniedViewController.view.trailingAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.trailingAnchor),

            heroLabel.leadingAnchor.constraint(equalTo: heroLabel.superview!.leadingAnchor, constant: 28),
            heroLabel.trailingAnchor.constraint(equalTo: heroLabel.superview!.trailingAnchor, constant: -28),

            shareContactsButton.topAnchor.constraint(equalTo: heroLabel.bottomAnchor, constant: 24),
            shareContactsButton.heightAnchor.constraint(equalToConstant: 40),

            shareContactsButton.bottomAnchor.constraint(equalTo: shareContactsButton.superview!.bottomAnchor, constant: -28),
            shareContactsButton.leadingAnchor.constraint(equalTo: shareContactsButton.superview!.leadingAnchor, constant: 28),
            shareContactsButton.trailingAnchor.constraint(equalTo: shareContactsButton.superview!.trailingAnchor, constant: -28)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions

    @objc
    private func shareContacts(_ sender: Any?) {
        AddressBookHelper.sharedHelper.requestPermissions({ [weak self] success in
            guard let weakSelf = self else { return }
            if success {
                weakSelf.delegate?.shareDidFinish(weakSelf)
            } else {
                weakSelf.displayContactsAccessDeniedMessage(animated: true)
            }
        })
    }

    @objc
    private func shareContactsLater(_ sender: Any?) {
        delegate?.shareDidSkip(self)
    }

    // MARK: - AddressBook Access Denied ViewController

    func displayContactsAccessDeniedMessage(animated: Bool) {
        endEditing()

        showingAddressBookAccessDeniedViewController = true

        if animated {
            UIView.transition(from: shareContactsContainerView,
                              to: addressBookAccessDeniedViewController.view,
                              duration: 0.35,
                              options: [.showHideTransitionViews, .transitionCrossDissolve])
        } else {
            shareContactsContainerView.isHidden = true
            addressBookAccessDeniedViewController.view.isHidden = false
        }
    }
}

extension ShareContactsViewController: PermissionDeniedViewControllerDelegate {
    public func continueWithoutPermission(_ viewController: PermissionDeniedViewController) {
        delegate?.shareDidSkip(self)
    }
}
