/*
 * Wire
 * Copyright (C) 2021 Wire Swiss GmbH
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import avs

private let zmLog = ZMSLog(tag: "calling")

/**
 * WireCallCenter is used for making Wire calls and observing their state. There can only be one instance of the
 * WireCallCenter.
 *
 * Thread safety: WireCallCenter instance methods should only be called from the main thread, class method can be
 * called from any thread.
 */
public class WireCallCenterV3: NSObject {

    /// The maximum number of participants for a legacy video call.

    let legacyVideoParticipantsLimit = 4

    // MARK: - Properties

    /// The selfUser remoteIdentifier
    let selfUserId: AVSIdentifier

    /// The object that controls media flow.
    let flowManager: FlowManagerType

    /// The object to use to record stats about the call.
    let analytics: AnalyticsType?

    /// The bridge to use to communicate with and receive events from AVS.
    var avsWrapper: AVSWrapperType!

    /// The Core Data context to use to coordinate events.
    weak var uiMOC: NSManagedObjectContext?

    /// The object that performs network requests when the call center requests them.
    weak var transport: WireCallCenterTransport?

    // MARK: - Calling State

    /**
     * The date when the call was established (Participants can talk to each other).
     * - note: This property is only valid when the call state is `.established`.
     */

    var establishedDate: Date?

    /**
     * Whether we use constant bit rate for calls.
     * - note: Changing this property after the call has started has no effect.
     */

    var useConstantBitRateAudio: Bool = false

    var usePackagingFeatureConfig: Bool = false

    var muted: Bool {
        get {
            return avsWrapper.muted
        }
        set {
            avsWrapper.muted = newValue
        }
    }

    /// The snaphot of the call state for each non-idle conversation.
    var callSnapshots: [AVSIdentifier: CallSnapshot] = [:]

    /// Used to collect incoming events (e.g. from fetching the notification stream) until AVS is ready to process them.
    var bufferedEvents : [(event: CallEvent, completionHandler: () -> Void)]  = []

    /// Set to true once AVS calls the ReadyHandler. Setting it to `true` forwards all previously buffered events to AVS.
    var isReady: Bool = false {
        didSet {
            VoIPPushHelper.isAVSReady = isReady

            if isReady {
                bufferedEvents.forEach { (item: (event: CallEvent, completionHandler: () -> Void)) in
                    let (event, completionHandler) = item
                    handleCallEvent(event, completionHandler: completionHandler)
                }
                bufferedEvents = []
            }
        }
    }

    /// Used to store AVS completions for the clients requests. AVS will only request the list of clients
    /// once, but we may need to provide AVS with an updated list during the call.
    var clientsRequestCompletionsByConversationId = [AVSIdentifier: (String) -> Void]()

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    // MARK: - Initialization

    deinit {
        avsWrapper.close()
    }

    /**
     * Creates a call center with the required details.
     * - parameter userId: The identifier of the current signed-in user.
     * - parameter clientId: The identifier of the current client on the user's account.
     * - parameter avsWrapper: The bridge to use to communicate with and receive events from AVS.
     * If you don't specify one, a default object will be created. Defaults to `nil`.
     * - parameter uiMOC: The Core Data context to use to coordinate events.
     * - parameter flowManager: The object that controls media flow.
     * - parameter analytics: The object to use to record stats about the call. Defaults to `nil`.
     * - parameter transport: The object that performs network requests when the call center requests them.
     */

    public required init(userId: AVSIdentifier,
                         clientId: String,
                         avsWrapper: AVSWrapperType? = nil,
                         uiMOC: NSManagedObjectContext,
                         flowManager: FlowManagerType,
                         analytics: AnalyticsType? = nil,
                         transport: WireCallCenterTransport) {

        self.selfUserId = userId
        self.uiMOC = uiMOC
        self.flowManager = flowManager
        self.analytics = analytics
        self.transport = transport

        super.init()

        let observer = Unmanaged.passUnretained(self).toOpaque()
        self.avsWrapper = avsWrapper ?? AVSWrapper(userId: userId, clientId: clientId, observer: observer)
    }

}

// MARK: - Snapshots

extension WireCallCenterV3 {

