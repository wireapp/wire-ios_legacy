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
import Cartography
import UIKit
import CocoaLumberjackSwift
import Classy

fileprivate let CameraPreviewContainerSize: CGFloat = 72.0;
fileprivate let OverlayButtonWidth: CGFloat = 56.0;
fileprivate let GroupCallAvatarSize: CGFloat = 120.0;
fileprivate let GroupCallAvatarGainRadius: CGFloat = 14.0;
fileprivate let GroupCallAvatarLabelHeight: CGFloat = 30.0;

fileprivate let VoiceChannelOverlayVideoFeedPositionKey = "VideoFeedPosition"

@objc protocol VoiceChannelOverlayDelegate: NSObjectProtocol {
    func cancelButtonTapped()
    func makeDegradedCallTapped()
    func acceptButtonTapped()
    func acceptDegradedButtonTapped()
    func acceptVideoButtonTapped()
    func ignoreButtonTapped()
    func leaveButtonTapped()
    func muteButtonTapped()
    func speakerButtonTapped()
    func videoButtonTapped()
    func switchCameraButtonTapped()
}

@objc enum VoiceChannelOverlayState: Int {
    case invalid
    case incomingCall
    case incomingCallInactive
    case incomingCallDegraded
    case joiningCall
    case outgoingCall
    case outgoingCallDegraded
    case connected
}

fileprivate extension IconLabelButton {
    convenience init(icon: ZetaIconType, label: String, accessibilityIdentifier: String) {
        self.init()
        self.iconButton.setIcon(icon, with: .small, for: .normal)
        self.subtitleLabel.text = label
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

fileprivate extension UILabel {
    static var multiline: UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        label.numberOfLines = 0
        return label
    }
}

class VoiceChannelOverlay: UIView {
    
    var muted = false {
        didSet {
            muteButton.isSelected = muted
            self.cameraPreviewView.mutedPreviewOverlay.isHidden = !self.outgoingVideoActive || !muted
        }
    }
    
    var speakerActive = false {
        didSet {
            speakerButton.isSelected = speakerActive
        }
    }
    
    var hidesSpeakerButton: Bool = false {
        didSet {
            updateVisibleViewsForCurrentState()
        }
    }
    
    var remoteIsSendingVideo: Bool = false {
        didSet {
            updateVisibleViewsForCurrentState()
        }
    }
    
    var incomingVideoActive: Bool = false {
        didSet {
            updateVisibleViewsForCurrentState()
            hideControlsAfterElapsedTime()
        }
    }
    
    var outgoingVideoActive: Bool = false {
        didSet {
            updateVisibleViewsForCurrentState()
        }
    }
    
    var lowBandwidth = false {
        didSet {
            self.centerStatusLabel.text = (lowBandwidth ? "voice.status.low_connection".localized : "voice.status.video_not_available".localized).uppercasedWithCurrentLocale
        }
    }
    
    var callDuration: TimeInterval = 0 {
        didSet {
            updateStatusLabelText()
        }
    }
    
    var constantBitRate: Bool = false {
        didSet {
            updateStatusLabelText()
        }
    }
    
    var controlsHidden = false

    var cameraPreviewPosition: CGPoint {
        get {
            if let positionString = UserDefaults.standard.string(forKey: VoiceChannelOverlayVideoFeedPositionKey)   {
                return CGPointFromString(positionString)
            } else {
                return cameraRightPosition()
            }
        }
        set {
            let position = NSStringFromCGPoint(newValue)
            UserDefaults.standard.set(position, forKey: VoiceChannelOverlayVideoFeedPositionKey)
        }
    }
    
    var videoViewFullscreen: Bool = true {
        didSet {
            createVideoPreviewIfNeeded()
            updateVideoPreviewLocation()
        }
    }
    
    var videoPreview: AVSVideoPreview?
    var videoView: AVSVideoView?
    var cameraPreviewCenterHorisontally: NSLayoutConstraint!
    var cameraPreviewInitialPositionX: CGFloat = 0
    
    let callingConversation: ZMConversation
    var state: VoiceChannelOverlayState = .invalid
    var selfUser: ZMUser = ZMUser.selfUser()
    weak var delegate: VoiceChannelOverlayDelegate?
    
    let participantsCollectionView: UICollectionView
    let participantsCollectionViewLayout: VoiceChannelCollectionViewLayout
    
    let callDurationFormatter = DateComponentsFormatter()
    let cameraPreviewView = CameraPreviewView(width: CameraPreviewContainerSize)
    let contentContainer = UIView()
    let avatarContainer = UIView()
    let shadow = UIView()
    let videoNotAvailableBackground = UIView()
    let callingUserImage = UserImageView()
    let shieldOverlay = DegradationOverlayView()
    let callingTopUserImage = UserImageView()
    
    let cancelButton = IconLabelButton(icon: .X, label: "voice.cancel_button.title".localized, accessibilityIdentifier: "SecurityCancelButton")
    let acceptDegradedButton = IconLabelButton(icon: .phone, label: "voice.accept_button.title".localized, accessibilityIdentifier: "AcceptDegradedButton")
    let makeDegradedCallButton = IconLabelButton(icon: .phone, label: "voice.call_button.title".localized, accessibilityIdentifier: "SecurityCallButton")
    let acceptButton = IconLabelButton(icon: .phone, label: "voice.accept_button.title".localized, accessibilityIdentifier: "AcceptButton")
    let acceptVideoButton = IconLabelButton(icon: .videoCall, label: "voice.accept_button.title".localized, accessibilityIdentifier: "AcceptVideoButton")
    let ignoreButton = IconLabelButton(icon: .endCall, label: "voice.decline_button.title".localized, accessibilityIdentifier: "IgnoreButton")
    let leaveButton = IconLabelButton(icon: .endCall, label: "voice.hang_up_button.title".localized, accessibilityIdentifier: "LeaveCallButton")
    let muteButton = IconLabelButton(icon: .microphoneWithStrikethrough, label: "voice.mute_button.title".localized, accessibilityIdentifier: "CallMuteButton")
    let speakerButton = IconLabelButton(icon: .speaker, label: "voice.speaker_button.title".localized, accessibilityIdentifier: "CallSpeakerButton")
    let videoButton = IconLabelButton(icon: .videoCall, label: "voice.video_button.title".localized, accessibilityIdentifier: "CallVideoButton")

    let degradationTopLabel = UILabel.multiline
    let degradationBottomLabel = UILabel.multiline
    let topStatusLabel = UILabel.multiline
    let centerStatusLabel = UILabel()
    let callingProtocolLabel = UILabel()
    
    var statusLabelToTopUserImageInset: NSLayoutConstraint?
    var degradationTopConstraint: NSLayoutConstraint?
    var degradationBottomConstraint: NSLayoutConstraint?
    var leaveButtonPinRightConstraint: NSLayoutConstraint?
    
    init(frame: CGRect, callingConversation: ZMConversation) {
        self.callingUserImage.userSession = ZMUserSession.shared()
        self.callingTopUserImage.userSession = ZMUserSession.shared()
        self.callingConversation = callingConversation
        self.participantsCollectionViewLayout = VoiceChannelCollectionViewLayout()
        self.participantsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: participantsCollectionViewLayout)
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        setupVoiceOverlay()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancelHideControlsAfterElapsedTime()
    }
    
    func applicationDidBecomeActive() {
        createVideoViewIfNeeded()
        createVideoPreviewIfNeeded()
    }
}

