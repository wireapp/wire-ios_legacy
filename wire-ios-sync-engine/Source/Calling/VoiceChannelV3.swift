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

public enum VoiceChannelV3Error: LocalizedError {
    case switchToVideoNotAllowed

    public var errorDescription: String? {
        switch self {
        case .switchToVideoNotAllowed:
            return "Switch to video is not allowed"
        }
    }
}

public class VoiceChannelV3: NSObject, VoiceChannel {

    public var callCenter: WireCallCenterV3? {
        return self.conversation?.managedObjectContext?.zm_callCenter
    }

    /// The date and time of current call start
    public var callStartDate: Date? {
        return self.callCenter?.establishedDate
    }

    weak public var conversation: ZMConversation?

    public required init(conversation: ZMConversation) {
        self.conversation = conversation
        super.init()
    }

    public var participants: [CallParticipant] {
        return participants(ofKind: .all, activeSpeakersLimit: nil)
    }

    public func participants(ofKind kind: CallParticipantsListKind, activeSpeakersLimit limit: Int?) -> [CallParticipant] {
        guard
            let callCenter = callCenter,
            let conversationId = conversation?.avsIdentifier
        else { return [] }

        return callCenter.callParticipants(conversationId: conversationId, kind: kind, activeSpeakersLimit: limit)
    }

    public var state: CallState {
        guard
            let conversationId = conversation?.avsIdentifier,
            let callCenter = callCenter
        else { return .none }

        return callCenter.callState(conversationId: conversationId)
    }

    public var isVideoCall: Bool {
        guard
            let conversationId = conversation?.avsIdentifier,
            let callCenter = callCenter
        else { return false }

        return callCenter.isVideoCall(conversationId: conversationId)
    }

    public var isConstantBitRateAudioActive: Bool {
        guard
            let conversationId = conversation?.avsIdentifier,
            let callCenter = callCenter
        else { return false }

        return callCenter.isContantBitRate(conversationId: conversationId)
    }

    public var networkQuality: NetworkQuality {
        guard
            let conversationId = conversation?.avsIdentifier,
            let callCenter = self.callCenter
        else { return .normal }

        return callCenter.networkQuality(conversationId: conversationId)
    }

    public var initiator: UserType? {
        guard let context = conversation?.managedObjectContext,
              let convId = conversation?.avsIdentifier,
              let userId = callCenter?.initiatorForCall(conversationId: convId)
        else {
            return nil
        }
        return ZMUser.fetch(with: userId.identifier, domain: userId.domain, in: context)
    }

    public var videoState: VideoState {
        get {
            guard
                let conversationId = conversation?.avsIdentifier,
                let callCenter = callCenter
            else { return .stopped }

            return callCenter.videoState(conversationId: conversationId)
        }
        set {
            guard let conversationId = conversation?.avsIdentifier else { return }

            callCenter?.setVideoState(conversationId: conversationId, videoState: newValue)
        }
    }

    public func setVideoCaptureDevice(_ device: CaptureDevice) throws {
        guard let conversationId = conversation?.avsIdentifier else {
            throw VoiceChannelV3Error.switchToVideoNotAllowed
        }

        self.callCenter?.setVideoCaptureDevice(device, for: conversationId)
    }

    public var muted: Bool {
        get {
            return callCenter?.muted ?? false
        }
        set {
            callCenter?.muted = newValue
        }
    }

    public var isConferenceCall: Bool {
        guard
            let conversationId = conversation?.avsIdentifier,
            let callCenter = self.callCenter
        else { return false }

        return callCenter.isConferenceCall(conversationId: conversationId)
    }

    public var firstDegradedUser: UserType? {
        guard
            let conversationId = conversation?.avsIdentifier,
            let degradedUser = callCenter?.degradedUser(conversationId: conversationId)
        else {
            return conversation?.localParticipants.first(where: {
                !$0.isTrusted
            })
        }

        return degradedUser
    }

    public var videoGridPresentationMode: VideoGridPresentationMode {
        get {
            guard
                let conversationId = conversation?.avsIdentifier,
                let callCenter = callCenter
            else {
                return .allVideoStreams
            }
            return callCenter.videoGridPresentationMode(conversationId: conversationId)
        }
        set {
            guard let conversationId = conversation?.avsIdentifier else { return }
            callCenter?.setVideoGridPresentationMode(newValue, for: conversationId)
        }
    }
}

extension VoiceChannelV3: CallActions {