    /// Removes the participantSnapshot and remove the conversation from the list of ignored conversations.
    func clearSnapshot(conversationId: AVSIdentifier) {
        callSnapshots.removeValue(forKey: conversationId)
        clientsRequestCompletionsByConversationId.removeValue(forKey: conversationId)
    }

    /**
     * Creates a snapshot for the specified call and adds it to the `callSnapshots` array.
     * - parameter callState:
     * - parameter members: The current members of the call.
     * - parameters callStarter: The ID of the user that started the call.
     * - parameter video: Whether the call is a video call.
     * - parameter conversationId: The identifier of the conversation that hosts the call.
     */

    func createSnapshot(callState: CallState, members: [AVSCallMember], callStarter: AVSIdentifier, video: Bool, for conversationId: AVSIdentifier, isConferenceCall: Bool) {
        guard
            let moc = uiMOC,
            let conversation = ZMConversation.fetch(with: conversationId.identifier,
                                                    domain: conversationId.domain,
                                                    in: moc)
        else {
            return
        }

        let callParticipants = CallParticipantsSnapshot(conversationId: conversationId, members: members, callCenter: self)
        let token = ConversationChangeInfo.add(observer: self, for: conversation)
        let group = conversation.conversationType == .group

        callSnapshots[conversationId] = CallSnapshot(
            callParticipants: callParticipants,
            callState: callState,
            callStarter: callStarter,
            isVideo: video,
            isGroup: group,
            isConstantBitRate: false,
            videoState: video ? .started : .stopped,
            networkQuality: .normal,
            isConferenceCall: isConferenceCall,
            degradedUser: nil,
            activeSpeakers: [],
            videoGridPresentationMode: .allVideoStreams,
            conversationObserverToken: token
        )
    }

}

// MARK: - State Helpers

extension WireCallCenterV3 {

    /// All non idle conversations and their corresponding call state.
    public var nonIdleCalls: [AVSIdentifier: CallState] {
        return callSnapshots.mapValues({ $0.callState })
    }

    /// The list of conversation with established calls.
    public var activeCalls: [AVSIdentifier: CallState] {
        return nonIdleCalls.filter { _, callState in
            switch callState {
            case .established, .establishedDataChannel:
                return true
            default:
                return false
            }
        }
    }

    /**
     * Checks the state of video calling in the conversation.
     * - parameter conversationId: The identifier of the conversation to check the state of.
     * - returns: Whether the conversation hosts a video call.
     */

    public func isVideoCall(conversationId: AVSIdentifier) -> Bool {
        return callSnapshots[conversationId]?.isVideo ?? false
    }

    /**
     * Checks the call bitrate type used in the conversation.
     * - parameter conversationId: The identifier of the conversation to check the state of.
     * - returns: Whether the call is being made with a constant bitrate.
     */

    public func isContantBitRate(conversationId: AVSIdentifier) -> Bool {
        return callSnapshots[conversationId]?.isConstantBitRate ?? false
    }

    /**
     * Determines the video state of the specified user in the conversation.
     * - parameter conversationId: The identifier of the conversation to check the state of.
     * - returns: The video-sending state of the user inside conversation.
     */

    public func videoState(conversationId: AVSIdentifier) -> VideoState {
        return callSnapshots[conversationId]?.videoState ?? .stopped
    }

    /**
     * Determines the call state of the conversation.
     * - parameter conversationId: The identifier of the conversation to check the state of.
     * - returns: The state of calling of conversation, if any.
     */

    public func callState(conversationId: AVSIdentifier) -> CallState {
        return callSnapshots[conversationId]?.callState ?? .none
    }

    /**
     * Determines the call state of the conversation.
     * - parameter conversationId: The identifier of the conversation to check the state of.
     * - returns: Whether there is an active call in the conversation.
     */

    public func isActive(conversationId: AVSIdentifier) -> Bool {
        switch callState(conversationId: conversationId) {
        case .established, .establishedDataChannel:
            return true
        default:
            return false
        }
    }

    /**
     * Determines the degradation of the conversation.
     * - parameter conversationId: The identifier of the conversation to check the state of.
     * - returns: Whether the conversation has degraded security or the call in the conversation has a degraded user.
     */