// MARK: - Status labels
extension VoiceChannelOverlay {
    fileprivate func updateStatusLabelText() {
        if let statusText = attributedStatus {
            topStatusLabel.attributedText = statusText
            CASStyler.default().styleItem(topStatusLabel)
        }
    }
    
    private var baseAttributes: [String : Any] {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = .center
        paragraphStyle.paragraphSpacingBefore = 8
        return [ NSParagraphStyleAttributeName : paragraphStyle ]
    }
    
    private var nameAttributes: [String : Any] {
        let font = UIFont(magicIdentifier: "style.text.normal.font_spec_bold")!
        var attributes = baseAttributes
        attributes[NSFontAttributeName] = font
        return attributes
    }
    
    private var messageAttributes: [String : Any] {
        let font = UIFont(magicIdentifier: "style.text.normal.font_spec")!
        var attributes = baseAttributes
        attributes[NSFontAttributeName] = font
        return attributes
    }
    
    private var attributedStatus: NSAttributedString? {
        let conversationName = callingConversation.displayName
        switch state {
        case .incomingCall:
            if callingConversation.conversationType == .oneOnOne {
                let statusText = "voice.status.one_to_one.incoming".localized.lowercasedWithCurrentLocale
                return labelText(withFormat: statusText, name: conversationName)
            } else {
                let statusText = "voice.status.group_call.incoming".localized.lowercasedWithCurrentLocale
                return labelText(withFormat: statusText, name: conversationName)
            }
        case .outgoingCall:
            let statusText = "voice.status.one_to_one.outgoing".localized.lowercasedWithCurrentLocale
            return labelText(withFormat: statusText, name: conversationName)
        case .incomingCallDegraded, .outgoingCallDegraded:
            return labelText(withFormat: "%@\n", name: conversationName)
        case .joiningCall:
            let statusText = "voice.status.joining".localized.lowercasedWithCurrentLocale
            return labelText(withFormat: statusText, name: conversationName)
        case .connected:
            guard let duration = callDurationFormatter.string(from: callDuration) else { return nil }
            var statusText = String(format:"%%@\n%@", duration)
            if self.constantBitRate {
                statusText = statusText + "\n" + "voice.status.cbr".localized.uppercasedWithCurrentLocale
            }
            
            return labelText(withFormat: statusText, name: conversationName)
        case .invalid, .incomingCallInactive:
            return nil
        }
    }
    
