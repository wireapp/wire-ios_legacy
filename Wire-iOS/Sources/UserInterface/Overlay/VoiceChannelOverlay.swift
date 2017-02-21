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

let CameraPreviewContainerSize: CGFloat = 72.0;
let OverlayButtonWidth: CGFloat = 56.0;
let GroupCallAvatarSize: CGFloat = 120.0;
let GroupCallAvatarGainRadius: CGFloat = 14.0;
let GroupCallAvatarLabelHeight: CGFloat = 30.0;

@objc class VoiceChannelOverlay: VoiceChannelOverlay_Old {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupVoiceOverlay()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension VoiceChannelOverlay {
    override public var hidesSpeakerButton: Bool {
        didSet {
            updateVisibleViewsForCurrentState()
        }
    }
    
    override public var remoteIsSendingVideo: Bool {
        didSet {
            updateVisibleViewsForCurrentState()
        }
    }
    
    override public var incomingVideoActive: Bool {
        didSet {
            updateVisibleViewsForCurrentState()
            hideControlsAfterElapsedTime()
        }
    }
    
    override public var outgoingVideoActive: Bool {
        didSet {
            updateVisibleViewsForCurrentState()
        }
    }
}

extension VoiceChannelOverlay {

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
        topStatusLabel = UILabel()
        topStatusLabel.accessibilityIdentifier = "CallStatusLabel"
        topStatusLabel.textAlignment = .center
        topStatusLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        topStatusLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        topStatusLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        topStatusLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        topStatusLabel.numberOfLines = 0
        contentContainer.addSubview(topStatusLabel)
        
        centerStatusLabel = UILabel()
        centerStatusLabel.accessibilityIdentifier = "CenterStatusLabel"
        centerStatusLabel.textAlignment = .center
        centerStatusLabel.numberOfLines = 2
        centerStatusLabel.text = "voice.status.video_not_available".localized.uppercasedWithCurrentLocale
        
        [topStatusLabel, centerStatusLabel].forEach(contentContainer.addSubview)
    }
    
    fileprivate func createButtons() {
        acceptButton = createButton(icon: .phone, label: "voice.accept_button.title".localized, accessibilityIdentifier: "AcceptButton")
        acceptVideoButton = createButton(icon: .videoCall, label: "voice.accept_button.title".localized, accessibilityIdentifier: "AcceptVideoButton")
        ignoreButton = createButton(icon: .endCall, label: "voice.decline_button.title".localized, accessibilityIdentifier: "IgnoreButton")
        leaveButton = createButton(icon: .endCall, label: "voice.hang_up_button.title".localized, accessibilityIdentifier: "LeaveCallButton")
        muteButton = createButton(icon: .microphoneWithStrikethrough, label: "voice.mute_button.title".localized, accessibilityIdentifier: "CallMuteButton")
        videoButton = createButton(icon: .videoCall, label: "voice.video_button.title".localized, accessibilityIdentifier: "CallVideoButton")
        speakerButton = createButton(icon: .speaker, label: "voice.speaker_button.title".localized, accessibilityIdentifier: "CallSpeakerButton")
        
        [acceptButton, acceptVideoButton, ignoreButton, leaveButton, muteButton, muteButton, videoButton, speakerButton].forEach(contentContainer.addSubview)
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
        
        constrain(self, contentContainer, callingTopUserImage, topStatusLabel, centerStatusLabel) { view, contentContainer, callingTopUserImage, topStatusLabel, centerStatusLabel in
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

            topStatusLabel.leading == contentContainer.leadingMargin ~ 750
            topStatusLabel.trailing == contentContainer.trailingMargin
            topStatusLabel.top == contentContainer.top + 50
            self.statusLabelToTopUserImageInset = topStatusLabel.leading == callingTopUserImage.trailing + 12
            self.statusLabelToTopUserImageInset.isActive = false
            
            centerStatusLabel.leading == contentContainer.leadingMargin
            centerStatusLabel.trailing == contentContainer.trailingMargin
            centerStatusLabel.centerY == contentContainer.centerY
        }
        
        constrain(contentContainer, avatarContainer, topStatusLabel, callingUserImage) { contentContainer, avatarContainer, topStatusLabel, callingUserImage in
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
        
        constrain([ignoreButton, muteButton]) { buttons in
            let superview = (buttons.first?.superview)!
            buttons.forEach {
                $0.width == OverlayButtonWidth
                $0.bottom == superview.bottomMargin
                $0.leading == superview.leadingMargin
            }
        }
        
        constrain([acceptButton, acceptVideoButton, videoButton, speakerButton]) { buttons in
            let superview = (buttons.first?.superview)!
            buttons.forEach {
                $0.width == OverlayButtonWidth
                $0.bottom == superview.bottomMargin
                $0.trailing == superview.trailingMargin
            }
        }
    }
    
}

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

extension VoiceChannelOverlay {
    @objc(transitionToState:)
    public func transition(to state: VoiceChannelOverlayState) {
        guard state != self.state else { return }
        self.state = state
        updateVisibleViewsForCurrentState()
    }
}
