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
import CocoaLumberjackSwift
import Classy


class ProfileClientViewController: UIViewController {

    let userClient: UserClient
    let contentView = UIView()
    let backButton = IconButton.iconButtonCircular()
    let showMyDeviceButton = ButtonWithLargerHitArea()
    let descriptionTextView = UITextView()
    let separatorLineView = UIView()
    let typeLabel = UILabel()
    let IDLabel = UILabel()
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    let fullIDLabel = CopyableLabel()
    let verifiedToggle = UISwitch()
    let verifiedToggleLabel = UILabel()
    let resetButton = ButtonWithLargerHitArea()

    var userClientToken: NSObjectProtocol!
    var resetSessionPending: Bool = false
    var descriptionTextFont: UIFont?
    var fromConversation: Bool = false

    /// Used for debugging purposes, disabled in public builds
    var deleteDeviceButton: ButtonWithLargerHitArea?

    var showBackButton: Bool = true {
        didSet {
            self.backButton.isHidden = !self.showBackButton
        }
    }
    
    var fingerprintSmallFont: UIFont? {
        didSet {
            self.updateIDLabel()
        }
    }
    
    var fingerprintSmallBoldFont: UIFont? {
        didSet {
            self.updateIDLabel()
        }
    }

    var fingerprintFont: UIFont? {
        didSet {
            self.updateFingerprintLabel()
        }
    }
    
    var fingerprintBoldFont: UIFont? {
        didSet {
            self.updateFingerprintLabel()
        }
    }

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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        CASStyler.default().styleItem(self)

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
    
    private func setupContentView() {
        self.view.addSubview(contentView)
    }

    private func setupBackButton() {
        backButton.setIcon(.chevronLeft, with: .tiny, for: UIControlState())
        backButton.accessibilityIdentifier = "back"
        backButton.addTarget(self, action: #selector(ProfileClientViewController.onBackTapped(_:)), for: .touchUpInside)
        backButton.isHidden = !self.showBackButton
        self.view.addSubview(backButton)
    }
    
    private func setupShowMyDeviceButton() {
        showMyDeviceButton.accessibilityIdentifier = "show my device"
        showMyDeviceButton.setTitle(NSLocalizedString("profile.devices.detail.show_my_device.title", comment: "").uppercased(), for: UIControlState())
        showMyDeviceButton.addTarget(self, action: #selector(ProfileClientViewController.onShowMyDeviceTapped(_:)), for: .touchUpInside)
        self.view.addSubview(showMyDeviceButton)
    }
    
    private func setupDescriptionTextView() {
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.isEditable = false
        descriptionTextView.delegate = self
        if let user = self.userClient.user,
            let descriptionTextFont = self.descriptionTextFont {
            descriptionTextView.attributedText = (String(format: "profile.devices.detail.verify_message".localized, user.displayName) && descriptionTextFont) + "\n" +
                ("profile.devices.detail.verify_message.link".localized && [NSFontAttributeName: descriptionTextFont, NSLinkAttributeName: NSURL.wr_fingerprintHowToVerify()])
        }
        self.contentView.addSubview(descriptionTextView)
    }
    
    private func setupSeparatorLineView() {
        self.contentView.addSubview(separatorLineView)
    }
    
    private func setupTypeLabel() {
        typeLabel.text = self.userClient.deviceClass?.uppercased()
        typeLabel.numberOfLines = 1
        self.contentView.addSubview(typeLabel)
    }
    
    private func setupIDLabel() {
        IDLabel.numberOfLines = 1
        self.contentView.addSubview(IDLabel)
        self.updateIDLabel()
    }
    
    private func updateIDLabel() {
        if let fingerprintSmallMonospaceFont = self.fingerprintSmallFont?.monospaced(),
            let fingerprintSmallBoldMonospaceFont = self.fingerprintSmallBoldFont?.monospaced() {
                IDLabel.attributedText = self.userClient.attributedRemoteIdentifier(
                    [NSFontAttributeName: fingerprintSmallMonospaceFont],
                    boldAttributes: [NSFontAttributeName: fingerprintSmallBoldMonospaceFont],
                    uppercase: true
                )
        }
    }

    private func setupFullIDLabel() {
        fullIDLabel.numberOfLines = 0
        self.contentView.addSubview(fullIDLabel)
    }
    
    private func setupSpinner() {
        spinner.hidesWhenStopped = true
        self.contentView.addSubview(spinner)
    }

    fileprivate func updateFingerprintLabel() {
        if let fingerprintMonospaceFont = self.fingerprintFont?.monospaced(),
            let fingerprintBoldMonospaceFont = self.fingerprintBoldFont?.monospaced(),
            let attributedFingerprint = self.userClient.fingerprint?.attributedFingerprint(
                attributes: [NSFontAttributeName: fingerprintMonospaceFont],
                boldAttributes: [NSFontAttributeName: fingerprintBoldMonospaceFont],
                uppercase: false
            )
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
        verifiedToggle.isOn = self.userClient.verified
        verifiedToggle.accessibilityLabel = "device verified"
        verifiedToggle.addTarget(self, action: #selector(ProfileClientViewController.onTrustChanged(_:)), for: .valueChanged)
        self.contentView.addSubview(verifiedToggle)
    }
    
    private func setupVerifiedToggleLabel() {
        verifiedToggleLabel.text = NSLocalizedString("device.verified", comment: "").uppercased()
        verifiedToggleLabel.numberOfLines = 0
        self.contentView.addSubview(verifiedToggleLabel)
    }
    
    private func setupResetButton() {
        resetButton.setTitle(NSLocalizedString("profile.devices.detail.reset_session.title", comment: "").uppercased(), for: UIControlState())
        resetButton.addTarget(self, action: #selector(ProfileClientViewController.onResetTapped(_:)), for: .touchUpInside)
        resetButton.accessibilityIdentifier = "reset session"
        self.contentView.addSubview(resetButton)
    }
    
    private func setupDeleteButton() {
        guard DeveloperMenuState.developerMenuEnabled() else { return }
        let deleteButton = ButtonWithLargerHitArea()
        deleteButton.setTitle("DELETE (⚠️ will cause decryption errors later ⚠️)", for: UIControlState())
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
            verifiedToggle.bottom == contentView.bottom
            verifiedToggleLabel.left == verifiedToggle.right + 10
            verifiedToggleLabel.centerY == verifiedToggle.centerY
            resetButton.right == contentView.right
            resetButton.centerY == verifiedToggle.centerY
        }

        constrain(contentView, backButton, showMyDeviceButton, view) { contentView, backButton, showMyDeviceButton, selfView in
            backButton.left == contentView.left - 8
            backButton.top == selfView.top + 26
            backButton.width == 32
            backButton.height == 32
            showMyDeviceButton.centerY == backButton.centerY
            showMyDeviceButton.right == contentView.right
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
        let selfClientController = SettingsClientViewController(userClient: ZMUserSession.shared()!.selfUserClient(), fromConversation:self.fromConversation)
        let navigationControllerWrapper = UINavigationController(rootViewController: selfClientController)
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
            
            let verificationType: DeviceVerificationType = self.verifiedToggle.isOn ? .verified : .unverified
            Analytics.shared()?.tagChange(verificationType, deviceOwner: .other)
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

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL == NSURL.wr_fingerprintHowToVerify() as URL {
            UIApplication.shared.openURL(URL)
            return true
        }
        else {
            return false
        }
    }

}
