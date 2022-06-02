/*
 * Wire
 * Copyright (C) 2017 Wire Swiss GmbH
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
import CallKit
import Intents
import avs

private let identifierSeparator: Character = "+"

// Represents a call managed by CallKit

private struct CallKitCall {
    let conversation: ZMConversation
    let observer: CallObserver

    init(conversation: ZMConversation) {
        self.conversation = conversation
        self.observer = CallObserver(conversation: conversation)
    }
}

/// Represents the location of a call uniquely across accounts

struct CallHandle: Hashable {
    let accountId: UUID
    let conversationId: UUID

    init?(customIdentifier value: String) {
        let identifiers = value.split(separator: identifierSeparator).compactMap({ UUID(uuidString: String($0)) })

        guard identifiers.count == 2 else { return nil }

        self.accountId = identifiers[0]
        self.conversationId = identifiers[1]
    }
}

protocol CallKitManagerDelegate: AnyObject {

    /// Look a conversation where a call has or will take place

    func lookupConversation(by handle: CallHandle, completionHandler: @escaping (Result<ZMConversation>) -> Void)

    /// End all active calls in all user sessions

    func endAllCalls()

}

@objc
public class CallKitManager: NSObject {

    fileprivate let provider: CXProvider
    fileprivate let callController: CXCallController
    fileprivate weak var delegate: CallKitManagerDelegate?
    fileprivate weak var mediaManager: MediaManagerType?
    fileprivate var callStateObserverToken: Any?
    fileprivate var missedCallObserverToken: Any?
    fileprivate var connectedCallConversation: ZMConversation?

    fileprivate var calls: [UUID: CallKitCall] {
        didSet {
            VoIPPushHelper.setOngoingCalls(
                conversationIDs: calls.values.map { $0.conversation.remoteIdentifier! }
            )
        }
    }

    convenience init(delegate: CallKitManagerDelegate, mediaManager: MediaManagerType?) {
        self.init(provider: CXProvider(configuration: CallKitManager.providerConfiguration),
                  callController: CXCallController(queue: DispatchQueue.main),
                  delegate: delegate,
                  mediaManager: mediaManager)
    }

    init(provider: CXProvider,
         callController: CXCallController,
         delegate: CallKitManagerDelegate,
         mediaManager: MediaManagerType?) {

        self.provider = provider
        self.callController = callController
        self.delegate = delegate
        self.mediaManager = mediaManager
        self.calls = [:]

        super.init()

        provider.setDelegate(self, queue: nil)

        callStateObserverToken = WireCallCenterV3.addGlobalCallStateObserver(observer: self)
        missedCallObserverToken = WireCallCenterV3.addGlobalMissedCallObserver(observer: self)
    }

    deinit {
        provider.invalidate()
    }

    public func updateConfiguration() {
        provider.configuration = CallKitManager.providerConfiguration
    }

    internal static var providerConfiguration: CXProviderConfiguration {

        let localizedName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Wire"
        let configuration = CXProviderConfiguration(localizedName: localizedName)

        configuration.supportsVideo = true
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        configuration.ringtoneSound = NotificationSound.call.name

        if let image = UIImage(named: "wire-logo-letter") {
            configuration.iconTemplateImageData = image.pngData()
        }

        return configuration
    }

    fileprivate func log(_ message: String, file: String = #file, line: Int = #line) {
        let messageWithLineNumber = String(format: "%@:%ld: %@", URL(fileURLWithPath: file).lastPathComponent, line, message)
        SessionManager.logAVS(message: messageWithLineNumber)
    }

    fileprivate func actionsToEndAllOngoingCalls(exceptIn conversation: ZMConversation) -> [CXAction] {
        return calls
            .lazy
            .filter { $0.value.conversation != conversation }
            .map { CXEndCallAction(call: $0.key) }
    }

    internal func callUUID(for conversation: ZMConversation) -> UUID? {
        return calls.first(where: { $0.value.conversation == conversation })?.key
    }

    private func callExists(for conversation: ZMConversation) -> Bool {
        return callUUID(for: conversation) != nil
    }

}

extension CallKitManager {

    func findConversationAssociated(with contacts: [INPerson], completion: @escaping (ZMConversation) -> Void) {

        guard contacts.count == 1,
              let contact = contacts.first,
              let customIdentifier = contact.personHandle?.value,
              let callHandle = CallHandle(customIdentifier: customIdentifier)
        else {
            return
        }

        delegate?.lookupConversation(by: callHandle, completionHandler: { (result) in
            guard case .success(let conversation) = result else { return }
            completion(conversation)
        })
    }

    public func continueUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard let interaction = userActivity.interaction
        else { return false }

        let intent = interaction.intent
        var contacts: [INPerson]?
        var video = false

        if let audioCallIntent = intent as? INStartAudioCallIntent {
            contacts = audioCallIntent.contacts
            video = false
        } else if let videoCallIntent = intent as? INStartVideoCallIntent {
            contacts = videoCallIntent.contacts
            video = true
        }

        if let contacts = contacts {
            findConversationAssociated(with: contacts) { [weak self] (conversation) in
                self?.requestStartCall(in: conversation, video: video)
            }

            return true
        }

        return false
    }
}

extension CallKitManager {

    func requestMuteCall(in conversation: ZMConversation, muted: Bool) {
        guard let existingCallUUID = callUUID(for: conversation) else { return }

        let action = CXSetMutedCallAction(call: existingCallUUID, muted: muted)

        callController.request(CXTransaction(action: action)) { [weak self] (error) in
            if let error = error {
                self?.log("Cannot update call to muted = \(muted): \(error)")
            }
        }
    }

    func requestJoinCall(in conversation: ZMConversation, video: Bool) {

        let existingCallUUID = callUUID(for: conversation)
        let existingCall = callController.callObserver.calls.first(where: { $0.uuid == existingCallUUID })

        if let call = existingCall, !call.isOutgoing {
            requestAnswerCall(in: conversation, video: video)
        } else {
            requestStartCall(in: conversation, video: video)
        }
    }

    func requestStartCall(in conversation: ZMConversation, video: Bool) {
        guard
            let managedObjectContext = conversation.managedObjectContext,
            let handle = conversation.callKitHandle
        else {
            self.log("Ignore request to start call since remoteIdentifier or handle is nil")
            return
        }

        let callUUID = UUID()
        calls[callUUID] = CallKitCall(conversation: conversation)

        let action = CXStartCallAction(call: callUUID, handle: handle)
        action.isVideo = video
        action.contactIdentifier = conversation.localizedCallerName(with: ZMUser.selfUser(in: managedObjectContext))

        let endCallActions = actionsToEndAllOngoingCalls(exceptIn: conversation)
        let transaction = CXTransaction(actions: endCallActions + [action])

        log("request CXStartCallAction")

        callController.request(transaction) { [weak self] (error) in
            if let error = error as? CXErrorCodeRequestTransactionError, error.code == .callUUIDAlreadyExists {
                self?.requestAnswerCall(in: conversation, video: video)
            } else if let error = error {
                self?.log("Cannot start call: \(error)")
            }
        }

    }

    func requestAnswerCall(in conversation: ZMConversation, video: Bool) {
        guard let callUUID = callUUID(for: conversation) else { return }

        let action = CXAnswerCallAction(call: callUUID)
        let endPreviousActions = actionsToEndAllOngoingCalls(exceptIn: conversation)
        let transaction = CXTransaction(actions: endPreviousActions + [action])

        log("request CXAnswerCallAction")

        callController.request(transaction) { [weak self] (error) in
            if let error = error {
                self?.log("Cannot answer call: \(error)")
            }
        }
    }

    func requestEndCall(in conversation: ZMConversation, completion: (() -> Void)? = nil) {
        guard let callUUID = callUUID(for: conversation) else { return }

        let action = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: action)

        log("request CXEndCallAction")

        callController.request(transaction) { [weak self] (error) in
            if let error = error {
                self?.log("Cannot end call: \(error)")
                conversation.voiceChannel?.leave()
            }
            completion?()
        }
    }

    /// Reports an incoming call to CallKit.
    ///
    /// - Parameters:
    ///   - user: The caller.
    ///   - conversation: The conversation in which the call is incoming.
    ///   - video: Whether the caller has video enabled.
    ///
    /// - Throws: ReportIncomingCallError if the call could not be reported.

    func reportIncomingCall(from user: ZMUser, in conversation: ZMConversation, video: Bool) throws {
        guard !callExists(for: conversation) else {
            log("Cannot report incoming call: call already exists, probably b/c it was reported earlier for a push notification")
            throw ReportIncomingCallError.callAlreadyExists
        }

        guard let handle = conversation.callKitHandle else {
            log("Cannot report incoming call: conversation is missing handle")
            throw ReportIncomingCallError.noCallKitHandle
        }

        guard !conversation.needsToBeUpdatedFromBackend else {
            log("Cannot report incoming call: conversation needs to be updated from backend")
            throw ReportIncomingCallError.conversationNotSynced
        }

        let update = CXCallUpdate()
        update.supportsHolding = false
        update.supportsDTMF = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.localizedCallerName = conversation.localizedCallerName(with: user)
        update.remoteHandle = handle
        update.hasVideo = video

        let callUUID = UUID()
        calls[callUUID] = CallKitCall(conversation: conversation)

        log("provider.reportNewIncomingCall")

        provider.reportNewIncomingCall(with: callUUID, update: update) { [weak self] error in
            if let error = error {
                self?.log("Cannot report incoming call: \(error)")
                self?.calls.removeValue(forKey: callUUID)
                conversation.voiceChannel?.leave()
            }
        }
    }

    /// Reports to CallKit all calls associated with a conversation as ended.
    ///
    /// - Parameters:
    ///   - conversation: The conversation in which the call(s) ended.
    ///   - timestamp: The date at which the call(s) ended.
    ///   - reason: The reason why the call(s) ended.
    ///
    /// - Throws: ReportTerminatingCallError if no call could be reported as ended.

    func reportCallEnded(in conversation: ZMConversation, atTime timestamp: Date?, reason: CXCallEndedReason) throws {
        let associatedCallUUIDs = calls
            .filter { $0.value.conversation == conversation }
            .keys

        guard !associatedCallUUIDs.isEmpty else {
            throw ReportTerminatingCallError.callNotFound
        }

        associatedCallUUIDs.forEach { callUUID in
            calls.removeValue(forKey: callUUID)
            log("provider.reportCallEndedAt: \(String(describing: timestamp))")
            provider.reportCall(with: callUUID, endedAt: timestamp?.clampForCallKit() ?? Date(), reason: reason)
        }
    }

}

fileprivate extension Date {
    func clampForCallKit() -> Date {
        let twoWeeksBefore = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        return clamp(between: twoWeeksBefore, and: Date())
    }

    func clamp(between fromDate: Date, and toDate: Date) -> Date {
        if timeIntervalSinceReferenceDate < fromDate.timeIntervalSinceReferenceDate {
            return fromDate
        } else if timeIntervalSinceReferenceDate > toDate.timeIntervalSinceReferenceDate {
            return toDate
        } else {
            return self
        }
    }
}

extension CallKitManager: CXProviderDelegate {

    public func providerDidBegin(_ provider: CXProvider) {
        log("providerDidBegin: \(provider)")
    }

    public func providerDidReset(_ provider: CXProvider) {
        log("providerDidReset: \(provider)")
        mediaManager?.resetAudioDevice()
        calls.removeAll()
        delegate?.endAllCalls()
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        log("perform CXStartCallAction: \(action)")

        guard let call = calls[action.callUUID] else {
            log("fail CXStartCallAction because call did not exist")
            action.fail()
            return
        }

        call.observer.onAnswered = {
            provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
        }

        call.observer.onEstablished = {
            provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
        }

        mediaManager?.setupAudioDevice()

        if call.conversation.voiceChannel?.join(video: action.isVideo) == true {
            action.fulfill()
        } else {
            action.fail()
        }

        let update = CXCallUpdate()
        update.remoteHandle = call.conversation.callKitHandle
        update.localizedCallerName = call.conversation.localizedCallerNameForOutgoingCall()

        provider.reportCall(with: action.callUUID, updated: update)
    }

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        log("perform CXAnswerCallAction: \(action)")

        guard let call = calls[action.callUUID] else {
            log("fail CXAnswerCallAction because call did not exist")
            action.fail()
            return
        }

        call.observer.onEstablished = {
            action.fulfill()
        }

        call.observer.onFailedToJoin = {
            action.fail()
        }

        mediaManager?.setupAudioDevice()

        if call.conversation.voiceChannel?.join(video: false) != true {
            action.fail()
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        log("perform CXEndCallAction: \(action)")

        guard let call = calls[action.callUUID] else {
            log("fail CXEndCallAction because call did not exist")
            action.fail()
            return
        }

        calls.removeValue(forKey: action.callUUID)
        call.conversation.voiceChannel?.leave()
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        log("perform CXSetHeldCallAction: \(action)")
        guard let call = calls[action.callUUID] else {
            log("fail CXSetHeldCallAction because call did not exist")
            action.fail()
            return
        }

        call.conversation.voiceChannel?.muted = action.isOnHold
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        log("perform CXSetMutedCallAction: \(action)")
        guard let call = calls[action.callUUID] else {
            log("fail CXSetMutedCallAction because call did not exist")
            action.fail()
            return
        }

        call.conversation.voiceChannel?.muted = action.isMuted
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        log("didActivate audioSession")
        mediaManager?.startAudio()
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        log("didDeactivate audioSession")
        mediaManager?.resetAudioDevice()
    }
}

extension CallKitManager: WireCallCenterCallStateObserver, WireCallCenterMissedCallObserver {

    public func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        switch callState {
        case .incoming(video: let video, shouldRing: let shouldRing, degraded: _):
            if shouldRing, let caller = caller as? ZMUser {
                if conversation.mutedMessageTypesIncludingAvailability == .none {
                    try? reportIncomingCall(from: caller, in: conversation, video: video)
                }
            } else {
                try? reportCallEnded(in: conversation, atTime: timestamp, reason: .unanswered)
            }
        case let .terminating(reason: reason):
            try? reportCallEnded(in: conversation, atTime: timestamp, reason: reason.CXCallEndedReason)
        default:
            break
        }
    }

    public func callCenterMissedCall(conversation: ZMConversation, caller: UserType, timestamp: Date, video: Bool) {
        // Since we missed the call we will not have an assigned callUUID and can just create a random one
        provider.reportCall(with: UUID(), endedAt: timestamp, reason: .unanswered)
    }

}

extension ZMConversation {

    var callKitHandle: CXHandle? {
        if let managedObjectContext = managedObjectContext,
           let userId = ZMUser.selfUser(in: managedObjectContext).remoteIdentifier,
           let remoteIdentifier = remoteIdentifier {
            return CXHandle(type: .generic, value: userId.transportString() + String(identifierSeparator) + remoteIdentifier.transportString())
        }

        return nil
    }

    func localizedCallerNameForOutgoingCall() -> String? {
        guard let managedObjectContext = self.managedObjectContext  else { return nil }

        return localizedCallerName(with: ZMUser.selfUser(in: managedObjectContext))
    }

    func localizedCallerName(with user: ZMUser) -> String {

        let conversationName = self.userDefinedName
        let callerName: String? = user.name
        var result: String?

        switch conversationType {
        case .group:
            if let conversationName = conversationName, let callerName = callerName {
                result = String.localizedStringWithFormat("callkit.call.started.group".pushFormatString, callerName, conversationName)
            } else if let conversationName = conversationName {
                result = String.localizedStringWithFormat("callkit.call.started.group.nousername".pushFormatString, conversationName)
            } else if let callerName = callerName {
                result = String.localizedStringWithFormat("callkit.call.started.group.noconversationname".pushFormatString, callerName)
            }
        case .oneOnOne:
            result = connectedUser?.name
        default:
            break
        }

        return result ?? String.localizedStringWithFormat("callkit.call.started.group.nousername.noconversationname".pushFormatString)
    }

}

extension CXCallAction {

    func conversation(in context: NSManagedObjectContext) -> ZMConversation? {
        return ZMConversation.fetch(with: callUUID, in: context)
    }

}

extension CallClosedReason {

    var CXCallEndedReason: CXCallEndedReason {
        switch self {
        case .timeout, .timeoutECONN:
            return .unanswered
        case .normal, .canceled:
            return .remoteEnded
        case .anweredElsewhere:
            return .answeredElsewhere
        case .rejectedElsewhere:
            return .declinedElsewhere
        default:
            return .failed
        }
    }

}

class CallObserver: WireCallCenterCallStateObserver {

    private var token: Any?

    public var onAnswered : (() -> Void)?
    public var onEstablished : (() -> Void)?
    public var onFailedToJoin : (() -> Void)?

    public init(conversation: ZMConversation) {
        token = WireCallCenterV3.addCallStateObserver(observer: self, for: conversation, context: conversation.managedObjectContext!)
    }

    public func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        switch callState {
        case .answered(degraded: false):
            onAnswered?()
        case .establishedDataChannel, .established:
            onEstablished?()
        case .terminating(reason: let reason):
            switch reason {
            case .inputOutputError, .internalError, .unknown, .lostMedia, .anweredElsewhere:
                onFailedToJoin?()
            default:
                break
            }
        default:
            break
        }
    }

}

// MARK: - Errors

extension CallKitManager {

    /// Errors describing why an incoming call could not be reported.

    enum ReportIncomingCallError: Error, SafeForLoggingStringConvertible {

        case callAlreadyExists
        case noCallKitHandle
        case conversationNotSynced

        var safeForLoggingDescription: String {
            switch self {
            case .callAlreadyExists:
                return "The call already exists. Perhaps it has already been reported."

            case .noCallKitHandle:
                return "No CallKit handle could be created for the conversation."

            case .conversationNotSynced:
                return "The conversation needs to be synced with the backend."
            }
        }

    }

    enum ReportTerminatingCallError: Error, SafeForLoggingStringConvertible {

        case callNotFound

        var safeForLoggingDescription: String {
            switch self {
            case .callNotFound:
                return "The call could not be found. Perhaps it has not yet been reported."
            }
        }

    }

}