    public func isDegraded(conversationId: AVSIdentifier) -> Bool {
        let conversation = ZMConversation.fetch(with: conversationId.identifier, domain: conversationId.domain, in: uiMOC!)
        let isConversationDegraded = conversation?.securityLevel == .secureWithIgnored
        let isCallDegraded = callSnapshots[conversationId]?.isDegradedCall ?? false
        return isConversationDegraded || isCallDegraded
    }

    /// Returns conversations with active calls.
    public func activeCallConversations(in userSession: ZMUserSession) -> [ZMConversation] {
        let conversations = nonIdleCalls.compactMap { (key: AVSIdentifier, value: CallState) -> ZMConversation? in
            switch value {
            case .establishedDataChannel, .established, .answered, .outgoing:
                return ZMConversation.fetch(with: key.identifier,
                                            domain: key.domain,
                                            in: userSession.managedObjectContext)
            default:
                return nil
            }
        }

        return conversations
    }

    /// Returns conversations with a non idle call state.
    public func nonIdleCallConversations(in userSession: ZMUserSession) -> [ZMConversation] {
        let conversations = nonIdleCalls.compactMap { (key: AVSIdentifier, _: CallState) -> ZMConversation? in
            return ZMConversation.fetch(with: key.identifier,
                                        domain: key.domain,
                                        in: userSession.managedObjectContext)
        }

        return conversations
    }

    public func networkQuality(conversationId: AVSIdentifier) -> NetworkQuality {
        return callSnapshots[conversationId]?.networkQuality ?? .normal
    }

    public func isConferenceCall(conversationId: AVSIdentifier) -> Bool {
        return callSnapshots[conversationId]?.isConferenceCall ?? false
    }

    func degradedUser(conversationId: AVSIdentifier) -> ZMUser? {
        return callSnapshots[conversationId]?.degradedUser
    }

    public func videoGridPresentationMode(conversationId: AVSIdentifier) -> VideoGridPresentationMode {
        return callSnapshots[conversationId]?.videoGridPresentationMode ?? .allVideoStreams
    }

    private func isGroup(conversationId: AVSIdentifier) -> Bool {
        return callSnapshots[conversationId]?.isGroup ?? false
    }

}

// MARK: - Call Participants

extension WireCallCenterV3 {

    /// Get a list of callParticipants of a given kind for a conversation
    /// - Parameters:
    ///   - conversationId: the avs identifier of the conversation
    ///   - kind: the kind of participants expected in return
    ///   - activeSpeakersLimit: the limit of active speakers to be included
    /// - Returns: the callParticipants currently in the conversation, according to the specified kind
    func callParticipants(conversationId: AVSIdentifier,
                          kind: CallParticipantsListKind,
                          activeSpeakersLimit limit: Int? = nil) -> [CallParticipant] {
        guard
            let callMembers = callSnapshots[conversationId]?.callParticipants.members.array,
            let context = uiMOC
        else {
            return []
        }

        let activeSpeakers = self.activeSpeakers(conversationId: conversationId, limitedBy: limit)

        return callMembers.compactMap { member in
            var activeSpeakerState: ActiveSpeakerState = .inactive

            if let activeSpeaker = activeSpeakers.first(where: { $0.client == member.client }) {
                activeSpeakerState = kind.state(ofActiveSpeaker: activeSpeaker)
            }

            if kind == .smoothedActiveSpeakers && activeSpeakerState == .inactive {
                return nil
            }

            return CallParticipant(member: member, activeSpeakerState: activeSpeakerState, context: context)
        }
    }

    private func activeSpeakers(conversationId: AVSIdentifier, limitedBy limit: Int? = nil) -> [AVSActiveSpeakersChange.ActiveSpeaker] {
        guard let activeSpeakers = callSnapshots[conversationId]?.activeSpeakers else {
            return []
        }

        guard let limit = limit else {
            return activeSpeakers
        }

        return Array(activeSpeakers.prefix(limit))
    }

    /// Returns the remote identifier of the user that initiated the call.
    func initiatorForCall(conversationId: AVSIdentifier) -> AVSIdentifier? {
        return callSnapshots[conversationId]?.callStarter
    }

    /// Call this method when the callParticipants changed and avs calls the handler `wcall_participant_changed_h`
    func callParticipantsChanged(conversationId: AVSIdentifier, participants: [AVSCallMember]) {
        callSnapshots[conversationId]?.callParticipants.callParticipantsChanged(participants: participants)
    }