    private func labelText(withFormat format: String?, name: String) -> NSAttributedString {
        guard let format = format else { return NSAttributedString(string: "") }
        let string = String(format: format, name)
        let attributedString = NSMutableAttributedString(string: string, attributes: messageAttributes)
        let nameRange = (string as NSString).range(of: name)
        attributedString.addAttributes(nameAttributes, range: nameRange)
        let cbrRange = (string as NSString).range(of: "voice.status.cbr".localized.uppercasedWithCurrentLocale)
        if cbrRange.location != NSNotFound {
            let font = UIFont(magicIdentifier: "style.text.small.font_spec")!
            attributedString.addAttributes([NSFontAttributeName: font], range: cbrRange)
        }
        
        return attributedString
    }
}

// MARK: - Button actions
extension VoiceChannelOverlay {
    func buttonTapped(_ sender: IconLabelButton) {
        switch sender {
        case cancelButton:
            delegate?.cancelButtonTapped()
        case makeDegradedCallButton:
            delegate?.makeDegradedCallTapped()
        case acceptButton:
            delegate?.acceptButtonTapped()
        case acceptDegradedButton:
            delegate?.acceptDegradedButtonTapped()
        case acceptVideoButton:
            delegate?.acceptVideoButtonTapped()
        case ignoreButton:
            delegate?.ignoreButtonTapped()
        case leaveButton:
            delegate?.leaveButtonTapped()
        case muteButton:
            delegate?.muteButtonTapped()
        case speakerButton:
            delegate?.speakerButtonTapped()
        case videoButton:
            delegate?.videoButtonTapped()
        case cameraPreviewView.switchCameraButton:
            delegate?.switchCameraButtonTapped()
        default:
            break
        }
    }
    
}
// MARK: - Showing/hiding controls
extension VoiceChannelOverlay {

    public func hideControls() {
        controlsHidden = true
        updateVisibleViewsForCurrentState(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        backgroundWasTapped()
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let pointInside = super.point(inside: point, with: event)
        if pointInside && incomingVideoActive {
            hideControlsAfterElapsedTime()
        }
        return pointInside
    }
    
    fileprivate func cancelHideControlsAfterElapsedTime() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideControls), object: nil)
    }
    
    fileprivate func hideControlsAfterElapsedTime() {
        cancelHideControlsAfterElapsedTime()
        perform(#selector(hideControls), with: nil, afterDelay: 4)
    }
    
    private func backgroundWasTapped() {
        controlsHidden = !controlsHidden
        updateVisibleViewsForCurrentState(animated: true)
        if !controlsHidden {
            hideControlsAfterElapsedTime()
        }
    }
}

// MARK: - Creating views
extension VoiceChannelOverlay {
    
    fileprivate func createVideoPreviewIfNeeded() {
        guard videoPreview == nil, UIApplication.shared.applicationState == .active else { return }
        
        // Preview view is moving from one subview to another. We cannot use constraints because renderer break if the view
        // is removed from hierarchy and immediately being added to the new superview (we need that to re-apply constraints)
        // therefore we use @c autoresizingMask here
        let preview = AVSVideoPreview(frame: bounds)
        preview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        preview.isUserInteractionEnabled = false
        preview.backgroundColor = .clear
        preview.isHidden = !isVideoCall
        videoPreview = preview
        
        updateVideoPreviewLocation()
    }
    
    fileprivate func updateVideoPreviewLocation() {
        guard let videoPreview = videoPreview, let videoView = videoView else { return }
        
        if videoViewFullscreen {
            videoPreview.frame = bounds
            insertSubview(videoPreview, aboveSubview: videoView)
        } else {
            videoPreview.frame = cameraPreviewView.videoFeedContainer.bounds
            cameraPreviewView.videoFeedContainer.addSubview(videoPreview)
        }
    }
    
