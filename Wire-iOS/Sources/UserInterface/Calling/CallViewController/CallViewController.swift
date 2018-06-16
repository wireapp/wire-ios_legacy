//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import UIKit
import AVFoundation

final class CallViewController: UIViewController {
    
    weak var dismisser: ViewControllerDismisser? = nil
    
    fileprivate let mediaManager: AVSMediaManager
    fileprivate let voiceChannel: VoiceChannel
    fileprivate var callInfoConfiguration: CallInfoConfiguration
    fileprivate var preferedVideoPlaceholderState: CallVideoPlaceholderState = .statusTextHidden
    fileprivate let callInfoRootViewController: CallInfoRootViewController
    fileprivate weak var overlayTimer: Timer?
    fileprivate let hapticsController = CallHapticsController()
    fileprivate let participantsTimestamps = CallParticipantTimestamps()

    private var observerTokens: [Any] = []
    private var videoConfiguration: VideoConfiguration
    private let videoGridViewController: VideoGridViewController
    private var cameraType: CaptureDevice = .front

    var conversation: ZMConversation? {
        return voiceChannel.conversation
    }
    
    private var proximityMonitorManager: ProximityMonitorManager?

    fileprivate var permissions: CallPermissionsConfiguration {
        return callInfoConfiguration.permissions
    }
    
    init(voiceChannel: VoiceChannel,
         proximityMonitorManager: ProximityMonitorManager? = ZClientViewController.shared()?.proximityMonitorManager,
         mediaManager: AVSMediaManager = .sharedInstance(),
         permissionsConfiguration: CallPermissionsConfiguration = CallPermissions()) {
        
        self.voiceChannel = voiceChannel
        self.mediaManager = mediaManager
        self.proximityMonitorManager = proximityMonitorManager
        videoConfiguration = VideoConfiguration(voiceChannel: voiceChannel, mediaManager: mediaManager,  isOverlayVisible: true)
        callInfoConfiguration = CallInfoConfiguration(voiceChannel: voiceChannel, preferedVideoPlaceholderState: preferedVideoPlaceholderState, permissions: permissionsConfiguration, cameraType: cameraType, sortTimestamps: participantsTimestamps)
        callInfoRootViewController = CallInfoRootViewController(configuration: callInfoConfiguration)
        videoGridViewController = VideoGridViewController(configuration: videoConfiguration)
        super.init(nibName: nil, bundle: nil)
        callInfoRootViewController.delegate = self
        AVSMediaManagerClientChangeNotification.add(self)
        observerTokens += [voiceChannel.addCallStateObserver(self), voiceChannel.addParticipantObserver(self), voiceChannel.addConstantBitRateObserver(self)]
        proximityMonitorManager?.stateChanged = { [weak self] raisedToEar in
            self?.proximityStateDidChange(raisedToEar)
        }
        disableVideoIfNeeded()
    }
    
    deinit {
        AVSMediaManagerClientChangeNotification.remove(self)
        NotificationCenter.default.removeObserver(self)
        stopOverlayTimer()
    }
    
