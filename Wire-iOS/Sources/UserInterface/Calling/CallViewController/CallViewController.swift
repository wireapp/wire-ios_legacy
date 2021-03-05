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
import WireSyncEngine
import avs

protocol CallViewControllerDelegate: class {
    func callViewControllerDidDisappear(_ callController: CallViewController,
                                        for conversation: ZMConversation?)
}

final class CallViewController: UIViewController {

    weak var delegate: CallViewControllerDelegate?
    fileprivate var tapRecognizer: UITapGestureRecognizer!
    fileprivate let mediaManager: AVSMediaManagerInterface
    fileprivate let voiceChannel: VoiceChannel
    fileprivate var callInfoConfiguration: CallInfoConfiguration
    fileprivate var preferedVideoPlaceholderState: CallVideoPlaceholderState = .statusTextHidden
    fileprivate let callInfoRootViewController: CallInfoRootViewController
    fileprivate weak var overlayTimer: Timer?
    fileprivate let hapticsController = CallHapticsController()

    private var observerTokens: [Any] = []
    private var videoConfiguration: VideoConfiguration
    private let videoGridViewController: VideoGridViewController
    private var cameraType: CaptureDevice = .front
    private var singleTapRecognizer: UITapGestureRecognizer!
    private var doubleTapRecognizer: UITapGestureRecognizer!

    private var isInteractiveDismissal = false

    var conversation: ZMConversation? {
        return voiceChannel.conversation
    }

    private var proximityMonitorManager: ProximityMonitorManager?

    fileprivate var permissions: CallPermissionsConfiguration {
        return callInfoConfiguration.permissions
    }

    private static var userEnabledCBR: Bool {
        return Settings.shared[.callingConstantBitRate] == true
    }

    init(voiceChannel: VoiceChannel,
         selfUser: UserType,
         proximityMonitorManager: ProximityMonitorManager? = ZClientViewController.shared?.proximityMonitorManager,
         mediaManager: AVSMediaManagerInterface = AVSMediaManager.sharedInstance(),
         permissionsConfiguration: CallPermissionsConfiguration = CallPermissions()) {

        self.voiceChannel = voiceChannel
        self.mediaManager = mediaManager
        self.proximityMonitorManager = proximityMonitorManager
        videoConfiguration = VideoConfiguration(voiceChannel: voiceChannel)

        callInfoConfiguration = CallInfoConfiguration(voiceChannel: voiceChannel,
                                                      preferedVideoPlaceholderState: preferedVideoPlaceholderState,
                                                      permissions: permissionsConfiguration,
                                                      cameraType: cameraType,
                                                      mediaManager: mediaManager,
                                                      userEnabledCBR: CallViewController.userEnabledCBR,
                                                      selfUser: selfUser)

        callInfoRootViewController = CallInfoRootViewController(configuration: callInfoConfiguration, selfUser: ZMUser.selfUser())
        videoGridViewController = VideoGridViewController(configuration: videoConfiguration)

        super.init(nibName: nil, bundle: nil)
        callInfoRootViewController.delegate = self
        observerTokens += [voiceChannel.addCallStateObserver(self),
                           voiceChannel.addParticipantObserver(self),
                           voiceChannel.addConstantBitRateObserver(self),
                           voiceChannel.addNetworkQualityObserver(self),
                           voiceChannel.addMuteStateObserver(self),
                           voiceChannel.addActiveSpeakersObserver(self)]
        proximityMonitorManager?.stateChanged = { [weak self] raisedToEar in
            self?.proximityStateDidChange(raisedToEar)
        }
        disableVideoIfNeeded()

        setupViews()
        createConstraints()
        updateConfiguration()

        singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(singleTapRecognizer)
        doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTapRecognizer)

