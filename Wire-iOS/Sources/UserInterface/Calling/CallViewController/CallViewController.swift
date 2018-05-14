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

import Foundation

final class CallViewController: UIViewController {
    
    weak var dismisser: ViewControllerDismisser? = nil
    
    fileprivate let voiceChannel: VoiceChannel
    fileprivate let callInfoConfiguration: CallInfoConfiguration
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
    
    init(voiceChannel: VoiceChannel, mediaManager: AVSMediaManager = .sharedInstance()) {
        self.voiceChannel = voiceChannel
        videoConfiguration = VideoConfiguration(voiceChannel: voiceChannel, mediaManager: mediaManager)
        callInfoConfiguration = CallInfoConfiguration(voiceChannel: voiceChannel)
        callInfoRootViewController = CallInfoRootViewController(configuration: callInfoConfiguration)
        videoGridViewController = VideoGridViewController(configuration: videoConfiguration)
        super.init(nibName: nil, bundle: nil)
        callInfoRootViewController.delegate = self
        AVSMediaManagerClientChangeNotification.add(self)
        observerTokens += [voiceChannel.addCallStateObserver(self), voiceChannel.addParticipantObserver(self)]
        proximityMonitorManager?.stateChanged = proximityStateDidChange
    }
    
    deinit {
        AVSMediaManagerClientChangeNotification.remove(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        updateConfiguration()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        proximityMonitorManager?.startListening()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        proximityMonitorManager?.stopListening()
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateConfiguration() {
        callInfoRootViewController.configuration = callInfoConfiguration
        videoGridViewController.configuration = videoConfiguration
        updateAppearance()
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
        voiceChannel.videoState = voiceChannel.videoState.toggledState
        updateConfiguration()
    }
    
    fileprivate func toggleCameraAnimated() {
        // TODO: Animations
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
        startInitialOverlayTimerIfNeeded()
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

extension CallViewController: CallInfoRootViewControllerDelegate {
    
    func infoRootViewController(_ viewController: CallInfoRootViewController, perform action: CallAction) {
        Calling.log.debug("request to perform call action: \(action)")
        guard let userSession = ZMUserSession.shared() else { return }
        
        switch action {
        case .acceptCall: conversation?.joinCall()
        case .terminateCall: voiceChannel.leave(userSession: userSession)
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

extension CallViewController {
    
    private var isOverlayVisible: Bool {
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
            completion: nil
        )
    }
    
    fileprivate func startInitialOverlayTimerIfNeeded() {
        guard nil == overlayTimer, canHideOverlay else { return }
        startOverlayTimer()
    }
    
    fileprivate func startOverlayTimer() {
        stopOverlayTimer()
        overlayTimer = .allVersionCompatibleScheduledTimer(withTimeInterval: 4, repeats: false) { [animateOverlay] _ in
            animateOverlay(false)
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
