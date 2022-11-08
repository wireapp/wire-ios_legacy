//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import CallKit
import WireDataModel
import WireRequestStrategy

public protocol CallEventHandlerProtocol {
    func isCorrectCallEvent(_ event: ZMUpdateEvent, accountIdentifier: UUID) -> Bool
    func processCallEvent(event: ZMUpdateEvent) throws
}

class CallEventHandler: CallEventHandlerProtocol, Loggable {
    private let managedObjectContext: NSManagedObjectContext
    private let accountID: UUID

    init(managedObjectContext: NSManagedObjectContext, accountID: UUID) {
        self.managedObjectContext = managedObjectContext
        self.accountID = accountID
    }

    func processCallEvent(event: ZMUpdateEvent) throws {
        guard
            let voipPayload = VoIPPushPayload(from: event, accountID: accountID, serverTimeDelta: managedObjectContext.serverTimeDelta),
            let payload = voipPayload.asDictionary
        else {
            throw NotificationServiceError.incorrectCallPayload
        }
        logger.trace("Voip payload: \(String(describing: payload.keys), privacy: .public)")
        reportIncomingVoIPCall(payload)
    }

    private func reportIncomingVoIPCall(_ payload: [String: Any]) {
        guard #available(iOS 14.5, *) else { return }
        CXProvider.reportNewIncomingVoIPPushPayload(payload) { error in
            if let error = error {
                self.logger.error("Voip report failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func isCorrectCallEvent(_ event: ZMUpdateEvent, accountIdentifier: UUID) -> Bool {
        guard
            event.type == .conversationOtrMessageAdd,
            let message = GenericMessage(from: event),
            message.hasCalling,
            let payload = message.calling.content.data(using: .utf8, allowLossyConversion: false),
            let callContent = CallEventContent(from: payload)
        else {
            return false
        }

        // The sender is needed to report who the call is from.
        guard isValidSender(in: event) else {
            return false
        }

        // The conversation is needed to report where the call is taking place.
        guard let conversationID = event.conversationUUID,
            let conversation = ZMConversation.fetch(with: conversationID, domain: event.conversationDomain, in: managedObjectContext) else {
                  return false
              }

        // The call event can be processed if the conversation is not muted
        if conversation.mutedMessageTypesIncludingAvailability != .none {
            return false
        }

        // AVS is ready to process call events.
        guard VoIPPushHelper.isAVSReady else {
            return false
        }

        // CallKit may not be available due to lack of permissions or because it
        // is disabled by the user.
        guard VoIPPushHelper.isCallKitAvailable else {
            return false
        }

        // The user session is needed to process the call event.
        guard VoIPPushHelper.isUserSessionLoaded(accountID: accountIdentifier) else {
            return false
        }

        guard let conversationID = conversation.remoteIdentifier else {
            return false
        }

        let callExistsForConversation = VoIPPushHelper.existsOngoingCallInConversation(
            withID: conversationID
        )

        // We can't report an incoming call if it already exists.
        if case .incomingCall = callContent.callState, callExistsForConversation {
            return false
        }

        // We can't terminate a call if it doesn't exist.
        if case .missedCall = callContent.callState, !callExistsForConversation {
            return false
        }

        return true
    }


    private func isValidSender(in event: ZMUpdateEvent) -> Bool {
        guard let id = event.senderUUID else { return false }
        return ZMUser.fetch(with: id, domain: event.senderDomain, in: managedObjectContext) != nil
    }

}
