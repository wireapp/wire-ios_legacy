//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireDataModel
import WireSyncEngine

final class ProfileClientViewController: UIViewController, SpinnerCapable {

    let userClient: UserClient
    let contentView = UIView()
    let backButton = IconButton(style: .circular)
    let showMyDeviceButton = ButtonWithLargerHitArea()
    let descriptionTextView = UITextView()
    let separatorLineView = UIView()
    let typeLabel = UILabel()
    let IDLabel = UILabel()
    let spinner = UIActivityIndicatorView(style: .gray)
    let fullIDLabel = CopyableLabel()
    let verifiedToggle = UISwitch()
    let verifiedToggleLabel = UILabel()
    let resetButton = ButtonWithLargerHitArea()
    var dismissSpinner: SpinnerCompletion?

    var userClientToken: NSObjectProtocol!
    var fromConversation: Bool = false

    /// Used for debugging purposes, disabled in public builds
    var debugMenuButton: ButtonWithLargerHitArea?

    var showBackButton: Bool = true {
        didSet {
            self.backButton.isHidden = !self.showBackButton
        }
    }

    fileprivate let fingerprintSmallFont = FontSpec(.small, .light).font!
    fileprivate let fingerprintSmallBoldFont = FontSpec(.small, .semibold).font!
    fileprivate let fingerprintFont = FontSpec(.normal, .none).font!
    fileprivate let fingerprintBoldFont = FontSpec(.normal, .semibold).font!

    convenience init(client: UserClient, fromConversation: Bool) {
        self.init(client: client)
        self.fromConversation = fromConversation
    }

