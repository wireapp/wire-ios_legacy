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

import UIKit
import Cartography
import Classy

fileprivate let zmLog = ZMSLog(tag: "calling")

class VoiceChannelViewController: UIViewController {
    
    let conversation : ZMConversation
    var voiceChannelView : VoiceChannelOverlay!
    var blurEffectView : UIVisualEffectView!
    var participantsController : VoiceChannelParticipantsController?
    
    var callStateObserverToken : WireCallCenterObserverToken?
    var receivedVideoObserverToken : WireCallCenterObserverToken?
    
    fileprivate var isSwitchingCamera = false
    fileprivate var currentCaptureDevice: CaptureDevice = .front
    fileprivate var previousCallState : CallState = .none
    fileprivate var callDurationTimer : Timer?
    fileprivate var outgoingVideoWasActiveBeforeEnteringEnteringBackground = false
    
    override func loadView() {
        voiceChannelView = VoiceChannelOverlay(frame: CGRect.zero, callingConversation: conversation)
        voiceChannelView.translatesAutoresizingMaskIntoConstraints = false
        voiceChannelView.delegate = self
        voiceChannelView.hidesSpeakerButton = !isMultipleAudioOutputOptionsAvailable
        
        blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurEffectView.contentView.addSubview(voiceChannelView)
        
        constrain(voiceChannelView) { voiceChannelView in
            voiceChannelView.edges == voiceChannelView.superview!.edges
        }
        
        self.view = blurEffectView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        voiceChannelView.callDuration = 0
        voiceChannelView.remoteIsSendingVideo = conversation.voiceChannel?.isVideoCall ?? false
        
        callStateObserverToken = conversation.voiceChannel?.addCallStateObserver(self)
        receivedVideoObserverToken = conversation.voiceChannel?.addReceivedVideoObserver(self)
        AVSMediaManagerClientChangeNotification.add(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(voiceChannelEnabledCBR), name: WireCallCenterV3.cbrNotificationName, object: nil)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delegate = self
        view.addGestureRecognizer(doubleTapRecognizer)
        
        createParticipantsControllerIfNecessary()
        
        if let callState = conversation.voiceChannel?.state {
            updateView(for: callState)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let mediaManager = AVSProvider.shared.mediaManager else { return }
        
        voiceChannelView.muted = mediaManager.isMicrophoneMuted
        voiceChannelView.speakerActive = mediaManager.isSpeakerEnabled
        voiceChannelView.outgoingVideoActive = conversation.voiceChannel?.isVideoCall ?? false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.voiceChannelView.participantsCollectionViewLayout.invalidateLayout()
        })
    }
    
    deinit {
        stopCallDurationTimer()
        AVSMediaManagerClientChangeNotification.remove(self)
        NotificationCenter.default.removeObserver(self)
    }

    init(conversation: ZMConversation) {
        self.conversation = conversation
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isMultipleAudioOutputOptionsAvailable : Bool {
        return UIDevice.current.userInterfaceIdiom == .phone // TODO determine by asking AVAudioSession / AVS
    }
    
    func createParticipantsControllerIfNecessary() {
        guard participantsController == nil, let callState = conversation.voiceChannel?.state else { return }
        
        switch callState {
        case .established, .establishedDataChannel:
            participantsController = VoiceChannelParticipantsController(conversation: conversation, collectionView: voiceChannelView.participantsCollectionView)
        default:
            break
        }
    }
    
    func onDoubleTap(_ gestureRecognizer : UITapGestureRecognizer) {
        guard let videoView = voiceChannelView.videoView else { return }
        
        videoView.shouldFill = !videoView.shouldFill;
    }
    
}

extension VoiceChannelViewController : UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension VoiceChannelViewController : VoiceChannelOverlayDelegate {
    
    func acceptButtonTapped() {
        zmLog.debug("acceptButtonTapped")
        conversation.joinCall()
    }
    
    func acceptDegradedButtonTapped() {
        zmLog.debug("acceptDegradedButtonTapped")
        
        guard let userSession = ZMUserSession.shared() else { return }
        
        let alreadyAnswered = conversation.voiceChannel?.state == CallState.answered(degraded: true)
        
        userSession.enqueueChanges({ 
            self.conversation.voiceChannel?.continueByDecreasingConversationSecurity(userSession: userSession)
        }) {
            if !alreadyAnswered {
                self.conversation.joinCall()
            }
        }
    }
    
    func makeDegradedCallTapped() {
        zmLog.debug("makeDegradedCallTapped")
        
        guard let userSession = ZMUserSession.shared() else { return }
        
        userSession.enqueueChanges {
            self.conversation.voiceChannel?.continueByDecreasingConversationSecurity(userSession: userSession)
        }
    }
    
    func acceptVideoButtonTapped() {
        zmLog.debug("acceptVideoButtonTapped")
        conversation.joinCall()
    }
    
    func ignoreButtonTapped() {
        zmLog.debug("ignoreButtonTapped")
        
        guard let userSession = ZMUserSession.shared() else { return }
        
        conversation.voiceChannel?.ignore(userSession: userSession)
    }
    
    func cancelButtonTapped() {
        zmLog.debug("cancelButtonTapped")
        
        guard let userSession = ZMUserSession.shared() else { return }
        
        conversation.voiceChannel?.leaveAndKeepDegradedConversationSecurity(userSession: userSession)
    }
    
    func leaveButtonTapped() {
        zmLog.debug("leaveButtonTapped")
        
        guard let userSession = ZMUserSession.shared() else { return }
        
        conversation.voiceChannel?.leave(userSession: userSession)
    }
    
