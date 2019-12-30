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

protocol ShareContactsViewControllerDelegate: NSObjectProtocol {
    func shareContactsViewControllerDidSkip(_ viewController: UIViewController)
    func shareContactsViewControllerDidFinish(_ viewController: UIViewController)
}

final class ShareContactsViewController: UIViewController {
    weak var delegate: ShareContactsViewControllerDelegate?
    var uploadAddressBookImmediately = false
    var backgroundBlurDisabled = false
    var notNowButtonHidden = false
    var monochromeStyle = false
    private(set) var showingAddressBookAccessDeniedViewController = false
    
    private var notNowButton: UIButton?
    private var heroLabel: UILabel?
    private var shareContactsButton: Button!
    private var shareContactsContainerView: UIView!
    private var addressBookAccessDeniedViewController: PermissionDeniedViewController!
    private var backgroundBlurView: UIVisualEffectView!
    private var showingAddressBookAccessDeniedViewController = false
    
    private func createHeroLabel() {
        heroLabel = UILabel()
        heroLabel.font = UIFont.largeSemiboldFont
        heroLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: ColorSchemeVariantDark)
        heroLabel.attributedText = attributedHeroText()
        heroLabel.numberOfLines = 0
        
        shareContactsContainerView.addSubview(heroLabel)
    }
    
    private func attributedHeroText() -> NSAttributedString? {
        let title = NSLocalizedString("registration.share_contacts.hero.title", comment: "")
        let paragraph = NSLocalizedString("registration.share_contacts.hero.paragraph", comment: "")
        
        let text = [title, paragraph].joined(separator: "\u{2029}")
        
        var paragraphStyle = NSParagraphStyle.default as? NSMutableParagraphStyle
        paragraphStyle?.paragraphSpacing = 10
        
        var attributedText: NSMutableAttributedString? = nil
        if let paragraphStyle = paragraphStyle {
            attributedText = NSMutableAttributedString(string: text, attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle
                ])
        }
        attributedText?.addAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: ColorSchemeVariantDark),
            NSAttributedString.Key.font: UIFont.largeThinFont
            ], range: (text as NSString).range(of: paragraph))
        
        if let attributedText = attributedText {
            return NSAttributedString(attributedString: attributedText)
        }
        return nil
    }

    private func createShareContactsButton() {
        shareContactsButton = Button(style: monochromeStyle ? ButtonStyleFullMonochrome : ButtonStyleFull)
        shareContactsButton.setTitle(NSLocalizedString("registration.share_contacts.find_friends_button.title", comment: "").uppercasedWithCurrentLocale(), for: .normal)
        shareContactsButton.addTarget(self, action: #selector(shareContacts(_:)), for: .touchUpInside)
        
        shareContactsContainerView.addSubview(shareContactsButton)
    }
    
    private func createNotNowButton() {
        notNowButton = UIButton(type: .custom)
        notNowButton.titleLabel?.font = UIFont.smallLightFont
        notNowButton.setTitleColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorButtonFaded, variant: ColorSchemeVariantDark), for: .normal)
        notNowButton.setTitleColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorButtonFaded, variant: ColorSchemeVariantDark).withAlphaComponent(0.2), for: .highlighted)
        notNowButton.setTitle(NSLocalizedString("registration.share_contacts.skip_button.title", comment: "").uppercasedWithCurrentLocale(), for: .normal)
        notNowButton.addTarget(self, action: #selector(shareContactsLater(_:)), for: .touchUpInside)
        notNowButton.hidden = notNowButtonHidden
        
        shareContactsContainerView.addSubview(notNowButton)
    }
    
    private func createAddressBookAccessDeniedViewController() {
        addressBookAccessDeniedViewController = PermissionDeniedViewController.addressBookAccessDeniedViewController(withMonochromeStyle: monochromeStyle)
        addressBookAccessDeniedViewController.delegate = self
        addressBookAccessDeniedViewController.backgroundBlurDisabled = backgroundBlurDisabled
        
        addChild(addressBookAccessDeniedViewController)
        view.addSubview(addressBookAccessDeniedViewController.view)
        addressBookAccessDeniedViewController.didMove(toParent: self)
        addressBookAccessDeniedViewController.view.hidden = true
    }
    
    func setBackgroundBlurDisabled(_ backgroundBlurDisabled: Bool) {
        self.backgroundBlurDisabled = backgroundBlurDisabled
        backgroundBlurView.hidden = self.backgroundBlurDisabled
    }
    
    func setNotNowButtonHidden(_ notNowButtonHidden: Bool) {
        self.notNowButtonHidden = notNowButtonHidden
        notNowButton.hidden = self.notNowButtonHidden
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        let blurEffect = UIBlurEffect(style: .dark)
        backgroundBlurView = UIVisualEffectView(effect: blurEffect)
        view.addSubview(backgroundBlurView)
        backgroundBlurView.isHidden = backgroundBlurDisabled
        
        shareContactsContainerView = UIView()
        view.addSubview(shareContactsContainerView)
        
        createHeroLabel()
        createNotNowButton()
        createShareContactsButton()
        createAddressBookAccessDeniedViewController()
        createConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if AddressBookHelper.sharedHelper.isAddressBookAccessDisabled {
            displayContactsAccessDeniedMessage(animated: false)
        }
    }
    
    // MARK: - Actions
    @objc
    func shareContacts(_ sender: Any?) {
        AddressBookHelper.sharedHelper.requestPermissions({ [weak self] success in
            guard let weakSelf = self else { return }
            if success {
                AddressBookHelper.sharedHelper.startRemoteSearch( weakSelf.uploadAddressBookImmediately)
                weakSelf.delegate?.shareContactsViewControllerDidFinish(weakSelf)
            } else {
                weakSelf.displayContactsAccessDeniedMessage(animated: true)
            }
        })
    }
    
    @objc
    func shareContactsLater(_ sender: Any?) {
        AddressBookHelper.sharedHelper.addressBookSearchWasPostponed = true
        delegate?.shareContactsViewControllerDidSkip(self)
    }

    // MARK: - UIApplication notifications
    @objc
    func applicationDidBecomeActive(_ notification: Notification) {
        if AddressBookHelper.sharedHelper.isAddressBookAccessGranted {
            AddressBookHelper.sharedHelper.startRemoteSearch(true)
            delegate?.shareContactsViewControllerDidFinish(self)
        }
    }

    // MARK: - Constraints
    func createConstraints() {
        [backgroundBlurView,
         shareContactsContainerView,
         addressBookAccessDeniedViewController.view,
         heroLabel,
         shareContactsButton].forEach(){ $0.translatesAutoresizingMaskIntoConstraints = false }

        let constraints: [NSLayoutConstraint] = [shareContactsContainerView.topAnchor.constraint(equalTo: shareContactsContainerView.superview!.topAnchor),
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

    // MARK: - AddressBook Access Denied ViewController

    @objc(displayContactsAccessDeniedMessageAnimated:)
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
        AddressBookHelper.sharedHelper.addressBookSearchWasPostponed = true
        delegate?.shareContactsViewControllerDidSkip(self)
    }
}