    public func mute(_ muted: Bool, userSession: ZMUserSession) {
        if userSession.callNotificationStyle == .callKit, #available(iOS 10.0, *) {
            userSession.callKitManager?.requestMuteCall(in: conversation!, muted: muted)
        } else {
            self.muted = muted
        }
    }

    public func continueByDecreasingConversationSecurity(userSession: ZMUserSession) {
        guard let conversation = conversation else { return }
        conversation.acknowledgePrivacyWarning(withResendIntent: false)
    }

    public func leaveAndDecreaseConversationSecurity(userSession: ZMUserSession) {
        guard let conversation = conversation else { return }
        conversation.acknowledgePrivacyWarning(withResendIntent: false)
        userSession.syncManagedObjectContext.performGroupedBlock {
            let conversationId = conversation.objectID
            if let syncConversation = (try? userSession.syncManagedObjectContext.existingObject(with: conversationId)) as? ZMConversation {
                userSession.syncStrategy?.callingRequestStrategy?.dropPendingCallMessages(for: syncConversation)
            }
        }
        leave(userSession: userSession, completion: nil)
    }

    public func join(video: Bool, userSession: ZMUserSession) -> Bool {
        if userSession.callNotificationStyle == .callKit, #available(iOS 10.0, *) {
            userSession.callKitManager?.requestJoinCall(in: conversation!, video: video)
            return true
        } else {
            return join(video: video)
        }
    }

    public func leave(userSession: ZMUserSession, completion: (() -> Void)?) {
        if userSession.callNotificationStyle == .callKit, #available(iOS 10.0, *) {
            userSession.callKitManager?.requestEndCall(in: conversation!, completion: completion)
        } else {
            leave()
            completion?()
        }
    }

    public func request(videoStreams: [AVSClient]) {
        guard let conversationId = conversation?.avsIdentifier else { return }

        callCenter?.requestVideoStreams(conversationId: conversationId, clients: videoStreams)
    }
}

extension VoiceChannelV3: CallActionsInternal {

    public func join(video: Bool) -> Bool {
        guard let conversation = conversation else { return false }

        var joined = false

        switch state {
        case .incoming(video: _, shouldRing: _, degraded: _):
            joined = callCenter?.answerCall(conversation: conversation, video: video) ?? false
        default:
            joined = callCenter?.startCall(conversation: conversation, video: video) ?? false
        }

        return joined
    }

    public func leave() {
        guard let conversationId = conversation?.avsIdentifier else { return }

        switch state {
        case .incoming:
            callCenter?.rejectCall(conversationId: conversationId)
        default:
            callCenter?.closeCall(conversationId: conversationId)
        }
    }

}

extension VoiceChannelV3: CallObservers {

    public func addNetworkQualityObserver(_ observer: NetworkQualityObserver) -> Any {
        return WireCallCenterV3.addNetworkQualityObserver(observer: observer, for: conversation!, context: conversation!.managedObjectContext!)
    }

    /// Add observer of voice channel state. Returns a token which needs to be retained as long as the observer should be active.
    public func addCallStateObserver(_ observer: WireCallCenterCallStateObserver) -> Any {
        return WireCallCenterV3.addCallStateObserver(observer: observer, for: conversation!, context: conversation!.managedObjectContext!)
    }

    /// Add observer of voice channel participants. Returns a token which needs to be retained as long as the observer should be active.
    public func addParticipantObserver(_ observer: WireCallCenterCallParticipantObserver) -> Any {
        return WireCallCenterV3.addCallParticipantObserver(observer: observer, for: conversation!, context: conversation!.managedObjectContext!)
    }

    /// Add observer of voice gain. Returns a token which needs to be retained as long as the observer should be active.
    public func addVoiceGainObserver(_ observer: VoiceGainObserver) -> Any {
        return WireCallCenterV3.addVoiceGainObserver(observer: observer, for: conversation!, context: conversation!.managedObjectContext!)
    }

    /// Add observer of constant bit rate audio. Returns a token which needs to be retained as long as the observer should be active.
    public func addConstantBitRateObserver(_ observer: ConstantBitRateAudioObserver) -> Any {
        return WireCallCenterV3.addConstantBitRateObserver(observer: observer, context: conversation!.managedObjectContext!)
    }

    /// Add observer of the state of all voice channels. Returns a token which needs to be retained as long as the observer should be active.
    public class func addCallStateObserver(_ observer: WireCallCenterCallStateObserver, userSession: ZMUserSession) -> Any {
        return WireCallCenterV3.addCallStateObserver(observer: observer, context: userSession.managedObjectContext)
    }

    /// Add observer of the mute state. Returns a token which needs to be retained as long as the observer should be active.
    public func addMuteStateObserver(_ observer: MuteStateObserver) -> Any {
        return WireCallCenterV3.addMuteStateObserver(observer: observer, context: conversation!.managedObjectContext!)
    }

    public func addActiveSpeakersObserver(_ observer: ActiveSpeakersObserver) -> Any {
        return WireCallCenterV3.addActiveSpeakersObserver(observer: observer, context: conversation!.managedObjectContext!)
    }
}