    /// Call this method when the network quality of a participant changes and avs calls the `wcall_network_quality_h`.
    func callParticipantNetworkQualityChanged(conversationId: AVSIdentifier, client: AVSClient, quality: NetworkQuality) {

        let snapshot = callSnapshots[conversationId]?.callParticipants
        snapshot?.callParticipantNetworkQualityChanged(client: client, networkQuality: quality)
    }

}

// MARK: - Actions

extension WireCallCenterV3 {

    /**
     * Answers an incoming call in the given conversation.
     * - parameter conversation: The conversation hosting the incoming call.
     * - parameter video: Whether to join the call with video.
     */

    public func answerCall(conversation: ZMConversation, video: Bool) -> Bool {
        guard let conversationId = conversation.avsIdentifier else { return false }

        endAllCalls(exluding: conversationId)

        let callType = self.callType(for: conversation,
                                     startedWithVideo: video,
                                     isConferenceCall: isConferenceCall(conversationId: conversationId))

        let answered = avsWrapper.answerCall(conversationId: conversationId, callType: callType, useCBR: useConstantBitRateAudio)
        if answered {
            let callState: CallState = .answered(degraded: isDegraded(conversationId: conversationId))

            let previousSnapshot = callSnapshots[conversationId]

            if previousSnapshot != nil {
                callSnapshots[conversationId] = previousSnapshot!.update(with: callState)
            }

            if let context = uiMOC, let callerId = initiatorForCall(conversationId: conversationId) {
                WireCallCenterCallStateNotification(context: context, callState: callState, conversationId: conversationId, callerId: callerId, messageTime: nil, previousCallState: previousSnapshot?.callState).post(in: context.notificationContext)
            }
        }

        return answered
    }

    /**
     * Starts a call in the given conversation.
     * - parameter conversation: The conversation to start the call.
     * - parameter video: Whether to start the call as a video call.
     */

    public func startCall(conversation: ZMConversation, video: Bool) -> Bool {
        guard let conversationId = conversation.avsIdentifier else { return false }

        endAllCalls(exluding: conversationId)
        clearSnapshot(conversationId: conversationId) // make sure we don't have an old state for this conversation

        let conversationType: AVSConversationType = conversation.conversationType == .group ? .conference : .oneToOne

        let callType = self.callType(for: conversation,
                                     startedWithVideo: video,
                                     isConferenceCall: conversationType == .conference)

        if conversationType == .conference && !canStartConferenceCalls {
            if let context = uiMOC {
                WireCallCenterConferenceCallingUnavailableNotification().post(in: context.notificationContext)
            }

            return false
        }

        let started = avsWrapper.startCall(conversationId: conversationId,
                                           callType: callType,
                                           conversationType: conversationType,
                                           useCBR: useConstantBitRateAudio)

        guard started else { return false }

        let callState: CallState = .outgoing(degraded: isDegraded(conversationId: conversationId))
        let previousCallState = callSnapshots[conversationId]?.callState

        createSnapshot(callState: callState, members: [], callStarter: selfUserId, video: video, for: conversationId, isConferenceCall: conversationType == .conference)

        if let context = uiMOC {
            WireCallCenterCallStateNotification(context: context,
                                                callState: callState,
                                                conversationId: conversationId,
                                                callerId: selfUserId,
                                                messageTime: nil,
                                                previousCallState: previousCallState).post(in: context.notificationContext)
        }

        return true
    }

    private var canStartConferenceCalls: Bool {
        guard usePackagingFeatureConfig else {
            return true
        }
        guard let context = uiMOC else { return false }
        let conferenceCalling = FeatureService(context: context).fetchConferenceCalling()
        return conferenceCalling.status == .enabled
    }

    /**
     * Closes the call in the specified conversation.
     * - parameter conversationId: The ID of the conversation where the call should be ended.
     * - parameter reason: The reason why the call should be ended. The default is `.normal` (user action).
     */

