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
import WireSyncEngine
import WireCommonComponents

final class ProfileClientViewController: UIViewController, SpinnerCapable {

    private let userClient: UserClient
    private let contentView = UIView()
    private let backButton = IconButton(style: .circular)
    private let showMyDeviceButton = ButtonWithLargerHitArea()
    private let descriptionTextView = UITextView()
    private let separatorLineView = UIView()
    private let typeLabel = UILabel()
    private let IDLabel = UILabel()
    let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
    private let fullIDLabel = CopyableLabel()
    private let verifiedToggle = Switch(style: .default)
    private let verifiedToggleLabel = UILabel()
    private let resetButton = ButtonWithLargerHitArea()

    var dismissSpinner: SpinnerCompletion?

    private var userClientToken: NSObjectProtocol!
    var fromConversation: Bool = false

    /// Used for debugging purposes, disabled in public builds
    private var debugMenuButton: ButtonWithLargerHitArea?

    var showBackButton: Bool = true {
        didSet {
            backButton.isHidden = !showBackButton
        }
    }

    private let fingerprintSmallFont = FontSpec(.small, .light).font!
    private let fingerprintSmallBoldFont = FontSpec(.small, .semibold).font!
    private let fingerprintFont = FontSpec(.normal, .none).font!
    private let fingerprintBoldFont = FontSpec(.normal, .semibold).font!

    convenience init(client: UserClient,
                     fromConversation: Bool) {
        self.init(client: client)
        self.fromConversation = fromConversation
    }

    required init(client: UserClient) {
        userClient = client

        super.init(nibName: nil, bundle: nil)

        userClientToken = UserClientChangeInfo.add(observer: self, for: client)
        if userClient.fingerprint == .none {
            ZMUserSession.shared()?.enqueue({ () -> Void in
                self.userClient.fetchFingerprintOrPrekeys()
            })
        }
        updateFingerprintLabel()
        modalPresentationStyle = .overCurrentContext
        title = L10n.Localizable.Registration.Devices.title

        setupViews()
    }