    fileprivate func createVideoViewIfNeeded() {
        guard videoView == nil, UIApplication.shared.applicationState == .active else { return }
        
        let video = AVSVideoView()
        video.shouldFill = true
        video.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        video.isUserInteractionEnabled = false
        video.backgroundColor = UIColor(patternImage: .dot(9))
        video.frame = self.bounds
        video.isHidden = !isVideoCall
        insertSubview(video, at: 0)
        self.videoView = video
    }

    fileprivate func setupVoiceOverlay() {
        clipsToBounds = true
        backgroundColor = .clear
        callDurationFormatter.allowedUnits = [.minute, .second]
        callDurationFormatter.zeroFormattingBehavior = DateComponentsFormatter.ZeroFormattingBehavior(rawValue: 0)
        
        createVideoViewIfNeeded()
        
        shadow.isUserInteractionEnabled = false
        shadow.backgroundColor = UIColor(white: 0, alpha: 0.4)
        addSubview(shadow)

        videoNotAvailableBackground.isUserInteractionEnabled = false
        videoNotAvailableBackground.backgroundColor = .black
        addSubview(videoNotAvailableBackground)
        
        contentContainer.layoutMargins = UIEdgeInsets(top: 48, left: 32, bottom: 40, right: 32)
        addSubview(contentContainer)
        
        contentContainer.addSubview(avatarContainer)
        
        callingUserImage.size = .big
        callingUserImage.accessibilityIdentifier = "CallingUsersImage"
        avatarContainer.addSubview(callingUserImage)
        
        avatarContainer.addSubview(shieldOverlay)
        
        callingTopUserImage.size = .small
        callingTopUserImage.accessibilityIdentifier = "CallingTopUsersImage"
        contentContainer.addSubview(callingTopUserImage)
        
        configureParticipantsCollectionViewLayout(layout: participantsCollectionViewLayout)
        configureParticipantsCollectionView(collectionView: participantsCollectionView)
        addSubview(participantsCollectionView)
        
        
        [acceptButton, acceptDegradedButton, acceptVideoButton, ignoreButton, leaveButton, muteButton, muteButton, videoButton, speakerButton, cancelButton, makeDegradedCallButton].forEach {
            contentContainer.addSubview($0)
            $0.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        cameraPreviewView.switchCameraButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        createLabels()
        
        addSubview(cameraPreviewView)
        setupCameraFeedPanGestureRecognizer()
    }
    
    private func createLabels() {
        topStatusLabel.accessibilityIdentifier = "CallStatusLabel"
        degradationTopLabel.accessibilityIdentifier = "CallDegradationTopLabel"
        degradationBottomLabel.accessibilityIdentifier = "CallDegradationBottomLabel"

        centerStatusLabel.accessibilityIdentifier = "CenterStatusLabel"
        centerStatusLabel.textAlignment = .center
        centerStatusLabel.numberOfLines = 2
        centerStatusLabel.text = "voice.status.video_not_available".localized.uppercasedWithCurrentLocale
        
        if let callingProtocol = callingConversation.voiceChannel?.callingProtocol, callingProtocol == .version2 {
            callingProtocolLabel.text = "V2";
        } else {
            callingProtocolLabel.isHidden = true
        }

        [topStatusLabel, centerStatusLabel, degradationTopLabel, degradationBottomLabel, callingProtocolLabel].forEach(contentContainer.addSubview)
    }
    
    private func configureParticipantsCollectionViewLayout(layout: VoiceChannelCollectionViewLayout) {
        layout.itemSize = CGSize(width: GroupCallAvatarSize, height: GroupCallAvatarSize + GroupCallAvatarLabelHeight)
        layout.minimumInteritemSpacing = 24
        layout.minimumLineSpacing = 24
        layout.scrollDirection = .horizontal
    }
    
    private func configureParticipantsCollectionView(collectionView: UICollectionView) {
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
    }
    
    fileprivate func createConstraints(){
        
        let videoViews: [UIView?] = [videoView, shadow, videoNotAvailableBackground]
        
        constrain(videoViews.flatMap{ $0 }) { views in
            let superview = (views.first?.superview)!
            views.forEach { $0.edges == superview.edges }
        }
        
        constrain(self, contentContainer, callingTopUserImage) { view, contentContainer, callingTopUserImage in
            
            contentContainer.width == 320 ~ LayoutPriority(750)
            contentContainer.width <= 320
            contentContainer.top == view.top
            contentContainer.bottom == view.bottom
            contentContainer.leading >= view.leading
            contentContainer.trailing <= view.trailing
            contentContainer.centerX == view.centerX
            
            callingTopUserImage.top == contentContainer.topMargin
            callingTopUserImage.leading == contentContainer.leadingMargin
            callingTopUserImage.height == callingTopUserImage.width
            callingTopUserImage.width == 56
        }
        
        constrain(self, callingUserImage, degradationTopLabel, degradationBottomLabel, makeDegradedCallButton) { view, callingUserImage, degradationTopLabel, degradationBottomLabel, callButton in
            
            degradationTopLabel.leading >= view.leadingMargin
            degradationTopLabel.trailing <= view.trailingMargin
            
            self.degradationTopConstraint = (degradationTopLabel.bottom == callingUserImage.top - 16)
            self.degradationTopConstraint?.isActive = false
            degradationTopLabel.centerX == view.centerX

            degradationBottomLabel.leading >= view.leadingMargin
            degradationBottomLabel.trailing <= view.trailingMargin
            degradationBottomLabel.centerX == view.centerX
            self.degradationBottomConstraint = (degradationBottomLabel.top == callingUserImage.bottom + 16)
            self.degradationBottomConstraint?.isActive = false
            degradationBottomLabel.bottom <= callButton.top - 16
        }
        
        constrain(contentContainer, callingTopUserImage, topStatusLabel, centerStatusLabel, callingProtocolLabel) { contentContainer, callingTopUserImage, topStatusLabel, centerStatusLabel, callingProtocolLabel in
            
            topStatusLabel.leading == contentContainer.leadingMargin ~ 750
            topStatusLabel.trailing == contentContainer.trailingMargin
            topStatusLabel.top == contentContainer.top + 50
            self.statusLabelToTopUserImageInset = topStatusLabel.leading == callingTopUserImage.trailing + 12
            self.statusLabelToTopUserImageInset?.isActive = false
            
            centerStatusLabel.leading == contentContainer.leadingMargin
            centerStatusLabel.trailing == contentContainer.trailingMargin
            centerStatusLabel.centerY == contentContainer.centerY
            
            callingProtocolLabel.leading == contentContainer.leading + 16
            callingProtocolLabel.top == contentContainer.top + 16
        }

        constrain(contentContainer, avatarContainer, topStatusLabel, callingUserImage, shieldOverlay) { contentContainer, avatarContainer, topStatusLabel, callingUserImage, shieldOverlay in
            avatarContainer.top == topStatusLabel.bottom + 24
            avatarContainer.leading == contentContainer.leadingMargin
            avatarContainer.trailing == contentContainer.trailingMargin
            
            callingUserImage.width == 320 ~ LayoutPriority(750)
            callingUserImage.height == 320 ~ LayoutPriority(750)
            callingUserImage.width == callingUserImage.height
            callingUserImage.center == avatarContainer.center
            callingUserImage.leading >= avatarContainer.leading
            callingUserImage.trailing <= avatarContainer.trailing
            callingUserImage.top >= avatarContainer.top
            callingUserImage.bottom <= avatarContainer.bottom
            
            shieldOverlay.edges == callingUserImage.edges
        }
        
        constrain(self, participantsCollectionView, cameraPreviewView) { view, participantsCollectionView, cameraPreviewView in
            participantsCollectionView.height == (GroupCallAvatarSize + GroupCallAvatarGainRadius + GroupCallAvatarLabelHeight)
            participantsCollectionView.leading == view.leading
            participantsCollectionView.trailing == view.trailing
            participantsCollectionView.centerY == view.centerY
            
            cameraPreviewView.width == CameraPreviewContainerSize
            cameraPreviewView.top == view.top + 24
            cameraPreviewView.leading >= view.leading + 24
            cameraPreviewView.trailing <= view.trailing - 24
            self.cameraPreviewCenterHorisontally = (cameraPreviewView.centerX == view.centerX ~ 750)
        }
        
        constrain(contentContainer, avatarContainer, leaveButton) { view, avatarContainer, leave in
            leave.width == OverlayButtonWidth
            leave.centerX == view.centerX ~ 750
            leave.top == avatarContainer.bottom + 32
            leave.bottom == view.bottomMargin
            leaveButtonPinRightConstraint = leave.trailing == view.trailingMargin
            leaveButtonPinRightConstraint?.isActive = false
        }
        
        constrain([ignoreButton, muteButton, cancelButton]) { buttons in
            let superview = (buttons.first?.superview)!
            buttons.forEach {
                $0.width == OverlayButtonWidth
                $0.bottom == superview.bottomMargin
                $0.leading == superview.leadingMargin
            }
        }
        
        constrain([acceptButton, acceptDegradedButton, acceptVideoButton, videoButton, speakerButton, makeDegradedCallButton]) { buttons in
            let superview = (buttons.first?.superview)!
            buttons.forEach {
                $0.width == OverlayButtonWidth
                $0.bottom == superview.bottomMargin
                $0.trailing == superview.trailingMargin
            }
        }
    }
    
}

// MARK: - CollectionViewDelegate
extension VoiceChannelOverlay: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let numberOfItems = CGFloat(collectionView.numberOfItems(inSection: 0))
        let contentWidth = numberOfItems * participantsCollectionViewLayout.itemSize.width + max(numberOfItems - 1, 0) * participantsCollectionViewLayout.minimumLineSpacing
        let frameWidth = participantsCollectionView.frame.size.width
        
