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

class CallViewController: UIViewController {
    
    var observerTokens: [Any] = []
    let voiceChannel: VoiceChannel
    let videoConfiguration: VideoConfiguration
    let callInfoConfiguration: CallInfoConfiguration
    let callInfoViewController: CallInfoViewController
    let videoGridViewController: VideoGridViewController
    weak var dismisser: ViewControllerDismisser? = nil
    
    var conversation: ZMConversation? {
        return voiceChannel.conversation
    }
    
    init(voiceChannel: VoiceChannel) {
        self.voiceChannel = voiceChannel
        videoConfiguration = VideoConfiguration(voiceChannel: voiceChannel)
        callInfoConfiguration = CallInfoConfiguration(voiceChannel: voiceChannel)
        callInfoViewController = CallInfoViewController(configuration: callInfoConfiguration)
        videoGridViewController = VideoGridViewController(configuration: videoConfiguration)
        
        super.init(nibName: nil, bundle: nil)

        callInfoViewController.delegate = self
        observerTokens += [voiceChannel.addCallStateObserver(self)]
        observerTokens += [voiceChannel.addParticipantObserver(self)]
        
        updateNavigationItem()
    }
    
    override func viewDidLoad() {
        setupViews()
        createConstraints()
    }
    
    private func setupViews() {
        addChildViewController(videoGridViewController)
        view.addSubview(videoGridViewController.view)
        videoGridViewController.didMove(toParentViewController: self)
        
        addChildViewController(callInfoViewController)
        view.addSubview(callInfoViewController.view)
        callInfoViewController.didMove(toParentViewController: self)
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            videoGridViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoGridViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoGridViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            videoGridViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            callInfoViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            callInfoViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            callInfoViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            callInfoViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func updateNavigationItem() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(icon: .downArrow,
                                                                target: self,
                                                                action: #selector(minimizeCallOverlay(_:)))
    }
    
    @objc dynamic func minimizeCallOverlay(_ sender: AnyObject!) {
        dismisser?.dismiss(viewController: self, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateConfiguration() {
        callInfoViewController.configuration = callInfoConfiguration
        videoGridViewController.configuration = videoConfiguration
    }
    
}

extension CallViewController: WireCallCenterCallStateObserver {
    
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?) {
        updateConfiguration()
    }
    
}

extension CallViewController: VoiceChannelParticipantObserver {
    
    func voiceChannelParticipantsDidChange(_ changeInfo: VoiceChannelParticipantNotification) {
        updateConfiguration()
    }
    
}

extension CallViewController: CallInfoViewControllerDelegate {
    
    func infoViewController(_ viewController: CallInfoViewController, perform action: CallAction) {
        Calling.log.debug("request to perform call action: \(action)")
        guard let userSession = ZMUserSession.shared() else { return }
        
        switch action {
        case .acceptCall: conversation?.joinCall()
        case .terminateCall: voiceChannel.leave(userSession: userSession)
        case .toggleMuteState: voiceChannel.toggleMuteState(userSession: userSession)
        case .toggleSpeakerState: AVSMediaManager.sharedInstance().toggleSpeaker()
        case .showParticipantsList: presentParticipantsList()
        default: break
        }
        
        updateConfiguration()
    }
    
    private func presentParticipantsList() {
        let participantsList = CallParticipantsViewController(scrollableWithConfiguration: callInfoConfiguration)
        navigationController?.pushViewController(participantsList, animated: true)
    }

}

extension VoiceChannel {
    func toggleMuteState(userSession: ZMUserSession) {
        mute(!AVSMediaManager.sharedInstance().isMicrophoneMuted, userSession: userSession)
    }
}

struct VideoConfiguration {
    
    let voiceChannel: VoiceChannel
    
}

extension VideoConfiguration: VideoGridConfiguration {
    
    var floatingVideoStream: UUID? {
        return nil
    }
    
    var videoStreams: [UUID] {
        let otherParticipants: [UUID] = voiceChannel.participants.flatMap({ user in
            guard let user = user as? ZMUser else { return nil }
            
            if case let .connected(videoState) = voiceChannel.state(forParticipant: user) {
                if case .started = videoState {
                    return user.remoteIdentifier
                }
            }
            
            return nil
        })
        
        return [ZMUser.selfUser().remoteIdentifier] + otherParticipants
    }
    
}

struct CallInfoConfiguration  {
    let voiceChannel: VoiceChannel
}

extension CallInfoConfiguration: CallInfoViewControllerInput {
    
    var accessoryType: CallInfoViewControllerAccessoryType {
        
        guard !voiceChannel.isVideoCall else { return .none }
        
        switch voiceChannel.state {
        case .incoming(_, shouldRing: true, _):
            if let initiator = voiceChannel.initiator {
                return .avatar(initiator)
            } else {
                return .none
            }
        case .answered, .establishedDataChannel, .outgoing:
            if voiceChannel.conversation?.conversationType == .oneOnOne, let remoteParticipant = voiceChannel.conversation?.firstActiveParticipantOtherThanSelf() {
                return .avatar(remoteParticipant)
            } else {
                return .none
            }
        case .unknown, .none, .terminating, .established, .incoming(_, shouldRing: false, _):
            if voiceChannel.conversation?.conversationType == .group {
                let participants = voiceChannel.participants.flatMap({ $0 as? ZMUser }).map({ user in
                    CallParticipantsCellConfiguration.callParticipant(user: user, sendsVideo: false)
                })
                
                return .participantsList(participants)
            } else if let remoteParticipant = voiceChannel.conversation?.firstActiveParticipantOtherThanSelf() {
                return .avatar(remoteParticipant)
            } else {
                return .none
            }
        }
    }
    
    var canToggleMediaType: Bool {
        return voiceChannel.state == .established
    }
    
    var isMuted: Bool {
        return AVSMediaManager.sharedInstance().isMicrophoneMuted
    }
    
    var isTerminating: Bool {
        if case .terminating = voiceChannel.state {
            return true
        } else {
            return false
        }
    }
    
    var canAccept: Bool {
        switch voiceChannel.state {
        case .incoming(video: _, shouldRing: true, degraded: false): return true
        default: return false
        }
    }
    
    var mediaState: MediaState {
        return MediaState.notSendingVideo(speakerEnabled: AVSMediaManager.sharedInstance().isSpeakerEnabled)
    }
    
    var state: CallStatusViewState {
        switch voiceChannel.state {
        case .incoming(_ , shouldRing: true, _):
            return CallStatusViewState.ringingIncoming(name: voiceChannel.initiator?.displayName ?? "")
        case .outgoing:
            return CallStatusViewState.ringingOutgoing
        case .answered, .establishedDataChannel:
            return CallStatusViewState.connecting
        case .established:
            return CallStatusViewState.established(duration: -(voiceChannel.callStartDate?.timeIntervalSinceNow ?? 0))
        case .terminating, .incoming(_ , shouldRing: false, _):
            return .terminating
        case .none, .unknown:
            return CallStatusViewState.none
        }
    }
    
    var isConstantBitRate: Bool {
        return voiceChannel.isConstantBitRateAudioActive
    }
    
    var title: String {
        return voiceChannel.conversation?.displayName ?? ""
    }
    
    var isVideoCall: Bool {
        return voiceChannel.isVideoCall
    }
    
    var variant: ColorSchemeVariant {
        return ColorScheme.default().variant
    }

}