    public func closeCall(conversationId: AVSIdentifier, reason: CallClosedReason = .normal) {
        avsWrapper.endCall(conversationId: conversationId)

        if let previousSnapshot = callSnapshots[conversationId] {
            if previousSnapshot.isGroup {
                let callState: CallState = .incoming(video: previousSnapshot.isVideo, shouldRing: false, degraded: isDegraded(conversationId: conversationId))
                callSnapshots[conversationId] = previousSnapshot.update(with: callState)
            } else {
                callSnapshots[conversationId] = previousSnapshot.update(with: .terminating(reason: reason))
            }
        }
    }

    /**
     * Rejects an incoming call in the conversation.
     * - parameter conversationId: The ID of the conversation where the incoming call is hosted.
     */

    public func rejectCall(conversationId: AVSIdentifier) {
        avsWrapper.rejectCall(conversationId: conversationId)

        if let previousSnapshot = callSnapshots[conversationId] {
            let callState: CallState = .incoming(video: previousSnapshot.isVideo, shouldRing: false, degraded: isDegraded(conversationId: conversationId))
            callSnapshots[conversationId] = previousSnapshot.update(with: callState)
        }
    }

    /**
     * Ends all the calls. You can specify the identifier of a conversation where the call shouldn't be ended.
     * - parameter excluding: If you need to terminate all calls except one, pass the identifier of the conversation
     * that hosts the call to keep alive. If you pass `nil`, all calls will be ended. Defaults to `nil`.
     */

    public func endAllCalls(exluding: AVSIdentifier? = nil) {
        nonIdleCalls.forEach { (key: AVSIdentifier, callState: CallState) in
            guard exluding == nil || key != exluding else { return }

            switch callState {
            case .incoming:
                rejectCall(conversationId: key)
            default:
                closeCall(conversationId: key)
            }
        }
    }

    /**
     * Enables or disables video for a call.
     * - parameter conversationId: The identifier of the conversation where the video call is hosted.
     * - parameter videoState: The new video state for the self user.
     */

    public func setVideoState(conversationId: AVSIdentifier, videoState: VideoState) {
        guard videoState != .badConnection else { return }

        if let snapshot = callSnapshots[conversationId] {
            callSnapshots[conversationId] = snapshot.updateVideoState(videoState)
        }

        avsWrapper.setVideoState(conversationId: conversationId, videoState: videoState)
    }

    /**
     * Sets the capture device type to use for video.
     * - parameter captureDevice: The device type to use to capture video for the call.
     * - parameter conversationId: The identifier of the conversation where the video call is hosted.
     */

    public func setVideoCaptureDevice(_ captureDevice: CaptureDevice, for conversationId: AVSIdentifier) {
        flowManager.setVideoCaptureDevice(captureDevice, for: conversationId)
    }

    public func setVideoGridPresentationMode(_ presentationMode: VideoGridPresentationMode, for conversationId: AVSIdentifier) {
        if let snapshot = callSnapshots[conversationId] {
            callSnapshots[conversationId] = snapshot.updateVideoGridPresentationMode(presentationMode)
        }
    }

    /// Requests AVS to load video streams for the given clients list
    /// - Parameters:
    ///   - conversationId: The identifier of the conversation where the video call is hosted.
    ///   - clients: The list of clients for which AVS should load video streams.
    public func requestVideoStreams(conversationId: AVSIdentifier, clients: [AVSClient]) {
        let videoStreams = AVSVideoStreams(conversationId: conversationId.serialized, clients: clients)
        avsWrapper.requestVideoStreams(videoStreams, conversationId: conversationId)
    }

    private func callType(for conversation: ZMConversation, startedWithVideo: Bool, isConferenceCall: Bool) -> AVSCallType {
        if !isConferenceCall && conversation.localParticipants.count > legacyVideoParticipantsLimit {
            return .audioOnly
        } else {
            return startedWithVideo ? .video : .normal
        }
    }
}

// MARK: - AVS Integration

extension WireCallCenterV3 {

    /// Sends a call OTR message when requested by AVS through `wcall_send_h`.
    func send(token: WireCallMessageToken, conversationId: AVSIdentifier, targets: AVSClientList?, data: Data, dataLength: Int) {
        zmLog.debug("\(self): send call message, transport = \(String(describing: transport))")
        transport?.send(data: data, conversationId: conversationId, targets: targets.map(\.clients), completionHandler: { [weak self] status in
            self?.avsWrapper.handleResponse(httpStatus: status, reason: "", context: token)
        })
    }