        singleTapRecognizer.require(toFail: doubleTapRecognizer)
    }

    @objc
    private func handleSingleTap(_ sender: UITapGestureRecognizer) {

        guard canHideOverlay else { return }

        if let overlay = videoGridViewController.previewOverlay,
            overlay.point(inside: sender.location(in: overlay), with: nil), !isOverlayVisible {
            return
        }
        toggleOverlayVisibility()
    }

    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        guard !isOverlayVisible else { return }

        videoGridViewController.handleDoubleTap(gesture: sender)
    }

    deinit {
        AVSMediaManagerClientChangeNotification.remove(self)
        stopOverlayTimer()
    }

    private func setupApplicationStateObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(resumeVideoIfNeeded), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseVideoIfNeeded), name: UIApplication.willResignActiveNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateVideoStatusPlaceholder()
        AVSMediaManagerClientChangeNotification.add(self)
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
        isInteractiveDismissal = transitionCoordinator?.isInteractive == true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false

        if isInteractiveDismissal {
            delegate?.callViewControllerDidDisappear(self, for: conversation)
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        guard let delegate = delegate else { return false }
        delegate.callViewControllerDidDisappear(self, for: conversation)
        return true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return callInfoConfiguration.effectiveColorVariant == .light ? .compatibleDarkContent : .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        return !isOverlayVisible
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    @objc
    private func resumeVideoIfNeeded() {
        guard voiceChannel.videoState.isPaused else { return }
        voiceChannel.videoState = .started
        updateConfiguration()
    }

    @objc
    private func pauseVideoIfNeeded() {
        guard voiceChannel.videoState.isSending else { return }
        voiceChannel.videoState = .paused
        updateConfiguration()
    }

    private func setupViews() {
        [videoGridViewController, callInfoRootViewController].forEach(addToSelf)
    }

    private func createConstraints() {
        [videoGridViewController, callInfoRootViewController].forEach { $0.view.fitInSuperview() }
    }

    fileprivate func minimizeOverlay() {
        delegate?.callViewControllerDidDisappear(self, for: conversation)
    }

    fileprivate func acceptDegradedCall() {
        guard let userSession = ZMUserSession.shared() else { return }

        userSession.enqueue({
            self.voiceChannel.continueByDecreasingConversationSecurity(userSession: userSession)
        }, completionHandler: {
            self.conversation?.joinCall()
        })
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func updateConfiguration() {
        callInfoConfiguration = CallInfoConfiguration(voiceChannel: voiceChannel,
                                                      preferedVideoPlaceholderState: preferedVideoPlaceholderState,
                                                      permissions: permissions,
                                                      cameraType: cameraType,
                                                      mediaManager: mediaManager,
                                                      userEnabledCBR: CallViewController.userEnabledCBR,
                                                      selfUser: ZMUser.selfUser())

        callInfoRootViewController.configuration = callInfoConfiguration
        videoConfiguration = VideoConfiguration(voiceChannel: voiceChannel)
        videoGridViewController.configuration = videoConfiguration
        updateOverlayAfterStateChanged()
        updateAppearance()
        updateIdleTimer()
    }

    private func updateIdleTimer() {
        let disabled = callInfoConfiguration.disableIdleTimer
        UIApplication.shared.isIdleTimerDisabled = disabled
        Log.calling.debug("Updated idle timer: \(disabled ? "disabled" : "enabled")")
    }

    private func updateAppearance() {
        view.backgroundColor = UIColor.from(scheme: .background, variant: callInfoConfiguration.variant)
    }

    fileprivate func alertVideoUnavailable() {
        guard voiceChannel.videoState == .stopped else { return }

        if !callInfoConfiguration.permissions.canAcceptVideoCalls {
            present(UIAlertController.cameraPermissionAlert(), animated: true)
        } else {
            presentLegacyAlertIfNeeded()
        }
    }

    private func presentLegacyAlertIfNeeded() {
        guard
            !voiceChannel.isConferenceCall,
            voiceChannel.isLegacyGroupVideoParticipantLimitReached
        else {
            return
        }
        let alert = UIAlertController.alertWithOKButton(
            title: "call.video.too_many.alert.title".localized,
            message: "call.video.too_many.alert.message".localized
        )

        present(alert, animated: true)
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

    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        updateConfiguration()
        hideOverlayAfterCallEstablishedIfNeeded()
        hapticsController.updateCallState(callState)
    }

}

extension CallViewController: ActiveSpeakersObserver {
    func callCenterDidChangeActiveSpeakers() {
        updateConfiguration()
    }
}

// MARK: - WireCallCenterCallParticipantObserver

extension CallViewController: WireCallCenterCallParticipantObserver {

    func callParticipantsDidChange(conversation: ZMConversation,
                                   participants: [CallParticipant]) {
        hapticsController.updateParticipants(participants)
        updateVideoGridPresentationModeIfNeeded(participants: participants)
        updateConfiguration() // Has to succeed updating the timestamps
    }

    private func updateVideoGridPresentationModeIfNeeded(participants: [CallParticipant]) {
        guard participants.filter(\.state.isConnected).count <= 2 else { return }

        voiceChannel.videoGridPresentationMode = .allVideoStreams
    }
}

extension CallViewController: AVSMediaManagerClientObserver {

    func mediaManagerDidChange(_ notification: AVSMediaManagerClientChangeNotification!) {
        updateConfiguration()
    }

}

extension CallViewController: MuteStateObserver {

    func callCenterDidChange(muted: Bool) {
        updateConfiguration()
    }

}

extension CallViewController {

    fileprivate func acceptCallIfPossible() {
        guard let conversation = self.conversation else {
            fatalError("Trying to accept a call for a voice channel without conversation.")
        }

        permissions.requestOrWarnAboutAudioPermission { audioGranted in
            guard audioGranted else {
                return self.voiceChannel.leave(userSession: ZMUserSession.shared()!, completion: nil)
            }

            conversation.confirmJoiningCallIfNeeded(alertPresenter: self, forceAlertModal: true) {
                self.checkVideoPermissions { videoGranted in
                    conversation.joinVoiceChannel(video: videoGranted)
                    self.disableVideoIfNeeded()
                }
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

extension CallViewController: NetworkQualityObserver {
    func callCenterDidChange(networkQuality: NetworkQuality) {
        updateConfiguration()
    }
}

extension CallViewController: CallInfoRootViewControllerDelegate {

    func infoRootViewController(_ viewController: CallInfoRootViewController, perform action: CallAction) {
        Log.calling.debug("request to perform call action: \(action)")
        guard let userSession = ZMUserSession.shared() else { return }

        switch action {
        case .continueDegradedCall: userSession.enqueue { self.voiceChannel.continueByDecreasingConversationSecurity(userSession: userSession) }
        case .acceptCall: acceptCallIfPossible()
        case .acceptDegradedCall: acceptDegradedCall()
        case .terminateCall: voiceChannel.leave(userSession: userSession, completion: nil)
        case .terminateDegradedCall: userSession.enqueue { self.voiceChannel.leaveAndDecreaseConversationSecurity(userSession: userSession) }
        case .toggleMuteState: voiceChannel.toggleMuteState(userSession: userSession)
        case .toggleSpeakerState: AVSMediaManager.sharedInstance().toggleSpeaker()
        case .minimizeOverlay: minimizeOverlay()
        case .toggleVideoState: toggleVideoState()
        case .alertVideoUnavailable: alertVideoUnavailable()
        case .flipCamera: toggleCameraAnimated()
        case .showParticipantsList: return // Handled in `CallInfoRootViewController`, we don't want to update.
        case .updateVideoGridPresentationMode(let mode): voiceChannel.videoGridPresentationMode = mode
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

        videoGridViewController.isCovered = show

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
        overlayTimer = .scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
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
