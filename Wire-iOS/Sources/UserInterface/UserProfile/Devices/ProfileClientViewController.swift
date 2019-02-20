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
import Cartography


@objcMembers class ProfileClientViewController: UIViewController {

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

    var userClientToken: NSObjectProtocol!
    var resetSessionPending: Bool = false
    var fromConversation: Bool = false

    /// Used for debugging purposes, disabled in public builds
    var deleteDeviceButton: ButtonWithLargerHitArea?

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
        
        self.userClientToken = UserClientChangeInfo.add(observer:self, for:client)
        if userClient.fingerprint == .none {
            ZMUserSession.shared()?.enqueueChanges({ () -> Void in
                self.userClient.fetchFingerprintOrPrekeys()
            })
        }
        self.updateFingerprintLabel()
        self.modalPresentationStyle = .overCurrentContext
        self.title = NSLocalizedString("registration.devices.title", comment:"")

        setupViews()
    }
    
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        self.setupDeleteButton()
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
        backButton.setIcon(.chevronLeft, with: .tiny, for: [])
        backButton.accessibilityIdentifier = "back"
        backButton.addTarget(self, action: #selector(ProfileClientViewController.onBackTapped(_:)), for: .touchUpInside)
        backButton.isHidden = !self.showBackButton
        self.view.addSubview(backButton)
    }
    
    private func setupShowMyDeviceButton() {
        showMyDeviceButton.accessibilityIdentifier = "show my device"
        showMyDeviceButton.setTitle(NSLocalizedString("profile.devices.detail.show_my_device.title", comment: "").uppercased(), for: [])
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
        descriptionTextView.linkTextAttributes = [.foregroundColor : UIColor.accent()]
        
        let descriptionTextFont = FontSpec(.normal, .light).font!

        if let user = self.userClient.user {
            descriptionTextView.attributedText = (String(format: "profile.devices.detail.verify_message".localized, user.displayName) &&
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
        typeLabel.text = self.userClient.deviceClass?.uppercased()
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
            uppercase: false)
        {
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
        verifiedToggleLabel.text = NSLocalizedString("device.verified", comment: "").uppercased()
        verifiedToggleLabel.numberOfLines = 0
        self.contentView.addSubview(verifiedToggleLabel)
    }
    
    private func setupResetButton() {
        resetButton.setTitleColor(UIColor.accent(), for: .normal)
        resetButton.titleLabel?.font = FontSpec(.small, .light).font!
        resetButton.setTitle(NSLocalizedString("profile.devices.detail.reset_session.title", comment: "").uppercased(), for: [])
        resetButton.addTarget(self, action: #selector(ProfileClientViewController.onResetTapped(_:)), for: .touchUpInside)
        resetButton.accessibilityIdentifier = "reset session"
        self.contentView.addSubview(resetButton)
    }
    
    private func setupDeleteButton() {
        guard DeveloperMenuState.developerMenuEnabled() else { return }
        let deleteButton = ButtonWithLargerHitArea()
        deleteButton.setTitleColor(UIColor.accent(), for: .normal)
        deleteButton.titleLabel?.font = FontSpec(.small, .light).font!
        deleteButton.setTitle("DELETE (⚠️ will cause decryption errors later ⚠️)", for: [])
        deleteButton.addTarget(self, action: #selector(ProfileClientViewController.onDeleteDeviceTapped(_:)), for: .touchUpInside)
        self.contentView.addSubview(deleteButton)
        self.deleteDeviceButton = deleteButton
    }
    
    private func createConstraints() {
        constrain(view, contentView, descriptionTextView, separatorLineView) { view, contentView, reviewInvitationTextView, separatorLineView in
            contentView.left == view.left + 16
            contentView.right == view.right - 16
            contentView.bottom == view.bottom - 32
            contentView.top >= view.top + 24
            reviewInvitationTextView.top == contentView.top
            reviewInvitationTextView.left == contentView.left
            reviewInvitationTextView.right == contentView.right
            reviewInvitationTextView.bottom == separatorLineView.top - 24
            separatorLineView.left == contentView.left
            separatorLineView.right == contentView.right
            separatorLineView.height == .hairline
        }

        constrain(contentView, separatorLineView, typeLabel, IDLabel, fullIDLabel) { contentView, separatorLineView, typeLabel, IDLabel, fullIDLabel in
            typeLabel.left == contentView.left
            typeLabel.right == contentView.right
            typeLabel.top == separatorLineView.bottom + 24
            IDLabel.left == contentView.left
            IDLabel.right == contentView.right
            IDLabel.top == typeLabel.bottom - 2
            fullIDLabel.left == contentView.left
            fullIDLabel.right == contentView.right
            fullIDLabel.top == IDLabel.bottom + 24
        }

        constrain(contentView, fullIDLabel, verifiedToggle, verifiedToggleLabel, resetButton) { contentView, fullIDLabel, verifiedToggle, verifiedToggleLabel, resetButton in
            verifiedToggle.left == contentView.left
            verifiedToggle.top == fullIDLabel.bottom + 32
            verifiedToggle.bottom == contentView.bottom - UIScreen.safeArea.bottom
            verifiedToggleLabel.left == verifiedToggle.right + 10
            verifiedToggleLabel.centerY == verifiedToggle.centerY
            resetButton.right == contentView.right
            resetButton.centerY == verifiedToggle.centerY
        }

        let topMargin = UIScreen.safeArea.top > 0 ? UIScreen.safeArea.top : 26.0
        
        constrain(contentView, backButton, view) { contentView, backButton, selfView in
            backButton.left == contentView.left - 8
            backButton.top == selfView.top + topMargin
            backButton.width == 32
            backButton.height == 32
        }

        constrain(contentView, spinner, verifiedToggle, IDLabel) { contentView, spinner, verifiedToggle, IDLabel in
            spinner.centerX == contentView.centerX
            spinner.top >= IDLabel.bottom + 24
            spinner.bottom <= verifiedToggle.bottom - 32
        }

        if let deleteDeviceButton = self.deleteDeviceButton {
            constrain(contentView, descriptionTextView, deleteDeviceButton) { contentView, reviewInvitationTextView, deleteDeviceButton in
                deleteDeviceButton.right == contentView.right
                deleteDeviceButton.left == contentView.left
                deleteDeviceButton.top == reviewInvitationTextView.bottom + 10
            }
        }
    }

    // MARK: Actions

    @objc private func onBackTapped(_ sender: AnyObject) {
        self.presentingViewController?.dismiss(animated: true, completion: .none)
    }

    @objc private func onShowMyDeviceTapped(_ sender: AnyObject) {
        let selfClientController = SettingsClientViewController(userClient: ZMUserSession.shared()!.selfUserClient(),
                                                                fromConversation:self.fromConversation,
                                                                variant: ColorScheme.default.variant)

        let navigationControllerWrapper = selfClientController.wrapInNavigationController()

        navigationControllerWrapper.modalPresentationStyle = .currentContext
        self.present(navigationControllerWrapper, animated: true, completion: .none)
    }

    @objc private func onTrustChanged(_ sender: AnyObject) {
        ZMUserSession.shared()?.enqueueChanges({ [weak self] in
            guard let `self` = self else { return }
            let selfClient = ZMUserSession.shared()!.selfUserClient()
            if(self.verifiedToggle.isOn) {
                selfClient?.trustClient(self.userClient)
            } else {
                selfClient?.ignoreClient(self.userClient)
            }
        }, completionHandler: {
            self.verifiedToggle.isOn = self.userClient.verified
        })
    }

    @objc private func onResetTapped(_ sender: AnyObject) {
        ZMUserSession.shared()?.performChanges {
            self.userClient.resetSession()
        }
        self.resetSessionPending = true
    }
    
    @objc private func onDeleteDeviceTapped(_ sender: AnyObject) {
        let sync = self.userClient.managedObjectContext!.zm_sync!
        sync.performGroupedBlockAndWait {
            let client = try! sync.existingObject(with: self.userClient.objectID) as! UserClient
            client.deleteClientAndEndSession()
            sync.saveOrRollback()
        }
        self.presentingViewController?.dismiss(animated: true, completion: .none)
    }

}


// MARK: - UserClientObserver


extension ProfileClientViewController: UserClientObserver {

    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        self.updateFingerprintLabel()
        
        // This means the fingerprint is acquired
        if self.resetSessionPending && self.userClient.fingerprint != .none {
            let alert = UIAlertController(title: "", message: NSLocalizedString("self.settings.device_details.reset_session.success", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("general.ok", comment: ""), style: .destructive, handler:  nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: .none)
            self.resetSessionPending = false
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
