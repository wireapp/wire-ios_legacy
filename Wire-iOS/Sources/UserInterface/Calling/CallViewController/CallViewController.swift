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
    
    fileprivate let voiceChannel: VoiceChannel
    fileprivate var callInfoConfiguration: CallInfoConfiguration
    fileprivate let callInfoRootViewController: CallInfoRootViewController
    fileprivate weak var overlayTimer: Timer?

    private var observerTokens: [Any] = []
    private let videoConfiguration: VideoConfiguration
    private let videoGridViewController: VideoGridViewController
    private var cameraType: CaptureDevice = .front
    
    var conversation: ZMConversation? {
        return voiceChannel.conversation
    }
    
    private var proximityMonitorManager: ProximityMonitorManager? {
        return ZClientViewController.shared()?.proximityMonitorManager
    }

    fileprivate var permissions: CallPermissionsConfiguration {
        return callInfoConfiguration.permissions
    }
    
    init(voiceChannel: VoiceChannel, mediaManager: AVSMediaManager = .sharedInstance(), permissionsConfiguration: CallPermissionsConfiguration = CallPermissions()) {
        self.voiceChannel = voiceChannel
        videoConfiguration = VideoConfiguration(voiceChannel: voiceChannel, mediaManager: mediaManager)
        callInfoConfiguration = CallInfoConfiguration(voiceChannel: voiceChannel, preferedVideoPlaceholderState: .statusTextHidden, permissions: permissionsConfiguration)
        callInfoRootViewController = CallInfoRootViewController(configuration: callInfoConfiguration)
        videoGridViewController = VideoGridViewController(configuration: videoConfiguration)
        super.init(nibName: nil, bundle: nil)
        callInfoRootViewController.delegate = self
        AVSMediaManagerClientChangeNotification.add(self)
        observerTokens += [voiceChannel.addCallStateObserver(self), voiceChannel.addParticipantObserver(self), voiceChannel.addConstantBitRateObserver(self)]
        proximityMonitorManager?.stateChanged = proximityStateDidChange
        videoConfiguration.overlayVisibilityProvider = self
        disableVideoIfNeeded()
    }
    
    deinit {
        AVSMediaManagerClientChangeNotification.remove(self)
        NotificationCenter.default.removeObserver(self)
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        proximityMonitorManager?.stopListening()
        pauseVideoIfNeeded()
        NotificationCenter.default.removeObserver(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return callInfoConfiguration.effectiveColorVariant == .light ? .default : .lightContent
    }

    @objc private func resumeVideoIfNeeded() {
        guard voiceChannel.isVideoCall, voiceChannel.videoState.isPaused else { return }
        voiceChannel.videoState = .started
        updateConfiguration()
    }

    @objc private func pauseVideoIfNeeded() {
        guard voiceChannel.isVideoCall, voiceChannel.videoState.isSending else { return }
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
        callInfoRootViewController.configuration = callInfoConfiguration
        videoGridViewController.configuration = videoConfiguration
        updateOverlayAfterStateChanged()
        updateAppearance()
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
    }

    private func updateAppearance() {
        view.backgroundColor = .wr_color(fromColorScheme: ColorSchemeColorBackground, variant: callInfoConfiguration.variant)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard canHideOverlay else { return }
        
        if let touch = touches.first,
            let overlay = videoGridViewController.previewOverlay,
            overlay.point(inside: touch.location(in: overlay), with: event) {
            return
        }

        toggleOverlayVisibility()
    }
    
    fileprivate func toggleVideoState() {

        if permissions.canAcceptVideoCalls == false {
            permissions.requestOrWarnAboutVideoPermission { _ in
                self.disableVideoIfNeeded()
                self.updateVideoStatusPlaceholder()
                self.updateConfiguration()
            }
            return
        }

        if voiceChannel.videoState == .stopped, voiceChannel.conversation?.activeParticipants.count > 4 {
            showAlert(forMessage: "call.video.too_many.alert.message".localized, title: "call.video.too_many.alert.title".localized) { _ in }
            return
        }

        let newState = voiceChannel.videoState.toggledState

        switch newState {
        case .stopped:
            callInfoConfiguration.preferedVideoPlaceholderState = .statusTextHidden
        default:
            callInfoConfiguration.preferedVideoPlaceholderState = .hidden
        }

        voiceChannel.videoState = newState
        updateConfiguration()

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
            Calling.log.error("error toggling capture device: \(error)")
        }
    }

}

extension CallViewController: WireCallCenterCallStateObserver {
    
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?) {
        updateConfiguration()
        hideOverlayAfterCallEstablishedIfNeeded()
    }
    
}

extension CallViewController: WireCallCenterCallParticipantObserver {
    
    func callParticipantsDidChange(conversation: ZMConversation, participants: [(UUID, CallParticipantState)]) {
        updateConfiguration()
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
                self.voiceChannel.leave(userSession: ZMUserSession.shared()!)
                return
            }

            self.checkVideoPermissions { videoGranted in
                self.conversation?.joinVoiceChannel(video: videoGranted)
            }

        }

    }

    private func checkVideoPermissions(resultHandler: @escaping (Bool) -> Void) {

        guard voiceChannel.isVideoCall else {
            resultHandler(false)
            return
        }

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
        callInfoConfiguration.preferedVideoPlaceholderState = permissions.preferredVideoPlaceholderState
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
        Calling.log.debug("request to perform call action: \(action)")
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

extension CallViewController: OverlayVisibilityProvider {
    
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

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseInOut,
            animations: { [callInfoRootViewController] in callInfoRootViewController.view.alpha = show ? 1 : 0 },
            completion: { [updateConfiguration] _ in updateConfiguration() }
        )
    }
    
    fileprivate func hideOverlayAfterCallEstablishedIfNeeded() {
        let isNotAnimating = callInfoRootViewController.view.layer.animationKeys()?.isEmpty ?? true
        guard nil == overlayTimer, canHideOverlay, isOverlayVisible, isNotAnimating else { return }
        animateOverlay(show: false)
    }
    
    fileprivate func startOverlayTimer() {
        stopOverlayTimer()
        overlayTimer = .allVersionCompatibleScheduledTimer(withTimeInterval: 4, repeats: false) { [animateOverlay] _ in
            animateOverlay(false)
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