    private func setupApplicationStateObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(resumeVideoIfNeeded), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseVideoIfNeeded), name: .UIApplicationWillResignActive, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        updateConfiguration()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateVideoStatusPlaceholder()
        proximityMonitorManager?.startListening()
        resumeVideoIfNeeded()
        setupApplicationStateObservers()
        updateIdleTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        proximityMonitorManager?.stopListening()
        pauseVideoIfNeeded()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override func accessibilityPerformEscape() -> Bool {
        guard let dismisser = self.dismisser else { return false }
        dismisser.dismiss(viewController: self, completion: nil)
        return true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return callInfoConfiguration.effectiveColorVariant == .light ? .default : .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return !isOverlayVisible
    }

    @objc private func resumeVideoIfNeeded() {
        guard voiceChannel.videoState.isPaused else { return }
        voiceChannel.videoState = .started
        updateConfiguration()
    }

    @objc private func pauseVideoIfNeeded() {
        guard voiceChannel.videoState.isSending else { return }
        voiceChannel.videoState = .paused
        updateConfiguration()
    }

    private func setupViews() {
        [videoGridViewController, callInfoRootViewController].forEach(addToSelf)
    }

    private func createConstraints() {
        callInfoRootViewController.view.fitInSuperview()
        videoGridViewController.view.fitInSuperview()
    }
    
    fileprivate func minimizeOverlay() {
        dismisser?.dismiss(viewController: self, completion: nil)
    }

    fileprivate func acceptDegradedCall() {
        guard let userSession = ZMUserSession.shared() else { return }
        
        userSession.enqueueChanges({
            self.voiceChannel.continueByDecreasingConversationSecurity(userSession: userSession)
        }, completionHandler: {
            self.conversation?.joinCall()
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func updateConfiguration() {
        callInfoConfiguration = CallInfoConfiguration(voiceChannel: voiceChannel, preferedVideoPlaceholderState: preferedVideoPlaceholderState, permissions: permissions, cameraType: cameraType, sortTimestamps: participantsTimestamps)
        callInfoRootViewController.configuration = callInfoConfiguration
        videoConfiguration = VideoConfiguration(voiceChannel: voiceChannel, mediaManager: mediaManager, isOverlayVisible: isOverlayVisible)
        videoGridViewController.configuration = videoConfiguration
        updateOverlayAfterStateChanged()
        updateAppearance()
        updateIdleTimer()
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
    }
    
    private func updateIdleTimer() {
        let disabled = callInfoConfiguration.disableIdleTimer
        UIApplication.shared.isIdleTimerDisabled = disabled
        Log.calling.debug("Updated idle timer: \(disabled ? "disabled" : "enabled")")
    }

    private func updateAppearance() {
        view.backgroundColor = UIColor(scheme: .background, variant: callInfoConfiguration.variant)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard canHideOverlay else { return }

        if let touch = touches.first,
            let overlay = videoGridViewController.previewOverlay,
            overlay.point(inside: touch.location(in: overlay), with: event), !isOverlayVisible {
            return
        }

        toggleOverlayVisibility()
    }
    
    fileprivate func alertVideoUnavailable() {
        if voiceChannel.videoState == .stopped, voiceChannel.conversation?.activeParticipants.count > 4 {
            showAlert(forMessage: "call.video.too_many.alert.message".localized, title: "call.video.too_many.alert.title".localized) { _ in }
        }
    }
    
    fileprivate func toggleVideoState() {
        if !permissions.canAcceptVideoCalls {
            permissions.requestOrWarnAboutVideoPermission { _ in
                self.disableVideoIfNeeded()
                self.updateVideoStatusPlaceholder()
                self.updateConfiguration()
            }
            return
        }

        let newState = voiceChannel.videoState.toggledState
        preferedVideoPlaceholderState = newState == .stopped ? .statusTextHidden : .hidden
        voiceChannel.videoState = newState
        updateConfiguration()
        AnalyticsCallingTracker.userToggledVideo(in: voiceChannel)
    }
    
    fileprivate func toggleCameraAnimated() {
        toggleCameraType()
    }
    
    private func toggleCameraType() {
        do {
            let newType: CaptureDevice = cameraType == .front ? .back : .front
            try voiceChannel.setVideoCaptureDevice(newType)
            cameraType = newType
        } catch {
            Log.calling.error("error toggling capture device: \(error)")
        }
    }

}

extension CallViewController: WireCallCenterCallStateObserver {
    
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?) {
        updateConfiguration()
        hideOverlayAfterCallEstablishedIfNeeded()
        hapticsController.updateCallState(callState)
    }
    
}

extension CallViewController: WireCallCenterCallParticipantObserver {
    
    func callParticipantsDidChange(conversation: ZMConversation, participants: [(UUID, CallParticipantState)]) {
        hapticsController.updateParticipants(participants)
        participantsTimestamps.updateParticipants(participants.map { $0.0 })
        updateConfiguration() // Has to succeed updating the timestamps
    }

}

extension CallViewController: AVSMediaManagerClientObserver {
    
    func mediaManagerDidChange(_ notification: AVSMediaManagerClientChangeNotification!) {
        updateConfiguration()
    }
    
}

extension CallViewController {

    fileprivate func acceptCallIfPossible() {
        permissions.requestOrWarnAboutAudioPermission { audioGranted in
            guard audioGranted else {
                return self.voiceChannel.leave(userSession: ZMUserSession.shared()!)
            }

            self.checkVideoPermissions { videoGranted in
                self.conversation?.joinVoiceChannel(video: videoGranted)
                self.disableVideoIfNeeded()
            }
        }
    }

    private func checkVideoPermissions(resultHandler: @escaping (Bool) -> Void) {
        guard voiceChannel.isVideoCall else { return resultHandler(false) }

        if !permissions.isPendingVideoPermissionRequest {
            resultHandler(permissions.canAcceptVideoCalls)
            updateConfiguration()
            return
        }

        permissions.requestVideoPermissionWithoutWarning { granted in
            resultHandler(granted)
            self.disableVideoIfNeeded()
            self.updateVideoStatusPlaceholder()
        }
    }

    fileprivate func updateVideoStatusPlaceholder() {
        preferedVideoPlaceholderState = permissions.preferredVideoPlaceholderState
        updateConfiguration()
    }

    fileprivate func disableVideoIfNeeded() {
        if permissions.isVideoDisabledForever {
            voiceChannel.videoState = .stopped
        }
    }

}

extension CallViewController: ConstantBitRateAudioObserver {
    
    func callCenterDidChange(constantAudioBitRateAudioEnabled: Bool) {
        updateConfiguration()
    }
    
}

extension CallViewController: CallInfoRootViewControllerDelegate {
    
    func infoRootViewController(_ viewController: CallInfoRootViewController, perform action: CallAction) {
        Log.calling.debug("request to perform call action: \(action)")
        guard let userSession = ZMUserSession.shared() else { return }
        
        switch action {
        case .continueDegradedCall: userSession.enqueueChanges { self.voiceChannel.continueByDecreasingConversationSecurity(userSession: userSession) }
        case .acceptCall: acceptCallIfPossible()
        case .acceptDegradedCall: acceptDegradedCall()
        case .terminateCall: voiceChannel.leave(userSession: userSession)
        case .terminateDegradedCall: userSession.enqueueChanges { self.voiceChannel.leaveAndKeepDegradedConversationSecurity(userSession: userSession) }
        case .toggleMuteState: voiceChannel.toggleMuteState(userSession: userSession)
        case .toggleSpeakerState: AVSMediaManager.sharedInstance().toggleSpeaker()
        case .minimizeOverlay: minimizeOverlay()
        case .toggleVideoState: toggleVideoState()
        case .alertVideoUnavailable: alertVideoUnavailable()
        case .flipCamera: toggleCameraAnimated()
        case .showParticipantsList: return // Handled in `CallInfoRootViewController`, we don't want to update.
        }
        
        updateConfiguration()
        restartOverlayTimerIfNeeded()
    }
    
    func infoRootViewController(_ viewController: CallInfoRootViewController, contextDidChange context: CallInfoRootViewController.Context) {
        guard canHideOverlay else { return }
        switch context {
        case .overview: startOverlayTimer()
        case .participants: stopOverlayTimer()
        }
    }

}

// MARK: - Hide + Show Overlay

extension CallViewController {
    
    var isOverlayVisible: Bool {
        return callInfoRootViewController.view.alpha > 0
    }
    
    fileprivate var canHideOverlay: Bool {
        guard case .established = callInfoConfiguration.state else { return false }
        return callInfoConfiguration.isVideoCall
    }

    fileprivate func toggleOverlayVisibility() {
        animateOverlay(show: !isOverlayVisible)
    }
    
    private func animateOverlay(show: Bool) {
        if show {
            startOverlayTimer()
        } else {
            stopOverlayTimer()
        }
        
        let animations = { [callInfoRootViewController, updateConfiguration] in
            callInfoRootViewController.view.alpha = show ? 1 : 0
            // We update the configuration here to ensure the mute overlay fade animation is in sync with the overlay
            updateConfiguration()
        }

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseInOut,
            animations: animations,
            completion: { [updateConfiguration] _ in updateConfiguration() }
        )
    }
    
    fileprivate func hideOverlayAfterCallEstablishedIfNeeded() {
        let isNotAnimating = callInfoRootViewController.view.layer.animationKeys()?.isEmpty ?? true
        guard nil == overlayTimer, canHideOverlay, isOverlayVisible, isNotAnimating else { return }
        animateOverlay(show: false)
    }
    
    func startOverlayTimer() {
        stopOverlayTimer()
        overlayTimer = .allVersionCompatibleScheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
            self?.animateOverlay(show: false)
        }
    }
    
    fileprivate func updateOverlayAfterStateChanged() {
        if canHideOverlay {
            if overlayTimer == nil {
                startOverlayTimer()
            }
        } else {
            if !isOverlayVisible {
                animateOverlay(show: true)
            }
            stopOverlayTimer()
        }
    }
    
    fileprivate func restartOverlayTimerIfNeeded() {
        guard nil != overlayTimer, canHideOverlay else { return }
        startOverlayTimer()
    }
    
    fileprivate func stopOverlayTimer() {
        overlayTimer?.invalidate()
        overlayTimer = nil
    }

}

extension CallViewController {
    
    func proximityStateDidChange(_ raisedToEar: Bool) {
        guard voiceChannel.isVideoCall, voiceChannel.videoState != .stopped else { return }
        voiceChannel.videoState = raisedToEar ? .paused : .started
        updateConfiguration()
    }

}
