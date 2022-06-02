//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@objc(ZMCaptureDevice)
public enum CaptureDevice: Int {
    case front
    case back

    var deviceIdentifier: String {
        switch  self {
        case .front:
            return "com.apple.avfoundation.avcapturedevice.built-in_video:1"
        case .back:
            return "com.apple.avfoundation.avcapturedevice.built-in_video:0"
        }
    }
}

public protocol VoiceChannel: AnyObject, CallProperties, CallActions, CallActionsInternal, CallObservers {

    init(conversation: ZMConversation)

}

public protocol CallProperties: NSObjectProtocol {

    var state: CallState { get }

    var conversation: ZMConversation? { get }

    /// The date and time of current call start
    var callStartDate: Date? { get }

    /// Voice channel participants. May be a subset of conversation participants.
    var participants: [CallParticipant] { get }

    /// Voice channel participants with a limit on participants flagged as active.
    func participants(ofKind kind: CallParticipantsListKind, activeSpeakersLimit limit: Int?) -> [CallParticipant]

    /// Voice channel is sending audio using a contant bit rate
    var isConstantBitRateAudioActive: Bool { get }
    var isVideoCall: Bool { get }
    var initiator: UserType? { get }
    var videoState: VideoState { get set }
    var networkQuality: NetworkQuality { get }
    var muted: Bool { get set }

    var isConferenceCall: Bool { get }

    var firstDegradedUser: UserType? { get }
    var videoGridPresentationMode: VideoGridPresentationMode { get set }

    func setVideoCaptureDevice(_ device: CaptureDevice) throws
}

public protocol CallActions: NSObjectProtocol {

    func mute(_ muted: Bool, userSession: ZMUserSession)
    func join(video: Bool, userSession: ZMUserSession) -> Bool
    func leave(userSession: ZMUserSession, completion: (() -> Void)?)
    func continueByDecreasingConversationSecurity(userSession: ZMUserSession)
    func leaveAndDecreaseConversationSecurity(userSession: ZMUserSession)
    func request(videoStreams: [AVSClient])

}

@objc
public protocol CallActionsInternal: NSObjectProtocol {

    func join(video: Bool) -> Bool
    func leave()

}

public protocol CallObservers: NSObjectProtocol {

    /// Add observer of voice channel state. Returns a token which needs to be retained as long as the observer should be active.
    func addCallStateObserver(_ observer: WireCallCenterCallStateObserver) -> Any

    /// Add observer of voice channel participants. Returns a token which needs to be retained as long as the observer should be active.
    func addParticipantObserver(_ observer: WireCallCenterCallParticipantObserver) -> Any

    /// Add observer of voice gain. Returns a token which needs to be retained as long as the observer should be active.
    func addVoiceGainObserver(_ observer: VoiceGainObserver) -> Any

    /// Add observer of constant bit rate audio. Returns a token which needs to be retained as long as the observer should be active.
    func addConstantBitRateObserver(_ observer: ConstantBitRateAudioObserver) -> Any

    /// Add observer of network quality. Returns a token which needs to be retained as long as the observer should be active.
    func addNetworkQualityObserver(_ observer: NetworkQualityObserver) -> Any

    /// Add observer of the mute state. Returns a token which needs to be retained as long as the observer should be active.
    func addMuteStateObserver(_ observer: MuteStateObserver) -> Any

    func addActiveSpeakersObserver(_ observer: ActiveSpeakersObserver) -> Any

    /// Add observer of the state of all voice channels. Returns a token which needs to be retained as long as the observer should be active.
    static func addCallStateObserver(_ observer: WireCallCenterCallStateObserver, userSession: ZMUserSession) -> Any
}