        let insets: UIEdgeInsets
        
        if contentWidth < frameWidth {
            // Align content in center of frame
            let horizontalInset = frameWidth - contentWidth
            insets = UIEdgeInsets(top: 0, left: horizontalInset / 2, bottom: 0, right: horizontalInset / 2)
        } else {
            insets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        }
        
        return insets
    }
}

// MARK: - State transitions
extension VoiceChannelOverlay {
    
    fileprivate var isVideoCall: Bool {
        return callingConversation.voiceChannel?.isVideoCall ?? false
    }
    
    private var isGroupCall: Bool {
        return callingConversation.conversationType == .group
    }
    
    @objc(transitionToState:)
    public func transition(to state: VoiceChannelOverlayState) {
        guard state != self.state else { return }
        self.state = state
        updateVisibleViewsForCurrentState()
    }
    
    fileprivate func updateVisibleViewsForCurrentState(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.updateVisibleViewsForCurrentState()
            }

        } else {
            updateVisibleViewsForCurrentState()
        }
    }
    
    private func setDegradationLabelConstraints(active: Bool) {
        self.degradationTopConstraint?.isActive = active
        self.degradationBottomConstraint?.isActive = active
    }
    
    fileprivate func updateCallDegradedLabels() {
        if selfUser.untrusted() {
            degradationTopLabel.text = "voice.degradation.new_self_device".localized
        } else {
            guard let user = callingConversation.connectedUser else { return }
            let format = "voice.degradation.new_user_device".localized
            degradationTopLabel.text = String(format: format, user.displayName)
        }
        
        switch state {
        case .outgoingCallDegraded:
            degradationBottomLabel.text = "voice.degradation_outgoing.prompt".localized
            setDegradationLabelConstraints(active: true)
        case .incomingCallDegraded:
            degradationBottomLabel.text = "voice.degradation_incoming.prompt".localized
            setDegradationLabelConstraints(active: true)
        default:
            setDegradationLabelConstraints(active: false)
        }
    }
    
    fileprivate func updateCallingUserImage() {
        let callingUser: ZMUser?
        if callingConversation.conversationType == .oneOnOne {
            callingUser = callingConversation.firstActiveParticipantOtherThanSelf()
        } else if state == .outgoingCall || state == .outgoingCallDegraded {
            callingUser = ZMUser.selfUser()
        } else {
            callingUser = self.callingConversation.firstActiveCallingParticipantOtherThanSelf()
        }
        callingUserImage.user = callingUser
        callingTopUserImage.user = callingUser
    }
    
    fileprivate func updateVisibleViewsForCurrentState() {
        updateStatusLabelText()
        updateCallingUserImage()
        updateCallDegradedLabels()
        
        visibleViews(for: state).forEach {
            $0.alpha = 1.0
        }
        hiddenViews(for: state).forEach {
            $0.alpha = 0.0
        }
        
        let connected = (state == .connected)
        
        muteButton.isEnabled = connected
        videoButton.isEnabled = connected
        videoButton.isSelected = videoButton.isEnabled && outgoingVideoActive
        
        if isVideoCall {
            videoView?.isHidden = false
            videoPreview?.isHidden = false
            videoViewFullscreen = !connected
        } else {
            videoView?.isHidden = true
            videoPreview?.isHidden = true
        }
        
        cameraPreviewView.mutedPreviewOverlay.isHidden = !outgoingVideoActive || !muted
    }
    
    fileprivate func hiddenViews(for state: VoiceChannelOverlayState) -> Set<UIView> {
        let visible = visibleViews(for: state)
        let hidden = allOverlayViews.subtracting(visible)
        return hidden
    }
    
    fileprivate func visibleViews(for state: VoiceChannelOverlayState) -> Set<UIView> {
        let visible: Set<UIView>
        if isVideoCall {
            visible = visibleViewsForState(inVideoCall: state)
        } else {
            visible = visibleViewsForState(inAudioCall: state)
        }
        updateViewsStateAndLayout(forVisibleViews: visible)
        return visible
    }
    
    fileprivate var allOverlayViews: Set<UIView> {
        return [callingUserImage, callingTopUserImage, topStatusLabel, centerStatusLabel, acceptButton, acceptDegradedButton, acceptVideoButton, ignoreButton, speakerButton, muteButton, leaveButton, videoButton, cameraPreviewView, shadow, videoNotAvailableBackground, participantsCollectionView, cancelButton, makeDegradedCallButton, degradationTopLabel, degradationBottomLabel, shieldOverlay]
    }
    
    fileprivate func connectedStateVisibleViews(videoEnabled: Bool) -> Set<UIView> {
        if videoEnabled {
            if !remoteIsSendingVideo {
                return [muteButton, leaveButton, videoButton, cameraPreviewView, centerStatusLabel, videoNotAvailableBackground]
            } else if incomingVideoActive {
                if controlsHidden {
                    return [cameraPreviewView]
                } else {
                    return [muteButton, leaveButton, videoButton, cameraPreviewView, shadow]
                }
            } else {
                return [muteButton, leaveButton, videoButton, cameraPreviewView]
            }
        } else {
            if isGroupCall {
                return [participantsCollectionView, topStatusLabel, speakerButton, muteButton, leaveButton];
            } else {
                return [callingUserImage, topStatusLabel, speakerButton, muteButton, leaveButton];
            }
        }
    }
    
    fileprivate func visibleViewsForState(inAudioCall state: VoiceChannelOverlayState) -> Set<UIView> {
        let visibleViews: Set<UIView>
        
        switch state {
        case .invalid, .incomingCallInactive:
            visibleViews = []
        case .outgoingCall:
            visibleViews = [callingUserImage, topStatusLabel, speakerButton, muteButton, leaveButton]
        case .outgoingCallDegraded:
            visibleViews = [callingUserImage, topStatusLabel, cancelButton, makeDegradedCallButton, degradationTopLabel, degradationBottomLabel, shieldOverlay]
        case .incomingCall:
            visibleViews = [callingUserImage, topStatusLabel, acceptButton, ignoreButton]
        case .incomingCallDegraded:
            visibleViews = [callingUserImage, topStatusLabel, acceptDegradedButton, cancelButton, degradationTopLabel, degradationBottomLabel, shieldOverlay]
        case .joiningCall:
            visibleViews = [callingUserImage, topStatusLabel, speakerButton, muteButton, leaveButton]
        case .connected:
            visibleViews = connectedStateVisibleViews(videoEnabled: false)
        }
        
        if hidesSpeakerButton {
            return visibleViews.subtracting([speakerButton])
        } else {
            return visibleViews
        }
    }
    
    fileprivate func visibleViewsForState(inVideoCall state: VoiceChannelOverlayState) -> Set<UIView> {
        var visibleViews: Set<UIView>
        
        switch state {
        case .invalid, .incomingCallInactive:
            visibleViews = []
        case .outgoingCall:
            visibleViews = [shadow, callingTopUserImage, topStatusLabel, muteButton, leaveButton, videoButton]
        case .outgoingCallDegraded:
            visibleViews = [shadow, callingUserImage, topStatusLabel, cancelButton, makeDegradedCallButton, degradationTopLabel, degradationBottomLabel, shieldOverlay]
        case .incomingCall:
            visibleViews = [shadow, callingTopUserImage, topStatusLabel, acceptVideoButton, ignoreButton]
        case .incomingCallDegraded:
            visibleViews = [shadow, callingUserImage, topStatusLabel, acceptDegradedButton, cancelButton, degradationTopLabel, degradationBottomLabel, shieldOverlay]
        case .joiningCall:
            visibleViews = [callingTopUserImage, topStatusLabel, muteButton, leaveButton, videoButton]
        case .connected:
            visibleViews = connectedStateVisibleViews(videoEnabled: true)
            if !outgoingVideoActive {
                visibleViews.remove(cameraPreviewView)
            }
        }
        
        return visibleViews
    }
    
    fileprivate func updateViewsStateAndLayout(forVisibleViews visibleViews: Set<UIView>) {
        if visibleViews.contains(callingTopUserImage) {
            topStatusLabel.textAlignment = .left
            statusLabelToTopUserImageInset?.isActive = true
        } else {
            topStatusLabel.textAlignment = .center
            statusLabelToTopUserImageInset?.isActive = false
        }
        
        if visibleViews.contains(cameraPreviewView) {
            cameraPreviewCenterHorisontally.constant = cameraPreviewPosition.x
        }
        
        if isVideoCall {
            leaveButtonPinRightConstraint?.isActive = false
        } else {
            leaveButtonPinRightConstraint?.isActive = hidesSpeakerButton
        }
    }
}

