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

let CameraPreviewContainerSize: CGFloat = 72.0;
let OverlayButtonWidth: CGFloat = 56.0;
let GroupCallAvatarSize: CGFloat = 120.0;
let GroupCallAvatarGainRadius: CGFloat = 14.0;
let GroupCallAvatarLabelHeight: CGFloat = 30.0;

fileprivate let VoiceChannelOverlayVideoFeedPositionKey = "VideoFeedPosition"

@objc class VoiceChannelOverlay: VoiceChannelOverlay_Old {
    
    var muted = false {
        didSet {
            self.muteButton.isSelected = muted
            self.cameraPreviewView.mutedPreviewOverlay.isHidden = !self.outgoingVideoActive || !muted
        }
    }
    var speakerActive = false {
        didSet {
            self.speakerButton.isSelected = speakerActive
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
    
    var attributedStatus: NSAttributedString? {
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
            let statusText = String(format:"%%@\n%@", duration)
            return labelText(withFormat: statusText, name: conversationName)
        case .invalid, .incomingCallInactive:
            return nil
        }
    }
    
    var controlsHidden = false

    var cancelButton: IconLabelButton!
    var acceptDegradedButton: IconLabelButton!
    var callButton: IconLabelButton!
    var degradationTopLabel: UILabel!
    var degradationBottomLabel: UILabel!
    var shieldOverlay: DegradationOverlayView!
    var degradationTopConstraint: NSLayoutConstraint!
    var degradationBottomConstraint: NSLayoutConstraint!
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
    
    var videoViewFullscreen: Bool = false {
        didSet {
            createVideoPreviewIfNeeded()
            if videoViewFullscreen {
                videoPreview.frame = bounds
                insertSubview(videoPreview, aboveSubview: videoView)
            } else {
                videoPreview.frame = cameraPreviewView.videoFeedContainer.bounds
                cameraPreviewView.videoFeedContainer.addSubview(videoPreview)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupVoiceOverlay()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cancelHideControlsAfterElapsedTime()
    }
    
    @objc(setCancelButtonTarget:action:)
    func setCancelButton(target: Any, action: Selector) {
        cancelButton.addTarget(target, action: action, for: .touchUpInside)
    }
    
    @objc(setCallButtonTarget:action:)
    func setCallButton(target: Any, action: Selector) {
        callButton.addTarget(target, action: action, for: .touchUpInside)
    }
    
    @objc(setAcceptDegradedButtonTarget:action:)
    func setAcceptDegradedButton(target: Any, action: Selector) {
        acceptDegradedButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func updateStatusLabelText() {
        if let statusText = attributedStatus {
            topStatusLabel.attributedText = statusText
        }
    }
}

// MARK: - Showing/hiding controls
extension VoiceChannelOverlay {

    public func hideControls() {
        controlsHidden = true
        updateVisibleViewsForCurrentState(animated: true)
    }
    
    public func hideControlsAfterElapsedTime() {
        cancelHideControlsAfterElapsedTime()
        perform(#selector(hideControls), with: nil, afterDelay: 4)
    }
    
    public func cancelHideControlsAfterElapsedTime() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideControls), object: nil)
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
    
    public func backgroundWasTapped() {
        controlsHidden = !controlsHidden
        updateVisibleViewsForCurrentState(animated: true)
        if !controlsHidden {
            hideControlsAfterElapsedTime()
        }
    }
}

// MARK: - Creating views
extension VoiceChannelOverlay {
    
    func createVideoPreviewIfNeeded() {
        if !Settings.shared().disableAVS && videoPreview == nil {
            // Preview view is moving from one subview to another. We cannot use constraints because renderer break if the view
            // is removed from hierarchy and immediately being added to the new superview (we need that to reapply constraints)
            // therefore we use @c autoresizingMask here
            videoPreview = AVSVideoPreview(frame: bounds)
            videoPreview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            videoPreview.isUserInteractionEnabled = false
            videoPreview.backgroundColor = .clear
            insertSubview(videoPreview, aboveSubview: videoView)
        }
    }

    public func setupVoiceOverlay() {
        clipsToBounds = true
        backgroundColor = .clear
        callDurationFormatter = DateComponentsFormatter()
        callDurationFormatter.allowedUnits = [.minute, .second]
        callDurationFormatter.zeroFormattingBehavior = DateComponentsFormatter.ZeroFormattingBehavior(rawValue: 0)
        
        if !Settings.shared().disableAVS {
            videoView = AVSVideoView()
            videoView.shouldFill = true
            videoView.isUserInteractionEnabled = false
            videoView.backgroundColor = UIColor(patternImage: .dot(9))
            addSubview(videoView)
        }

        videoViewFullscreen = true
        
        shadow = UIView()
        shadow.isUserInteractionEnabled = false
        shadow.backgroundColor = UIColor(white: 0, alpha: 0.4)
        addSubview(shadow)

        videoNotAvailableBackground = UIView()
        videoNotAvailableBackground.isUserInteractionEnabled = false
        videoNotAvailableBackground.backgroundColor = .black
        addSubview(videoNotAvailableBackground)
        
        contentContainer = UIView()
        contentContainer.layoutMargins = UIEdgeInsets(top: 48, left: 32, bottom: 40, right: 32)
        addSubview(contentContainer)
        
        avatarContainer = UIView()
        contentContainer.addSubview(avatarContainer)
        
        callingUserImage = UserImageView()
        callingUserImage.suggestedImageSize = .big
        callingUserImage.accessibilityIdentifier = "CallingUsersImage"
        avatarContainer.addSubview(callingUserImage)
        
        shieldOverlay = DegradationOverlayView()
        avatarContainer.addSubview(shieldOverlay)
        
        callingTopUserImage = UserImageView()
        callingTopUserImage.suggestedImageSize = .small
        callingTopUserImage.accessibilityIdentifier = "CallingTopUsersImage"
        contentContainer.addSubview(callingTopUserImage)
        
        participantsCollectionViewLayout = createParticipantsCollectionViewLayout()
        participantsCollectionView = createParticipantsCollectionView(layout: participantsCollectionViewLayout)
        addSubview(participantsCollectionView)
        
        createButtons()
        createLabels()
        
        cameraPreviewView = CameraPreviewView(width: CameraPreviewContainerSize)
        addSubview(cameraPreviewView)
        setupCameraFeedPanGestureRecognizer()
    }
    
    fileprivate func createLabels() {
        topStatusLabel = createMultilineLabel()
        topStatusLabel.accessibilityIdentifier = "CallStatusLabel"
        
        centerStatusLabel = UILabel()
        centerStatusLabel.accessibilityIdentifier = "CenterStatusLabel"
        centerStatusLabel.textAlignment = .center
        centerStatusLabel.numberOfLines = 2
        centerStatusLabel.text = "voice.status.video_not_available".localized.uppercasedWithCurrentLocale
        
        degradationTopLabel = createMultilineLabel()
        degradationTopLabel.accessibilityIdentifier = "CallDegradationTopLabel"
        
        degradationBottomLabel = createMultilineLabel()
        degradationBottomLabel.accessibilityIdentifier = "CallDegradationBottomLabel"

        [topStatusLabel, centerStatusLabel, degradationTopLabel, degradationBottomLabel].forEach(contentContainer.addSubview)
    }
    
    fileprivate func createMultilineLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        label.numberOfLines = 0
        return label
    }
    
    fileprivate func createButtons() {
        acceptButton = createButton(icon: .phone, label: "voice.accept_button.title".localized, accessibilityIdentifier: "AcceptButton")
        acceptDegradedButton = createButton(icon: .phone, label: "voice.accept_button.title".localized, accessibilityIdentifier: "AcceptDegradedButton")
        acceptVideoButton = createButton(icon: .videoCall, label: "voice.accept_button.title".localized, accessibilityIdentifier: "AcceptVideoButton")
        ignoreButton = createButton(icon: .endCall, label: "voice.decline_button.title".localized, accessibilityIdentifier: "IgnoreButton")
        leaveButton = createButton(icon: .endCall, label: "voice.hang_up_button.title".localized, accessibilityIdentifier: "LeaveCallButton")
        muteButton = createButton(icon: .microphoneWithStrikethrough, label: "voice.mute_button.title".localized, accessibilityIdentifier: "CallMuteButton")
        videoButton = createButton(icon: .videoCall, label: "voice.video_button.title".localized, accessibilityIdentifier: "CallVideoButton")
        speakerButton = createButton(icon: .speaker, label: "voice.speaker_button.title".localized, accessibilityIdentifier: "CallSpeakerButton")
        cancelButton = createButton(icon: .X, label: "voice.cancel_button.title".localized, accessibilityIdentifier: "SecurityCancelButton")
        callButton = createButton(icon: .phone, label: "voice.call_button.title".localized, accessibilityIdentifier: "SecurityCallButton")

        [acceptButton, acceptDegradedButton, acceptVideoButton, ignoreButton, leaveButton, muteButton, muteButton, videoButton, speakerButton, cancelButton, callButton].forEach(contentContainer.addSubview)
    }
    
    fileprivate func createButton(icon: ZetaIconType, label: String, accessibilityIdentifier: String) -> IconLabelButton {
        let button = IconLabelButton()
        button.iconButton.setIcon(icon, with: .small, for: .normal)
        button.subtitleLabel.text = label
        button.accessibilityIdentifier = accessibilityIdentifier
        return button
    }
    
    fileprivate func createParticipantsCollectionViewLayout() -> VoiceChannelCollectionViewLayout {
        let layout = VoiceChannelCollectionViewLayout()
        layout.itemSize = CGSize(width: GroupCallAvatarSize, height: GroupCallAvatarSize + GroupCallAvatarLabelHeight)
        layout.minimumInteritemSpacing = 24
        layout.minimumLineSpacing = 24
        layout.scrollDirection = .horizontal
        return layout
    }
    
    fileprivate func createParticipantsCollectionView(layout: UICollectionViewLayout) -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        return collectionView
    }
    
    public func createConstraints(){
        
        constrain([videoView, shadow, videoNotAvailableBackground]) { views in
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
        
        constrain(self, callingUserImage, degradationTopLabel, degradationBottomLabel, callButton) { view, callingUserImage, degradationTopLabel, degradationBottomLabel, callButton in
            
            degradationTopLabel.leading >= view.leadingMargin
            degradationTopLabel.trailing <= view.trailingMargin
            
            self.degradationTopConstraint = (degradationTopLabel.bottom == callingUserImage.top - 16)
            self.degradationTopConstraint.isActive = false
            degradationTopLabel.centerX == view.centerX

            degradationBottomLabel.leading >= view.leadingMargin
            degradationBottomLabel.trailing <= view.trailingMargin
            degradationBottomLabel.centerX == view.centerX
            self.degradationBottomConstraint = (degradationBottomLabel.top == callingUserImage.bottom + 16)
            self.degradationBottomConstraint.isActive = false
            degradationBottomLabel.bottom <= callButton.top - 16
        }
        
        constrain(contentContainer, callingTopUserImage, topStatusLabel, centerStatusLabel) { contentContainer, callingTopUserImage, topStatusLabel, centerStatusLabel in
            
            topStatusLabel.leading == contentContainer.leadingMargin ~ 750
            topStatusLabel.trailing == contentContainer.trailingMargin
            topStatusLabel.top == contentContainer.top + 50
            self.statusLabelToTopUserImageInset = topStatusLabel.leading == callingTopUserImage.trailing + 12
            self.statusLabelToTopUserImageInset.isActive = false
            
            centerStatusLabel.leading == contentContainer.leadingMargin
            centerStatusLabel.trailing == contentContainer.trailingMargin
            centerStatusLabel.centerY == contentContainer.centerY
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
            self.leaveButtonPinRightConstraint = leave.trailing == view.trailingMargin
            self.leaveButtonPinRightConstraint.isActive = false
        }
        
        constrain([ignoreButton, muteButton, cancelButton]) { buttons in
            let superview = (buttons.first?.superview)!
            buttons.forEach {
                $0.width == OverlayButtonWidth
                $0.bottom == superview.bottomMargin
                $0.leading == superview.leadingMargin
            }
        }
        
        constrain([acceptButton, acceptDegradedButton, acceptVideoButton, videoButton, speakerButton, callButton]) { buttons in
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
    
    var isVideoCall: Bool {
        return callingConversation.voiceChannel?.isVideoCall ?? false
    }
    
    var isGroupCall: Bool {
        return callingConversation.conversationType == .group
    }
    
    @objc(transitionToState:)
    public func transition(to state: VoiceChannelOverlayState) {
        guard state != self.state else { return }
        self.state = state
        updateVisibleViewsForCurrentState()
    }
    
    func updateVisibleViewsForCurrentState(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.updateVisibleViewsForCurrentState()
            }

        } else {
            updateVisibleViewsForCurrentState()
        }
    }
    
    private func setDegradationLabelConstraints(active: Bool) {
        self.degradationTopConstraint.isActive = active
        self.degradationBottomConstraint.isActive = active
    }
    
    func updateCallDegradedLabels() {
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
    
    func updateCallingUserImage() {
        let callingUser: ZMUser?
        if callingConversation.conversationType == .oneOnOne {
            callingUser = callingConversation.firstActiveParticipantOtherThanSelf()
        } else if state == .outgoingCall || state == .outgoingCallDegraded {
            callingUser = ZMUser.selfUser()
        } else {
            callingUser = self.callingConversation.firstActiveCallingParticipantOtherThanSelf()
        }
        self.callingUserImage.user = callingUser
        self.callingTopUserImage.user = callingUser
    }
    
    func updateVisibleViewsForCurrentState() {
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
            videoViewFullscreen = !connected
        } else {
            videoView.isHidden = true
            videoPreview?.isHidden = true
        }
        
        cameraPreviewView.mutedPreviewOverlay.isHidden = !outgoingVideoActive || !muted
    }
    
    func hiddenViews(for state: VoiceChannelOverlayState) -> Set<UIView> {
        let visible = visibleViews(for: state)
        let hidden = allOverlayViews.subtracting(visible)
        return hidden
    }
    
    func visibleViews(for state: VoiceChannelOverlayState) -> Set<UIView> {
        let visible: Set<UIView>
        if isVideoCall {
            visible = visibleViewsForState(inVideoCall: state)
        } else {
            visible = visibleViewsForState(inAudioCall: state)
        }
        updateViewsStateAndLayout(forVisibleViews: visible)
        return visible
    }
    
    var allOverlayViews: Set<UIView> {
        return [self.callingUserImage, self.callingTopUserImage, self.topStatusLabel, self.centerStatusLabel, self.acceptButton, self.acceptDegradedButton, self.acceptVideoButton, self.ignoreButton, self.speakerButton, self.muteButton, self.leaveButton, self.videoButton, self.cameraPreviewView, self.shadow, self.videoNotAvailableBackground, self.participantsCollectionView, cancelButton, callButton, degradationTopLabel, degradationBottomLabel, shieldOverlay]
    }
    
    func visibleViewsForState(inAudioCall state: VoiceChannelOverlayState) -> Set<UIView> {
        let visibleViews: Set<UIView>
        
        switch state {
        case .invalid, .incomingCallInactive:
            visibleViews = []
        case .outgoingCall:
            visibleViews = [self.callingUserImage, self.topStatusLabel, self.speakerButton, self.muteButton, self.leaveButton]
        case .outgoingCallDegraded:
            visibleViews = [self.callingUserImage, self.topStatusLabel, cancelButton, callButton, degradationTopLabel, degradationBottomLabel, shieldOverlay]
        case .incomingCall:
            visibleViews = [self.callingUserImage, self.topStatusLabel, self.acceptButton, self.ignoreButton]
        case .incomingCallDegraded:
            visibleViews = [self.callingUserImage, self.topStatusLabel, self.acceptDegradedButton, cancelButton, degradationTopLabel, degradationBottomLabel, shieldOverlay]
        case .joiningCall:
            visibleViews = [self.callingUserImage, self.topStatusLabel, self.speakerButton, self.muteButton, self.leaveButton]
        case .connected:
            if isGroupCall {
                visibleViews = [self.participantsCollectionView, self.topStatusLabel, self.speakerButton, self.muteButton, self.leaveButton];
            } else {
                visibleViews = [self.callingUserImage, self.topStatusLabel, self.speakerButton, self.muteButton, self.leaveButton];
            }
        }
        
        if hidesSpeakerButton {
            return visibleViews.subtracting([speakerButton])
        } else {
            return visibleViews
        }
    }
    
    func visibleViewsForState(inVideoCall state: VoiceChannelOverlayState) -> Set<UIView> {
        var visibleViews: Set<UIView>
        
        switch state {
        case .invalid, .incomingCallInactive:
            visibleViews = []
        case .outgoingCall:
            visibleViews = [self.shadow, self.callingTopUserImage, self.topStatusLabel, self.muteButton, self.leaveButton, self.videoButton]
        case .outgoingCallDegraded:
            visibleViews = [self.shadow, self.callingUserImage, self.topStatusLabel, cancelButton, callButton, degradationTopLabel, degradationBottomLabel, shieldOverlay]
        case .incomingCall:
            visibleViews = [self.shadow, self.callingTopUserImage, self.topStatusLabel, self.acceptVideoButton, self.ignoreButton]
        case .incomingCallDegraded:
            visibleViews = [self.shadow, self.callingUserImage, self.topStatusLabel, self.acceptDegradedButton, cancelButton, degradationTopLabel, degradationBottomLabel, shieldOverlay]
        case .joiningCall:
            visibleViews = [self.callingTopUserImage, self.topStatusLabel, self.muteButton, self.leaveButton, self.videoButton]
        case .connected:
            if !remoteIsSendingVideo {
                visibleViews = [self.muteButton, self.leaveButton, self.videoButton, self.cameraPreviewView, self.centerStatusLabel, self.videoNotAvailableBackground]
            } else if incomingVideoActive {
                if controlsHidden {
                    visibleViews = [cameraPreviewView]
                } else {
                    visibleViews = [self.muteButton, self.leaveButton, self.videoButton, self.cameraPreviewView, shadow]

                }
            } else {
                visibleViews = [self.muteButton, self.leaveButton, self.videoButton, self.cameraPreviewView]
            }
            
            if !outgoingVideoActive {
                visibleViews.remove(cameraPreviewView)
            }
        }
        
        if hidesSpeakerButton || outgoingVideoActive {
            visibleViews.subtract([speakerButton])
        }
        
        return visibleViews
    }
    
    func updateViewsStateAndLayout(forVisibleViews visibleViews: Set<UIView>) {
        if visibleViews.contains(callingTopUserImage) {
            topStatusLabel.textAlignment = .left
            statusLabelToTopUserImageInset.isActive = true
        } else {
            topStatusLabel.textAlignment = .center
            statusLabelToTopUserImageInset.isActive = false
        }
        
        if visibleViews.contains(cameraPreviewView) {
            cameraPreviewCenterHorisontally.constant = cameraPreviewPosition.x
        }
        
        if isVideoCall {
            leaveButtonPinRightConstraint.isActive = false
        } else {
            leaveButtonPinRightConstraint.isActive = hidesSpeakerButton
        }
    }
}

// MARK: - Camera overlay
extension VoiceChannelOverlay {
    func setupCameraFeedPanGestureRecognizer() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onCameraPreviewPan(_:)))
        cameraPreviewView.addGestureRecognizer(pan)
    }
    
    func cameraRightPosition() -> CGPoint {
        let inset: CGFloat = 24
        let sideInset = (bounds.width - inset) / 2
        return CGPoint(x: sideInset, y: 0)
    }

    func cameraLeftPosition() -> CGPoint {
        let inset: CGFloat = 24
        let sideInset = (bounds.width - inset) / 2
        return CGPoint(x: -sideInset, y: 0)
    }
    
    func onCameraPreviewPan(_ gestureRecognizer: UIPanGestureRecognizer) {
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
    
    func animateCameraChange(changeAction action: (() -> Void)?, completion: ((Bool) -> Void)?) {
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
