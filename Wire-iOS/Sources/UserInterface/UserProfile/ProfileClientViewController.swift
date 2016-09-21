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

class ProfileClientViewController: UIViewController, UserClientObserver, UITextViewDelegate {
    let userClient: UserClient!
    var userClientToken: UserClientObserverOpaqueToken!
    var resetSessionPending: Bool = false
    
    var contentView: UIView!
    var backButton: IconButton!
    var showMyDeviceButton: ButtonWithLargerHitArea!
    var reviewInvitationTextView: UITextView!
    var reviewInvitationTextFont: UIFont?
    var separatorLineView: UIView!
    var typeLabel: UILabel!
    var IDLabel: UILabel!
    var spinner: UIActivityIndicatorView!
    var fullIDLabel: UILabel!
    var verifiedToggle: UISwitch!
    var verifiedToggleLabel: UILabel!
    var resetButton: ButtonWithLargerHitArea!
    var showBackButton: Bool = true {
        didSet {
            self.backButton?.isHidden = !self.showBackButton
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

    required init(client: UserClient) {
        self.userClient = client

        super.init(nibName: nil, bundle: nil)
        
        self.userClientToken = userClient.addObserver(self)
        if userClient.fingerprint == .None {
            ZMUserSession.sharedSession().enqueueChanges({ () -> Void in                
                self.userClient.markForFetchingPreKeys()
            })
        }
        self.updateFingerprintLabel()
        self.modalPresentationStyle = .OverCurrentContext
        self.title = NSLocalizedString("registration.devices.title", comment:"")
    }
    
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    deinit {
        UserClient.removeObserverForUserClientToken(self.userClientToken)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        CASStyler.default().styleItem(self)
        
        self.createContentView()
        self.createBackButton()
        self.createShowMyDeviceButton()
        self.createReviewInvitationTextView()
        self.createSeparatorLineView()
        self.createTypeLabel()
        self.createIDLabel()
        self.createFullIDLabel()
        self.createSpinner()
        self.createVerifiedToggle()
        self.createVerifiedToggleLabel()
        self.createResetButton()
        self.createConstraints()
        self.updateFingerprintLabel()
    }
    
    func createContentView() {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(contentView)
        self.contentView = contentView
    }

    func createBackButton() {
        let backButton = IconButton.iconButtonCircular()
        backButton?.setIcon(.chevronLeft, with: .tiny, for: UIControlState())
        backButton?.addTarget(self, action: #selector(ProfileClientViewController.onBackTapped(_:)), for: .touchUpInside)
        backButton?.translatesAutoresizingMaskIntoConstraints = false
        backButton?.isHidden = !self.showBackButton
        self.backButton = backButton
        self.view.addSubview(backButton!)
    }
    
    func createShowMyDeviceButton() {
        let showMyDeviceButton = ButtonWithLargerHitArea()
        showMyDeviceButton.translatesAutoresizingMaskIntoConstraints = false
        showMyDeviceButton.setTitle(NSLocalizedString("profile.devices.detail.show_my_device.title", comment: "").uppercased(), for: UIControlState())
        showMyDeviceButton.addTarget(self, action: #selector(ProfileClientViewController.onShowMyDeviceTapped(_:)), for: .touchUpInside)
        self.view.addSubview(showMyDeviceButton)
        self.showMyDeviceButton = showMyDeviceButton
    }
    
    func createReviewInvitationTextView() {
        let reviewInvitationTextView = UITextView()
        reviewInvitationTextView.isScrollEnabled = false
        reviewInvitationTextView.isEditable = false
        reviewInvitationTextView.delegate = self
        reviewInvitationTextView.translatesAutoresizingMaskIntoConstraints = false
        if let user = self.userClient.user,
            let reviewInvitationTextFont = self.reviewInvitationTextFont {
            reviewInvitationTextView.attributedText = (String(format: "profile.devices.detail.verify_message".localized, user.displayName) && reviewInvitationTextFont) + "\n" +
                ("profile.devices.detail.verify_message.link".localized && [NSFontAttributeName: reviewInvitationTextFont, NSLinkAttributeName: URL.wr_fingerprintHowToVerifyURL()])
        }
        self.contentView.addSubview(reviewInvitationTextView)
        self.reviewInvitationTextView = reviewInvitationTextView
    }
    
    func createSeparatorLineView() {
        let separatorLineView = UIView()
        self.contentView.addSubview(separatorLineView)
        self.separatorLineView = separatorLineView
    }
    
    func createTypeLabel() {
        let typeLabel = UILabel()
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.text = self.userClient.deviceClass?.uppercaseString
        typeLabel.numberOfLines = 1
        self.contentView.addSubview(typeLabel)
        self.typeLabel = typeLabel
    }
    
    func createIDLabel() {
        let IDLabel = UILabel()
        IDLabel.translatesAutoresizingMaskIntoConstraints = false
        IDLabel.numberOfLines = 1
        self.contentView.addSubview(IDLabel)
        self.IDLabel = IDLabel
        self.updateIDLabel()
    }
    
    func updateIDLabel() {
        if let IDLabel = self.IDLabel,
            let fingerprintSmallMonospaceFont = self.fingerprintSmallFont?.monospacedFont(),
            let fingerprintSmallBoldMonospaceFont = self.fingerprintSmallBoldFont?.monospacedFont() {
                IDLabel.attributedText = self.userClient.attributedRemoteIdentifier(
                    [NSFontAttributeName: fingerprintSmallMonospaceFont],
                    boldAttributes: [NSFontAttributeName: fingerprintSmallBoldMonospaceFont],
                    uppercase: true
                )
        }
    }
    
    func createFullIDLabel() {
        let fullIDLabel = UILabel()
        fullIDLabel.translatesAutoresizingMaskIntoConstraints = false
        fullIDLabel.numberOfLines = 0
        self.contentView.addSubview(fullIDLabel)
        self.fullIDLabel = fullIDLabel
    }
    
    func createSpinner() {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true

        self.contentView.addSubview(spinner)
        self.spinner = spinner
    }
    
    func updateFingerprintLabel() {

        if let fullIDLabel = self.fullIDLabel,
            let spinner = self.spinner {
            
            if let fingerprintMonospaceFont = self.fingerprintFont?.monospacedFont(),
                let fingerprintBoldMonospaceFont = self.fingerprintBoldFont?.monospacedFont(),
                let attributedFingerprint = self.userClient.fingerprint?.attributedFingerprint(
                    [NSFontAttributeName: fingerprintMonospaceFont],
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
    }
    
    func createVerifiedToggle() {
        let verifiedToggle = UISwitch()
        verifiedToggle.translatesAutoresizingMaskIntoConstraints = false
        verifiedToggle.on = self.userClient.verified
        verifiedToggle.addTarget(self, action: #selector(ProfileClientViewController.onTrustChanged(_:)), for: .valueChanged)
        self.contentView.addSubview(verifiedToggle)
        self.verifiedToggle = verifiedToggle
    }
    
    func createVerifiedToggleLabel() {
        let verifiedToggleLabel = UILabel()
        verifiedToggleLabel.translatesAutoresizingMaskIntoConstraints = false
        verifiedToggleLabel.text = NSLocalizedString("device.verified", comment: "").uppercased()
        verifiedToggleLabel.numberOfLines = 0
        self.contentView.addSubview(verifiedToggleLabel)
        self.verifiedToggleLabel = verifiedToggleLabel
    }
    
    func createResetButton() {
        let resetButton = ButtonWithLargerHitArea()
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.setTitle(NSLocalizedString("profile.devices.detail.reset_session.title", comment: "").uppercased(), for: UIControlState())
        resetButton.addTarget(self, action: #selector(ProfileClientViewController.onResetTapped(_:)), for: .touchUpInside)
        self.contentView.addSubview(resetButton)
        self.resetButton = resetButton
    }
    
    func createConstraints() {
        if let view = self.view
        {
            constrain(view, contentView, reviewInvitationTextView, separatorLineView) { view, contentView, reviewInvitationTextView, separatorLineView in
                contentView.left == view.left + 24
                contentView.right == view.right - 24
                contentView.bottom == view.bottom - 32
                contentView.top >= view.top + 24
                reviewInvitationTextView.top == contentView.top
                reviewInvitationTextView.left == contentView.left
                reviewInvitationTextView.right == contentView.right
                reviewInvitationTextView.bottom == separatorLineView.top - 24
                separatorLineView.left == contentView.left
                separatorLineView.right == contentView.right
                separatorLineView.height == 0.5
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
                backButton.left == contentView.left
                backButton.top == selfView.top + 24
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
        }
    }
    
    // MARK: Actions
    
    func onBackTapped(_ sender: AnyObject) {
        self.presentingViewController?.dismiss(animated: true, completion: .none)
    }
    
    func onShowMyDeviceTapped(_ sender: AnyObject) {
        let selfClientController = SettingsClientViewController(userClient: ZMUserSession.sharedSession().selfUserClient())
        let navigationControllerWrapper = UINavigationController(rootViewController: selfClientController)
        navigationControllerWrapper.modalPresentationStyle = .CurrentContext
        self.presentViewController(navigationControllerWrapper, animated: true, completion: .None)
    }
    
    func onTrustChanged(_ sender: AnyObject) {
        if let verifiedToggle = self.verifiedToggle {
            let selfClient = ZMUserSession.sharedSession().selfUserClient()
            if(verifiedToggle.isOn) {
                selfClient.trustClient(self.userClient)
            } else {
                selfClient.ignoreClient(self.userClient)
            }
            verifiedToggle.on = self.userClient.verified
            
            let verificationType : DeviceVerificationType = verifiedToggle.on ? .Verified : .Unverified
            Analytics.shared()?.tagChangeDeviceVerification(verificationType, deviceOwner: .Other)
        }
    }
    
    func onResetTapped(_ sender: AnyObject) {
        self.userClient.resetSession()
        self.resetSessionPending = true
    }
    
    // MARK: - UserClientObserver
    
    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        if changeInfo.fingerprintChanged {
            self.updateFingerprintLabel()
        }
        
        // This means the fingerprint is acquired
        if self.resetSessionPending && self.userClient.fingerprint != .None {
            let alert = UIAlertController(title: "", message: NSLocalizedString("self.settings.device_details.reset_session.success", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("general.ok", comment: ""), style: .default, handler:  { [unowned alert] (_) -> Void in
                alert.dismiss(animated: true, completion: .none)
                })
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: .none)
            self.resetSessionPending = false
        }
    }
    
    // MARK: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.isEqual(Foundation.URL.wr_fingerprintHowToVerifyURL()) {
            UIApplication.shared.openURL(URL)
            return true
        }
        else {
            return false
        }
    }
}