    /// Sends an SFT call message when requested by AVS through `wcall_sft_req_h`.
    func sendSFT(token: WireCallMessageToken, url: String, data: Data) {
        zmLog.debug("\(self): send SFT call message, transport = \(String(describing: transport))")

        guard let endpoint = URL(string: url) else {
            zmLog.error("SFT request failed. Invalid url: \(url)")
            avsWrapper.handleSFTResponse(data: nil, context: token)
            return
        }

        transport?.sendSFT(data: data, url: endpoint) { [weak self] result in
            switch result {
            case let .failure(error):
                zmLog.error("SFT request failed: \(error.localizedDescription)")
                self?.avsWrapper.handleSFTResponse(data: nil, context: token)

            case let .success(data):
                self?.avsWrapper.handleSFTResponse(data: data, context: token)
            }
        }
    }

    /// Sends the config request when requested by AVS through `wcall_config_req_h`.
    func requestCallConfig() {
        zmLog.debug("\(self): requestCallConfig(), transport = \(String(describing: transport))")
        transport?.requestCallConfig(completionHandler: { [weak self] (config, httpStatusCode) in
            guard let `self` = self else { return }
            zmLog.debug("\(self): self.avsWrapper.update with \(String(describing: config))")
            self.avsWrapper.update(callConfig: config, httpStatusCode: httpStatusCode)
        })
    }

    /// Tags a call as missing when requested by AVS through `wcall_missed_h`.
    func missed(conversationId: AVSIdentifier, userId: AVSIdentifier, timestamp: Date, isVideoCall: Bool) {
        zmLog.debug("missed call")

        if let context = uiMOC {
            WireCallCenterMissedCallNotification(context: context, conversationId: conversationId, callerId: userId, timestamp: timestamp, video: isVideoCall).post(in: context.notificationContext)
        }
    }

    /// Handles incoming OTR calling messages, and transmist them to AVS when it is ready to process events, or adds it to the `bufferedEvents`.
    /// - parameter callEvent: calling event to process.
    /// - parameter completionHandler: called after the call event has been processed (this will for example wait for AVS to signal that it's ready).
    func processCallEvent(_ callEvent: CallEvent, completionHandler: @escaping () -> Void) {

        if isReady {
            handleCallEvent(callEvent, completionHandler: completionHandler)
        } else {
            bufferedEvents.append((callEvent, completionHandler))
        }
    }

    fileprivate func handleCallEvent(_ callEvent: CallEvent, completionHandler: @escaping () -> Void) {
        let result = avsWrapper.received(callEvent: callEvent)

        if let context = uiMOC, let error = result {
            WireCallCenterCallErrorNotification(
                context: context,
                error: error,
                conversationId: callEvent.conversationId
            ).post(in: context.notificationContext)
        }

        completionHandler()
    }

    /// Handles a change in calling state.
    ///
    /// - Parameters:
    ///     - callState: The state to handle.
    ///     - conversationId: The id of the conversation where teh calling state has changed.
    ///     - messageTime: The timestamp of the event.

    func handle(callState: CallState, conversationId: AVSIdentifier, messageTime: Date? = nil, userId: AVSIdentifier? = nil) {
        callState.logState()

        var callState = callState

        if case .terminating(reason: .stillOngoing) = callState {
            callState = .incoming(video: false, shouldRing: false, degraded: isDegraded(conversationId: conversationId))
        }

        if case .incoming = callState, isGroup(conversationId: conversationId), activeCalls.isEmpty {
            muted = true
        }

        let callerId = initiatorForCall(conversationId: conversationId) ?? userId
        let previousCallState = callSnapshots[conversationId]?.callState

        if case .terminating = callState {
            clearSnapshot(conversationId: conversationId)
        } else if let previousSnapshot = callSnapshots[conversationId] {
            callSnapshots[conversationId] = previousSnapshot.update(with: callState)
        }

        if let context = uiMOC, let callerId = callerId {
            let notification = WireCallCenterCallStateNotification(context: context,
                                                                   callState: callState,
                                                                   conversationId: conversationId,
                                                                   callerId: callerId,
                                                                   messageTime: messageTime,
                                                                   previousCallState: previousCallState)
            notification.post(in: context.notificationContext)
        }
    }

}