    func muteButtonTapped() {
        zmLog.debug("muteButtonTapped")
        
        guard let mediaManager = AVSProvider.shared.mediaManager else { return }
        
        mediaManager.isMicrophoneMuted = !mediaManager.isMicrophoneMuted
        voiceChannelView.muted = mediaManager.isMicrophoneMuted
    }
    
    func speakerButtonTapped() {
        zmLog.debug("speakerButtonTapped")
        
        guard let mediaManager = AVSProvider.shared.mediaManager else { return }
        
        mediaManager.isSpeakerEnabled = !mediaManager.isSpeakerEnabled
        voiceChannelView.speakerActive = mediaManager.isSpeakerEnabled
    }
    
    func videoButtonTapped() {
        zmLog.debug("videoButtonTapped")
        
        do {
            let active = !voiceChannelView.outgoingVideoActive
            try conversation.voiceChannel?.toggleVideo(active: active)
            voiceChannelView.outgoingVideoActive = active
        } catch {
            zmLog.error("failed to toggle video: \(error)")
        }
    }
    
    func switchCameraButtonTapped() {
        zmLog.debug("switchCameraButtonTapped")
        
        if (self.isSwitchingCamera) {
            return;
        }
        
        isSwitchingCamera = true
        
        voiceChannelView.animateCameraChange(changeAction: { 
            self.toggleCaptureDevice()
        }) { (completed) in
            // Intentional delay
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: { 
                self.isSwitchingCamera = false
            })
        }
    }
    
    func toggleCaptureDevice() {
        
        let newCaptureDevice : CaptureDevice = (currentCaptureDevice == CaptureDevice.front) ? .back : .front
        
        do {
            try conversation.voiceChannel?.setVideoCaptureDevice(device: newCaptureDevice)
            currentCaptureDevice = newCaptureDevice
        } catch {
            zmLog.error("failed to toggle capture device: \(error)")
        }
        
    }
    
}

extension VoiceChannelViewController : WireCallCenterCallStateObserver, ReceivedVideoObserver {
    
    func callCenterDidChange(callState: CallState, conversationId: UUID, userId: UUID?, timeStamp: Date?) {
        updateIdleTimer(for: callState)
        updateCallDurationTimer(for: callState)
        updateView(for: callState)
    }
    
    func updateIdleTimer(for callState : CallState) {
        switch callState {
        case .incoming, .outgoing(degraded: false), .established, .establishedDataChannel:
            if conversation.voiceChannel?.isVideoCall ?? false {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        case .terminating:
            UIApplication.shared.isIdleTimerDisabled = false
            
        default:
            break
        }
    }
    
    func updateCallDurationTimer(for callState: CallState) {
        switch callState {
        case .established:
            startCallDurationTimer()
        case .terminating:
            stopCallDurationTimer()
        default:
            break
        }
    }
    
    func startCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateCallDuration), userInfo: nil, repeats: true)
    }
    
    func stopCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
    }
    
    func updateCallDuration() {
        if let callStartDate = self.conversation.voiceChannel?.callStartDate {
            self.voiceChannelView.callDuration = callStartDate.timeIntervalSinceNow
        } else {
            self.voiceChannelView.callDuration = 0
        }
    }
    
    func updateView(for callState : CallState) {
        defer {
            previousCallState = callState
        }
        
        voiceChannelView.transition(to: viewState(for: callState, previousCallState: previousCallState))
        voiceChannelView.speakerActive = AVSProvider.shared.mediaManager?.isSpeakerEnabled ?? false
    }
    
    func viewState(for callState : CallState, previousCallState : CallState) -> VoiceChannelOverlayState {
        
        switch callState {
        case .incoming(video: _, shouldRing: _, degraded: let degraded):
            if degraded {
                return .incomingCallDegraded
            } else {
                return .incomingCall
            }
        case .outgoing(degraded: let degraded):
            if degraded {
                return .outgoingCallDegraded
            } else {
                return .outgoingCall
            }
        case .answered(degraded: let degraded):
            if degraded {
                return .incomingCallDegraded
            } else {
                switch previousCallState {
                case .outgoing:
                    return .outgoingCall
                default:
                    return .joiningCall
                }
            }
        case .established, .establishedDataChannel:
            return .connected
        default:
            return .invalid
        }
        
    }
    
    func callCenterDidChange(receivedVideoState: ReceivedVideoState) {
        voiceChannelView.incomingVideoActive = receivedVideoState == .started
        voiceChannelView.remoteIsSendingVideo = receivedVideoState == .started
        voiceChannelView.lowBandwidth = receivedVideoState == .badConnection       
    }
    
}

extension VoiceChannelViewController : AVSMediaManagerClientObserver {
    
    func mediaManagerDidChange(_ notification: AVSMediaManagerClientChangeNotification!) {
        if notification.microphoneMuteChanged {
            voiceChannelView.muted = notification.manager.isMicrophoneMuted
        }
        
        if notification.speakerMuteChanged {
            voiceChannelView.speakerActive = notification.manager.isSpeakerEnabled
        }
    }
    
}

extension VoiceChannelViewController {
    
    func applicationWillResignActive() {
        guard conversation.voiceChannel?.isVideoCall ?? false else { return }
        
        outgoingVideoWasActiveBeforeEnteringEnteringBackground =  voiceChannelView.outgoingVideoActive
        
        try? conversation.voiceChannel?.toggleVideo(active: false)
    }
    
    func applicationDidBecomeActive() {
        guard conversation.voiceChannel?.isVideoCall ?? false else { return }
        
        if outgoingVideoWasActiveBeforeEnteringEnteringBackground {
            try? conversation.voiceChannel?.toggleVideo(active: true)
        }
    }
    
    func voiceChannelEnabledCBR() {
        voiceChannelView.constantBitRate = true
    }
        
}