    @available(*, unavailable)
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }

    private func setupViews() {
        view.backgroundColor = UIColor.from(scheme: .background)

        setupContentView()
        setupBackButton()
        setupShowMyDeviceButton()
        setupDescriptionTextView()
        setupSeparatorLineView()
        setupTypeLabel()
        setupIDLabel()
        setupFullIDLabel()
        setupSpinner()
        setupVerifiedToggle()
        setupVerifiedToggleLabel()
        setupResetButton()
        setupDebugMenuButton()
        createConstraints()
        updateFingerprintLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = ""
    }

    private func setupContentView() {
        view.addSubview(contentView)
    }

    private func setupBackButton() {
        backButton.setIcon(.backArrow, size: .tiny, for: [])
        backButton.accessibilityIdentifier = "back"
        backButton.addTarget(self, action: #selector(ProfileClientViewController.onBackTapped(_:)), for: .touchUpInside)
        backButton.isHidden = !showBackButton
        view.addSubview(backButton)
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

        if let user = userClient.user {
            descriptionTextView.attributedText = (String(format: "profile.devices.detail.verify_message".localized, user.name ?? "") &&
                                                    descriptionTextFont &&
                                                    UIColor.from(scheme: .textForeground)) +
                "\n" +
                ("profile.devices.detail.verify_message.link".localized &&
                    [.font: descriptionTextFont, .link: URL.wr_fingerprintHowToVerify])
        }
        contentView.addSubview(descriptionTextView)
    }

    private func setupSeparatorLineView() {
        separatorLineView.backgroundColor = UIColor.from(scheme: .separator)
        contentView.addSubview(separatorLineView)
    }

    private func setupTypeLabel() {
        typeLabel.text = userClient.deviceClass?.localizedDescription.localizedUppercase
        typeLabel.numberOfLines = 1
        typeLabel.font = FontSpec(.small, .semibold).font!
        typeLabel.textColor = UIColor.from(scheme: .textForeground)
        contentView.addSubview(typeLabel)
    }

    private func setupIDLabel() {
        IDLabel.numberOfLines = 1
        IDLabel.textColor = UIColor.from(scheme: .textForeground)
        contentView.addSubview(IDLabel)
        updateIDLabel()
    }

    private func updateIDLabel() {
        let fingerprintSmallMonospaceFont = fingerprintSmallFont.monospaced()
        let fingerprintSmallBoldMonospaceFont = fingerprintSmallBoldFont.monospaced()

        IDLabel.attributedText = userClient.attributedRemoteIdentifier(
            [.font: fingerprintSmallMonospaceFont],
            boldAttributes: [.font: fingerprintSmallBoldMonospaceFont],
            uppercase: true
        )
    }

    private func setupFullIDLabel() {
        fullIDLabel.numberOfLines = 0
        fullIDLabel.textColor = UIColor.from(scheme: .textForeground)
        contentView.addSubview(fullIDLabel)
    }

    private func setupSpinner() {
        spinner.hidesWhenStopped = true
        contentView.addSubview(spinner)
    }

    private func updateFingerprintLabel() {
        let fingerprintMonospaceFont = fingerprintFont.monospaced()
        let fingerprintBoldMonospaceFont = fingerprintBoldFont.monospaced()

        if let attributedFingerprint = userClient.fingerprint?.attributedFingerprint(
            attributes: [.font: fingerprintMonospaceFont],
            boldAttributes: [.font: fingerprintBoldMonospaceFont],
            uppercase: false) {
            fullIDLabel.attributedText = attributedFingerprint
            spinner.stopAnimating()
        } else {
            fullIDLabel.attributedText = NSAttributedString(string: "")
            spinner.startAnimating()
        }
    }

    private func setupVerifiedToggle() {
        verifiedToggle.isOn = userClient.verified
        verifiedToggle.accessibilityLabel = "device verified"
        verifiedToggle.addTarget(self, action: #selector(ProfileClientViewController.onTrustChanged(_:)), for: .valueChanged)
        contentView.addSubview(verifiedToggle)
    }

    private func setupVerifiedToggleLabel() {
        verifiedToggleLabel.font = FontSpec(.small, .light).font!
        verifiedToggleLabel.textColor = UIColor.from(scheme: .textForeground)
        verifiedToggleLabel.text = "device.verified".localized(uppercased: true)
        verifiedToggleLabel.numberOfLines = 0
        contentView.addSubview(verifiedToggleLabel)
    }

    private func setupResetButton() {
        resetButton.setTitleColor(UIColor.accent(), for: .normal)
        resetButton.titleLabel?.font = FontSpec(.small, .light).font!
        resetButton.setTitle("profile.devices.detail.reset_session.title".localized(uppercased: true), for: [])
        resetButton.addTarget(self, action: #selector(ProfileClientViewController.onResetTapped(_:)), for: .touchUpInside)
        resetButton.accessibilityIdentifier = "reset session"
        contentView.addSubview(resetButton)
    }

    private func setupDebugMenuButton() {
        guard Bundle.developerModeEnabled else { return }
        let debugButton = ButtonWithLargerHitArea()
        debugButton.setTitleColor(UIColor.accent(), for: .normal)
        debugButton.titleLabel?.font = FontSpec(.small, .light).font!
        debugButton.setTitle("DEBUG MENU", for: [])
        debugButton.addTarget(self, action: #selector(ProfileClientViewController.onShowDebugActions(_:)), for: .touchUpInside)
        contentView.addSubview(debugButton)
        debugMenuButton = debugButton
    }

    private func createConstraints() {
        let topMargin = UIScreen.safeArea.top > 0 ? UIScreen.safeArea.top : 26.0

        [contentView,
         descriptionTextView,
         separatorLineView,
         typeLabel,
         fullIDLabel,
         verifiedToggle,
         verifiedToggleLabel,
         resetButton,
         backButton,
         spinner,
         IDLabel].prepareForLayout()

        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32),
            contentView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 24),
            descriptionTextView.topAnchor.constraint(equalTo: contentView.topAnchor),
            descriptionTextView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            descriptionTextView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            descriptionTextView.bottomAnchor.constraint(equalTo: separatorLineView.topAnchor, constant: -24),
            separatorLineView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            separatorLineView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            separatorLineView.heightAnchor.constraint(equalToConstant: .hairline),

            typeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            typeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            typeLabel.topAnchor.constraint(equalTo: separatorLineView.bottomAnchor, constant: 24),
            IDLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            IDLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            IDLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: -2),
            fullIDLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            fullIDLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            fullIDLabel.topAnchor.constraint(equalTo: IDLabel.bottomAnchor, constant: 24),

            verifiedToggle.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            verifiedToggle.topAnchor.constraint(equalTo: fullIDLabel.bottomAnchor, constant: 32),
            verifiedToggle.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UIScreen.safeArea.bottom),
            verifiedToggleLabel.leftAnchor.constraint(equalTo: verifiedToggle.rightAnchor, constant: 10),
            verifiedToggleLabel.centerYAnchor.constraint(equalTo: verifiedToggle.centerYAnchor),
            resetButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            resetButton.centerYAnchor.constraint(equalTo: verifiedToggle.centerYAnchor),

            backButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: -8),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: topMargin),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.topAnchor.constraint(greaterThanOrEqualTo: IDLabel.bottomAnchor, constant: 24),
            spinner.bottomAnchor.constraint(lessThanOrEqualTo: verifiedToggle.bottomAnchor, constant: -32)
        ])

        if let debugMenuButton = debugMenuButton {
            [contentView, descriptionTextView, debugMenuButton].prepareForLayout()
            NSLayoutConstraint.activate([
                debugMenuButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                debugMenuButton.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                debugMenuButton.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 10)
            ])
        }
    }

    // MARK: Actions

    @objc private func onBackTapped(_ sender: AnyObject) {
        presentingViewController?.dismiss(animated: true, completion: .none)
    }

    @objc private func onShowMyDeviceTapped(_ sender: AnyObject) {
        let selfClientController = SettingsClientViewController(userClient: ZMUserSession.shared()!.selfUserClient!,
                                                                fromConversation: fromConversation,
                                                                variant: ColorScheme.default.variant)

        let navigationControllerWrapper = selfClientController.wrapInNavigationController(setBackgroundColor: true)

        navigationControllerWrapper.modalPresentationStyle = .currentContext
        present(navigationControllerWrapper, animated: true, completion: .none)
    }

    @objc
    private func onTrustChanged(_ sender: AnyObject) {
        ZMUserSession.shared()?.enqueue({ [weak self] in
            guard let weakSelf = self else { return }
            let selfClient = ZMUserSession.shared()!.selfUserClient
            if weakSelf.verifiedToggle.isOn {
                selfClient?.trustClient(weakSelf.userClient)
            } else {
                selfClient?.ignoreClient(weakSelf.userClient)
            }
        }, completionHandler: { [weak self] in
            guard let weakSelf = self else { return }

            weakSelf.verifiedToggle.isOn = weakSelf.userClient.verified
        })
    }

    @objc private func onResetTapped(_ sender: AnyObject) {
        ZMUserSession.shared()?.perform { [weak self] in
            self?.userClient.resetSession()
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

    @objc
    private func onDeleteDeviceTapped() {
        let sync = userClient.managedObjectContext!.zm_sync!
        sync.performGroupedBlockAndWait { [weak self] in
            guard let weakSelf = self else { return }

            let client = try! sync.existingObject(with: weakSelf.userClient.objectID) as! UserClient
            client.deleteClientAndEndSession()
            sync.saveOrRollback()
        }
        presentingViewController?.dismiss(animated: true, completion: .none)
    }

    @objc
    private func onCorruptSessionTapped() {
        let sync = userClient.managedObjectContext!.zm_sync!
        let selfClientID = ZMUser.selfUser()?.selfClient()?.objectID
        sync.performGroupedBlockAndWait { [weak self] in
            guard let weakSelf = self else { return }

            let client = try! sync.existingObject(with: weakSelf.userClient.objectID) as! UserClient
            let selfClient = try! sync.existingObject(with: selfClientID!) as! UserClient

            _ = selfClient.establishSessionWithClient(client, usingPreKey: "pQABAQACoQBYIBi1nXQxPf9hpIp1K1tBOj/tlBuERZHfTMOYEW38Ny7PA6EAoQBYIAZbZQ9KtsLVc9VpHkPjYy2+Bmz95fyR0MGKNUqtUUi1BPY=")
            sync.saveOrRollback()
        }
        presentingViewController?.dismiss(animated: true, completion: .none)
    }

}

// MARK: - UserClientObserver

extension ProfileClientViewController: UserClientObserver {

    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {

        if changeInfo.fingerprintChanged {
            updateFingerprintLabel()
        }

        if changeInfo.sessionHasBeenReset {
            let alert = UIAlertController(title: "", message: NSLocalizedString("self.settings.device_details.reset_session.success", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("general.ok", comment: ""), style: .destructive, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: .none)
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