// MARK: - Camera overlay
extension VoiceChannelOverlay {
    fileprivate func setupCameraFeedPanGestureRecognizer() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onCameraPreviewPan(_:)))
        cameraPreviewView.addGestureRecognizer(pan)
    }
    
    fileprivate func cameraRightPosition() -> CGPoint {
        let inset: CGFloat = 24
        let sideInset = (bounds.width - inset) / 2
        return CGPoint(x: sideInset, y: 0)
    }

    fileprivate func cameraLeftPosition() -> CGPoint {
        let inset: CGFloat = 24
        let sideInset = (bounds.width - inset) / 2
        return CGPoint(x: -sideInset, y: 0)
    }
    
    public func onCameraPreviewPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        let offset = gestureRecognizer.translation(in: self)
        let newPositionX = cameraPreviewInitialPositionX + offset.x;
        let dragThreshold: CGFloat = 180
        
        switch gestureRecognizer.state {
        case .began:
            cameraPreviewInitialPositionX = cameraPreviewCenterHorisontally.constant
        case .changed:
            cameraPreviewInitialPositionX = newPositionX
            layoutIfNeeded()
        case .ended:
            UIView.wr_animate(easing: RBBEasingFunctionEaseOutExpo, duration: 0.7) {
                var endPosition = CGPoint.zero
                if (self.cameraPreviewInitialPositionX < 0) {
                    if fabs(offset.x) > dragThreshold {
                        // move to new position
                        endPosition = self.cameraRightPosition()
                    } else {
                        // bounce back
                        endPosition = self.cameraLeftPosition()
                    }
                }
                else { // camera was on the right
                    if fabs(offset.x) > dragThreshold {
                        // move to new position
                        endPosition = self.cameraLeftPosition()
                    }
                    else {
                        // bounce back
                        endPosition = self.cameraRightPosition()
                    }
                }
                self.cameraPreviewPosition = endPosition
                self.cameraPreviewCenterHorisontally.constant = endPosition.x
                self.layoutIfNeeded()
            }
        default:
            break;
        }
    }
    
    public func animateCameraChange(changeAction action: (() -> Void)?, completion: ((Bool) -> Void)?) {
        let snapshot = cameraPreviewView.videoFeedContainer.snapshotView(afterScreenUpdates: true)!
        cameraPreviewView.addSubview(snapshot)
        if let action = action {
            action()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let initialTransform = CATransform3DRotate(self.cameraPreviewView.switchCameraButton.layer.transform, CGFloat.pi, 0, 1, 0)
            self.cameraPreviewView.switchCameraButton.layer.transform = CATransform3DRotate(initialTransform, CGFloat.pi, 1, 0, 0)
            UIView.transition(with: self.cameraPreviewView, duration: 0.8, options: [.transitionFlipFromLeft], animations: {
                snapshot.removeFromSuperview()
            }, completion: completion)
        }
    }
}

// MARK: - State string representation
extension VoiceChannelOverlay {
    static func stringFrom(state: VoiceChannelOverlayState) -> String {
        switch state {
        case .invalid:
            return "OverlayInvalid"
        case .incomingCall:
            return "OverlayIncomingCall"
        case .incomingCallInactive:
            return "OverlayIncomingCallInactive"
        case .incomingCallDegraded:
            return "OverlayIncomingCallDegraded"
        case .joiningCall:
            return "OverlayJoiningCall"
        case .outgoingCall:
            return "OverlayOutgoingCall"
        case .outgoingCallDegraded:
            return "OverlayOutgoingCallDegraded"
        case .connected:
            return "OverlayConnected"
        }
    }
}