    required init(client: UserClient) {
        self.userClient = client

        super.init(nibName: nil, bundle: nil)

        self.userClientToken = UserClientChangeInfo.add(observer: self, for: client)
        if userClient.fingerprint == .none {
            ZMUserSession.shared()?.enqueue({ () -> Void in
                self.userClient.fetchFingerprintOrPrekeys()
            })
        }
        self.updateFingerprintLabel()
        self.modalPresentationStyle = .overCurrentContext
        self.title = NSLocalizedString("registration.devices.title", comment: "")

        setupViews()
    }

    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }

    func setupViews() {
        view.backgroundColor = UIColor.from(scheme: .background)

        self.setupContentView()
        self.setupBackButton()
        self.setupShowMyDeviceButton()
        self.setupDescriptionTextView()
        self.setupSeparatorLineView()
        self.setupTypeLabel()
        self.setupIDLabel()
        self.setupFullIDLabel()
        self.setupSpinner()
        self.setupVerifiedToggle()
        self.setupVerifiedToggleLabel()
        self.setupResetButton()
        self.setupDebugMenuButton()
        self.createConstraints()
        self.updateFingerprintLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = ""
    }

    private func setupContentView() {
        self.view.addSubview(contentView)
    }

    private func setupBackButton() {
        backButton.setIcon(.backArrow, size: .tiny, for: [])
        backButton.accessibilityIdentifier = "back"
        backButton.addTarget(self, action: #selector(ProfileClientViewController.onBackTapped(_:)), for: .touchUpInside)
        backButton.isHidden = !self.showBackButton
        self.view.addSubview(backButton)
    }

    private func setupShowMyDeviceButton() {
        showMyDeviceButton.accessibilityIdentifier = "show my device"
        showMyDeviceButton.setTitle("profile.devices.detail.show_my_device.title".localized(uppercased: true), for: [])
        showMyDeviceButton.addTarget(self, action: #selector(ProfileClientViewController.onShowMyDeviceTapped(_:)), for: .touchUpInside)
        showMyDeviceButton.setTitleColor(UIColor.accent(), for: .normal)
        showMyDeviceButton.titleLabel?.font = FontSpec(.small, .light).font!
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: showMyDeviceButton)
    }

    private func setupDescriptionTextView() {
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.isEditable = false
        descriptionTextView.delegate = self
        descriptionTextView.textColor = UIColor.from(scheme: .textForeground)
        descriptionTextView.backgroundColor = UIColor.from(scheme: .textBackground)
        descriptionTextView.linkTextAttributes = [.foregroundColor: UIColor.accent()]

        let descriptionTextFont = FontSpec(.normal, .light).font!

        if let user = self.userClient.user {
            descriptionTextView.attributedText = (String(format: "profile.devices.detail.verify_message".localized, user.name ?? "") &&
                descriptionTextFont &&
                UIColor.from(scheme: .textForeground)) +
                "\n" +
                ("profile.devices.detail.verify_message.link".localized &&
                    [.font: descriptionTextFont, .link: URL.wr_fingerprintHowToVerify])
        }
        self.contentView.addSubview(descriptionTextView)
    }

    private func setupSeparatorLineView() {
        separatorLineView.backgroundColor = UIColor.from(scheme: .separator)
        self.contentView.addSubview(separatorLineView)
    }

    private func setupTypeLabel() {
        typeLabel.text = self.userClient.deviceClass?.localizedDescription.localizedUppercase
        typeLabel.numberOfLines = 1
        typeLabel.font = FontSpec(.small, .semibold).font!
        typeLabel.textColor = UIColor.from(scheme: .textForeground)
        self.contentView.addSubview(typeLabel)
    }

    private func setupIDLabel() {
        IDLabel.numberOfLines = 1
        IDLabel.textColor = UIColor.from(scheme: .textForeground)
        self.contentView.addSubview(IDLabel)
        self.updateIDLabel()
    }

    private func updateIDLabel() {
        let fingerprintSmallMonospaceFont = self.fingerprintSmallFont.monospaced()
        let fingerprintSmallBoldMonospaceFont = self.fingerprintSmallBoldFont.monospaced()

        IDLabel.attributedText = self.userClient.attributedRemoteIdentifier(
            [.font: fingerprintSmallMonospaceFont],
            boldAttributes: [.font: fingerprintSmallBoldMonospaceFont],
            uppercase: true
        )
    }

    private func setupFullIDLabel() {
        fullIDLabel.numberOfLines = 0
        fullIDLabel.textColor = UIColor.from(scheme: .textForeground)
        self.contentView.addSubview(fullIDLabel)
    }

    private func setupSpinner() {
        spinner.hidesWhenStopped = true
        self.contentView.addSubview(spinner)
    }

    fileprivate func updateFingerprintLabel() {
        let fingerprintMonospaceFont = self.fingerprintFont.monospaced()
        let fingerprintBoldMonospaceFont = self.fingerprintBoldFont.monospaced()

        if let attributedFingerprint = self.userClient.fingerprint?.attributedFingerprint(
            attributes: [.font: fingerprintMonospaceFont],
            boldAttributes: [.font: fingerprintBoldMonospaceFont],
            uppercase: false) {
            fullIDLabel.attributedText = attributedFingerprint
            spinner.stopAnimating()
        }
        else {
            fullIDLabel.attributedText = NSAttributedString(string: "")
            spinner.startAnimating()
        }
    }

    private func setupVerifiedToggle() {
        verifiedToggle.onTintColor = UIColor(red: 0, green: 0.588, blue: 0.941, alpha: 1)
        verifiedToggle.isOn = self.userClient.verified
        verifiedToggle.accessibilityLabel = "device verified"
        verifiedToggle.addTarget(self, action: #selector(ProfileClientViewController.onTrustChanged(_:)), for: .valueChanged)
        self.contentView.addSubview(verifiedToggle)
    }

    private func setupVerifiedToggleLabel() {
        verifiedToggleLabel.font = FontSpec(.small, .light).font!
        verifiedToggleLabel.textColor = UIColor.from(scheme: .textForeground)
        verifiedToggleLabel.text = "device.verified".localized(uppercased: true)
        verifiedToggleLabel.numberOfLines = 0
        self.contentView.addSubview(verifiedToggleLabel)
    }

    private func setupResetButton() {
        resetButton.setTitleColor(UIColor.accent(), for: .normal)
        resetButton.titleLabel?.font = FontSpec(.small, .light).font!
        resetButton.setTitle("profile.devices.detail.reset_session.title".localized(uppercased: true), for: [])
        resetButton.addTarget(self, action: #selector(ProfileClientViewController.onResetTapped(_:)), for: .touchUpInside)
        resetButton.accessibilityIdentifier = "reset session"
        self.contentView.addSubview(resetButton)
    }

    private func setupDebugMenuButton() {
        guard Bundle.developerModeEnabled else { return }
        let debugButton = ButtonWithLargerHitArea()
        debugButton.setTitleColor(UIColor.accent(), for: .normal)
        debugButton.titleLabel?.font = FontSpec(.small, .light).font!
        debugButton.setTitle("DEBUG MENU", for: [])
        debugButton.addTarget(self, action: #selector(ProfileClientViewController.onShowDebugActions(_:)), for: .touchUpInside)
        self.contentView.addSubview(debugButton)
        self.debugMenuButton = debugButton
    }

    private func createConstraints() {
        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          contentView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
          contentView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
          contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32),
          contentView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 24),
          reviewInvitationTextView.topAnchor.constraint(equalTo: contentView.topAnchor),
          reviewInvitationTextView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
          reviewInvitationTextView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
          reviewInvitationTextView.bottomAnchor.constraint(equalTo: separatorLineView.topAnchor, constant: -24),
          separatorLineView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
          separatorLineView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
          separatorLineView.heightAnchor.constraint(equalTo: .hairlineAnchor)
        ])

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          typeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
          typeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
          typeLabel.topAnchor.constraint(equalTo: separatorLineView.bottomAnchor, constant: 24),
          IDLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
          IDLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
          IDLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: -2),
          fullIDLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
          fullIDLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
          fullIDLabel.topAnchor.constraint(equalTo: IDLabel.bottomAnchor, constant: 24)
        ])

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          verifiedToggle.leftAnchor.constraint(equalTo: contentView.leftAnchor),
          verifiedToggle.topAnchor.constraint(equalTo: fullIDLabel.bottomAnchor, constant: 32),
          verifiedToggle.bottomAnchor.constraint(equalToConstant: contentView.bottom - UIScreen.safeArea.bottom),
          verifiedToggleLabel.leftAnchor.constraint(equalTo: verifiedToggle.rightAnchor, constant: 10),
          verifiedToggleLabel.centerYAnchor.constraint(equalTo: verifiedToggle.centerYAnchor),
          resetButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),
          resetButton.centerYAnchor.constraint(equalTo: verifiedToggle.centerYAnchor)
        ])

        let topMargin = UIScreen.safeArea.top > 0 ? UIScreen.safeArea.top : 26.0

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          backButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: -8),
          backButton.topAnchor.constraint(equalTo: selfView.topAnchor, constant: topMargin),
          backButton.widthAnchor.constraint(equalToConstant: 32),
          backButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
          spinner.topAnchor.constraint(greaterThanOrEqualTo: IDLabel.bottomAnchor, constant: 24),
          spinner.bottomAnchor.constraint(lessThanOrEqualTo: verifiedToggle.bottomAnchor, constant: -32)
        ])

        if let debugMenuButton = self.debugMenuButton {
            [<#views#>].prepareForLayout()
            NSLayoutConstraint.activate([
              debugMenuButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),
              debugMenuButton.leftAnchor.constraint(equalTo: contentView.leftAnchor),
              debugMenuButton.topAnchor.constraint(equalTo: reviewInvitationTextView.bottomAnchor, constant: 10)
            ])
        }
    }

    // MARK: Actions

    @objc private func onBackTapped(_ sender: AnyObject) {
        self.presentingViewController?.dismiss(animated: true, completion: .none)
    }

    @objc private func onShowMyDeviceTapped(_ sender: AnyObject) {
        let selfClientController = SettingsClientViewController(userClient: ZMUserSession.shared()!.selfUserClient!,
                                                                fromConversation: self.fromConversation,
                                                                variant: ColorScheme.default.variant)

        let navigationControllerWrapper = selfClientController.wrapInNavigationController()

        navigationControllerWrapper.modalPresentationStyle = .currentContext
        self.present(navigationControllerWrapper, animated: true, completion: .none)
    }

    @objc private func onTrustChanged(_ sender: AnyObject) {
        ZMUserSession.shared()?.enqueue({ [weak self] in
            guard let `self` = self else { return }
            let selfClient = ZMUserSession.shared()!.selfUserClient
            if self.verifiedToggle.isOn {
                selfClient?.trustClient(self.userClient)
            } else {
                selfClient?.ignoreClient(self.userClient)
            }
        }, completionHandler: {
            self.verifiedToggle.isOn = self.userClient.verified
        })
    }

    @objc private func onResetTapped(_ sender: AnyObject) {
        ZMUserSession.shared()?.perform {
            self.userClient.resetSession()
        }
        isLoadingViewVisible = true
    }

    @objc private func onShowDebugActions(_ sender: AnyObject) {
        let actionSheet = UIAlertController(title: "Debug actions",
                                            message: "⚠️ will cause decryption errors ⚠️",
                                            preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Delete Session", style: .default, handler: { [weak self] (_) in
            self?.onDeleteDeviceTapped()
        }))

        actionSheet.addAction(UIAlertAction(title: "Corrupt Session", style: .default, handler: { [weak self] (_) in
            self?.onCorruptSessionTapped()
        }))

        actionSheet.addAction(.cancel())

        present(actionSheet, animated: true)
    }

    @objc private func onDeleteDeviceTapped() {
        let sync = self.userClient.managedObjectContext!.zm_sync!
        sync.performGroupedBlockAndWait {
            let client = try! sync.existingObject(with: self.userClient.objectID) as! UserClient
            client.deleteClientAndEndSession()
            sync.saveOrRollback()
        }
        self.presentingViewController?.dismiss(animated: true, completion: .none)
    }

    @objc private func onCorruptSessionTapped() {
        let sync = self.userClient.managedObjectContext!.zm_sync!
        let selfClientID = ZMUser.selfUser()?.selfClient()?.objectID
        sync.performGroupedBlockAndWait {
            let client = try! sync.existingObject(with: self.userClient.objectID) as! UserClient
            let selfClient = try! sync.existingObject(with: selfClientID!) as! UserClient

            _ = selfClient.establishSessionWithClient(client, usingPreKey: "pQABAQACoQBYIBi1nXQxPf9hpIp1K1tBOj/tlBuERZHfTMOYEW38Ny7PA6EAoQBYIAZbZQ9KtsLVc9VpHkPjYy2+Bmz95fyR0MGKNUqtUUi1BPY=")
            sync.saveOrRollback()
        }
        self.presentingViewController?.dismiss(animated: true, completion: .none)
    }

}

// MARK: - UserClientObserver

extension ProfileClientViewController: UserClientObserver {

    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {

        if changeInfo.fingerprintChanged {
            self.updateFingerprintLabel()
        }

        if changeInfo.sessionHasBeenReset {
            let alert = UIAlertController(title: "", message: NSLocalizedString("self.settings.device_details.reset_session.success", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("general.ok", comment: ""), style: .destructive, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: .none)
            isLoadingViewVisible = false
        }
    }

}

// MARK: - UITextViewDelegate

extension ProfileClientViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard url == .wr_fingerprintHowToVerify else { return false }
        url.openInApp(above: self)
        return false
    }
}
