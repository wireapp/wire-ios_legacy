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

private let log = ZMSLog(tag: "calling")

final class CallViewController: UIViewController {
    
    private let actionsView = CallActionsView()
    private let statusViewController: CallStatusViewController
    
    fileprivate var isSwitchingCamera = false
    fileprivate var currentCaptureDevice: CaptureDevice = .front

    var variant: ColorSchemeVariant = .dark
    fileprivate var properties: CallProperties
    
    
    init(properties: CallProperties) {
        self.properties = properties
        statusViewController = CallStatusViewController(properties: properties, variant: variant)
        super.init(nibName: nil, bundle: nil)
        actionsView.delegate = self
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateActionsState() {
        guard let manager = AVSMediaManager.sharedInstance() else { return }
        let input = CallActionsViewInput(mediaManager: manager, properties: properties)
        actionsView.update(with: input)
    }
}

extension CallViewController: CallActionsViewDelegate {
    func callActionsView(_ callActionsView: CallActionsView, perform action: CallActionsViewAction) {
        guard let manager = AVSMediaManager.sharedInstance(), let session = ZMUserSession.shared() else { return }
        log.debug("\(action) button tapped")

        switch action {
        case .toggleMuteState: properties.conversation?.voiceChannel?.mute(manager.isMicrophoneMuted, userSession: session)
        case .toggleVideoState: break // TODO
        case .toggleSpeakerState: manager.toggleSpeaker()
        case .acceptCall: properties.conversation?.joinCall()
        case .terminateCall: properties.conversation?.voiceChannel?.leave(userSession: session)
        case .flipCamera: toggleCaptureDevice() // TODO: Tell video view to animate / flip
        }
        
        updateActionsState()
    }
    
    func toggleCaptureDevice() {
        do {
            let device = currentCaptureDevice == .front ? CaptureDevice.back : .front
            try properties.conversation?.voiceChannel?.setVideoCaptureDevice(device: device)
            currentCaptureDevice = device
        } catch {
            log.error("failed to toggle capture device: \(error)")
        }
    }
}

extension CallState {
    var isTerminating: Bool {
        guard case .terminating = self else { return false }
        return true
    }
    
    var canToggleMediaType: Bool {
        return .established == self
    }
    
    var canAccept: Bool {
        guard case .incoming = self else { return false }
        return true
    }
}

struct CallActionsViewInput: CallActionsViewInputType {
    
    var isMuted: Bool
    var isAudioCall: Bool
    var canToggleMediaType: Bool
    var isTerminating: Bool
    var canAccept: Bool
    var mediaState: MediaState
    
    init(mediaManager: AVSMediaManager, properties: CallProperties) {
        isMuted = mediaManager.isMicrophoneMuted
        isAudioCall = !properties.isVideoCall
        canToggleMediaType = properties.state.canToggleMediaType
        isTerminating = properties.state.isTerminating
        canAccept = properties.state.canAccept
        mediaState = CallActionsViewInput.mediaState(for: mediaManager, properties: properties)
    }
    
    private static func mediaState(for mediaManager: AVSMediaManager, properties: CallProperties) -> MediaState {
        guard !properties.isVideoCall else { return .sendingVideo } // TODO: Adjust check whether we're sending video
        return .notSendingVideo(speakerEnabled: mediaManager.isSpeakerEnabled)
    }

}
