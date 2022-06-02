////
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
import WireUtilities

@objc public enum ZMUpdateEventsPolicy : Int {
    case buffer /// store live events in a buffer, to be processed later
    case ignore /// process events received through /notifications or /conversation/.../events
    case process /// process events received through the push channel
}

@objc public enum ZMUpdateEventSource : Int {
    case webSocket
    case pushNotification
    case download
}

@objc public enum ZMUpdateEventType : UInt, CaseIterable {
    case unknown = 0
    case conversationAssetAdd = 1
    case conversationConnectRequest = 2
    case conversationCreate = 3
    case conversationDelete = 39
    case conversationKnock = 4
    case conversationMemberJoin = 5
    case conversationMemberLeave = 6
    case conversationMemberUpdate = 7
    case conversationMessageAdd = 8
    case conversationClientMessageAdd = 9
    case conversationOtrMessageAdd = 10
    case conversationOtrAssetAdd = 11
    case conversationRename = 12
    case conversationTyping = 13
    case conversationCodeUpdate = 14
    case conversationAccessModeUpdate = 15
    case conversationMessageTimerUpdate = 31
    case conversationReceiptModeUpdate = 34
    case userConnection = 16
    case userNew = 17
    case userUpdate = 18
    case userDelete = 35
    case userPushRemove = 19
    case userLegalHoldEnable = 38
    case userLegalHoldDisable = 37
    case userLegalHoldRequest = 36
    case userContactJoin = 20
    case userClientAdd = 21
    case userClientRemove = 22
    case userPropertiesSet = 32
    case userPropertiesDelete = 33
    case teamCreate = 23
    case teamDelete = 24
    case teamUpdate = 25
    case teamMemberJoin = 26
    case teamMemberLeave = 27
    case teamConversationCreate = 28
    case teamConversationDelete = 29
    case teamMemberUpdate = 30
    case featureConfigUpdate = 40

    // Current max value: featureConfigUpdate = 40
}

extension ZMUpdateEventType {
    var stringValue: String? {
        switch self {
        case .unknown:
            return nil

        case .conversationAssetAdd:
            return "conversation.asset-add"
        case .conversationConnectRequest:
            return "conversation.connect-request"
        case .conversationCreate:
            return "conversation.create"
        case .conversationDelete:
            return "conversation.delete"
        case .conversationKnock:
            return "conversation.knock"
        case .conversationMemberJoin:
            return "conversation.member-join"
        case .conversationMemberLeave:
            return "conversation.member-leave"
        case .conversationMemberUpdate:
            return "conversation.member-update"
        case .conversationMessageAdd:
            return "conversation.message-add"
        case .conversationClientMessageAdd:
            return "conversation.client-message-add"
        case .conversationOtrMessageAdd:
            return "conversation.otr-message-add"
        case .conversationOtrAssetAdd:
            return "conversation.otr-asset-add"
        case .conversationRename:
            return "conversation.rename"
        case .conversationTyping:
            return "conversation.typing"
        case .conversationCodeUpdate:
            return "conversation.code-update"
        case .conversationAccessModeUpdate:
            return "conversation.access-update"
        case .conversationReceiptModeUpdate:
            return "conversation.receipt-mode-update"
        case .userConnection:
            return "user.connection"
        case .userNew:
            return "user.new"
        case .userUpdate:
            return "user.update"
        case .userDelete:
            return "user.delete"
        case .userPushRemove:
            return "user.push-remove"
        case .userContactJoin:
            return "user.contact-join"
        case .userLegalHoldEnable:
            return "user.legalhold-enable"
        case .userLegalHoldDisable:
            return "user.legalhold-disable"
        case .userLegalHoldRequest:
            return "user.legalhold-request"
        case .userClientAdd:
            return "user.client-add"
        case .userClientRemove:
            return "user.client-remove"
        case .teamCreate:
            return "team.create"
        case .teamDelete:
            return "team.delete"
        case .teamUpdate:
            return "team.update"
        case .teamMemberJoin:
            return "team.member-join"
        case .teamMemberLeave:
            return "team.member-leave"
        case .teamConversationCreate:
            return "team.conversation-create"
        case .teamConversationDelete:
            return "team.conversation-delete"
        case .teamMemberUpdate:
            return "team.member-update"
        case .conversationMessageTimerUpdate:
            return "conversation.message-timer-update"
        case .userPropertiesSet:
            return "user.properties-set"
        case .userPropertiesDelete:
            return "user.properties-delete"
        case .featureConfigUpdate:
            return "feature-config.update"
        }
    }

    init(string: String) {
        let result = ZMUpdateEventType.allCases.lazy
            .compactMap { eventType -> (ZMUpdateEventType, String)? in
                guard let stringValue = eventType.stringValue else { return nil }
                return (eventType, stringValue)
            }
            .filter { (_, stringValue) -> Bool in
                return stringValue == string
            }
            .map { (eventType, _) -> ZMUpdateEventType in
                return eventType
            }
            .first

        self = result ?? .unknown
    }
}

extension ZMUpdateEvent {
    @objc(updateEventTypeForEventTypeString:) public static func updateEventType(for string: String) -> ZMUpdateEventType {
        return ZMUpdateEventType(string: string)
    }

    @objc(eventTypeStringForUpdateEventType:) public static func eventTypeString(for eventType: ZMUpdateEventType) -> String? {
        return eventType.stringValue
    }

}

private let zmLog = ZMSLog(tag: "UpdateEvents")

@objcMembers open class ZMUpdateEvent: NSObject {

    open var payload: [AnyHashable : Any]
    open var type: ZMUpdateEventType
    open var source: ZMUpdateEventSource
    open var uuid: UUID?

    var debugInformationArray: [String] = []
    /// True if the event will not appear in the notification stream
    open var isTransient: Bool
    /// True if the event had encrypted payload but now it has decrypted payload
    open var wasDecrypted: Bool
    /// True if the event contains cryptobox-encrypted data
    open var isEncrypted: Bool {
        switch self.type {
        case .conversationOtrAssetAdd, .conversationOtrMessageAdd:
            return true
        default:
            return false
        }
    }

    /// True if the event is encoded with ZMGenericMessage
    open var isGenericMessageEvent: Bool {
        switch self.type {
        case .conversationOtrMessageAdd, .conversationOtrAssetAdd, .conversationClientMessageAdd:
            return true
        default:
            return false
        }
    }

    /// True if this event type could have two versions, encrypted and non-encrypted, during the transition phase
    open var hasEncryptedAndUnencryptedVersion: Bool {
        switch self.type {
        case .conversationOtrMessageAdd,
             .conversationOtrAssetAdd,
             .conversationMessageAdd,
             .conversationAssetAdd,
             .conversationKnock:
            return true
        default:
            return false
        }
    }

    /// Debug information
    open var debugInformation: String {
        return debugInformationArray.joined(separator: "\n")
    }


    public init?(uuid: UUID?, payload: [AnyHashable : Any]?, transient: Bool, decrypted: Bool, source: ZMUpdateEventSource) {
        guard let payload = payload else { return nil }
        guard let payloadType = payload["type"] as? String else { return nil }

        self.uuid = uuid
        self.payload = payload
        self.isTransient = transient
        self.wasDecrypted = decrypted

        let eventType = ZMUpdateEventType(string: payloadType)
        guard eventType != .unknown else { return nil }
        self.type = eventType
        self.source = source
        wasDecrypted = false
    }

    open class func eventsArray(fromPushChannelData transportData: ZMTransportData) -> [ZMUpdateEvent]? {
        return self.eventsArray(from: transportData, source: .webSocket)
    }


    /// Returns an array of @c ZMUpdateEvent from the given push channel data, the source will be set to @c
    /// ZMUpdateEventSourceWebSocket, if a non-nil @c NSUUID is given for the @c pushStartingAt parameter, all
    /// events earlier or equal to this uuid will have a source of @c ZMUpdateEventSourcePushNotification
    open class func eventsArray(fromPushChannelData transportData: ZMTransportData, pushStartingAt threshold: UUID?) -> [Any]? {
        return self.eventsArray(from: transportData, source: .webSocket, pushStartingAt: threshold)
    }

    class func eventsArray(with uuid: UUID, payloadArray: [Any]?, transient: Bool, source: ZMUpdateEventSource, pushStartingAt sourceThreshold: UUID?) -> [ZMUpdateEvent] {

        guard let payloads = payloadArray as? [[AnyHashable: AnyHashable]] else {
            zmLog.error("Push event payload is invalid")
            return []
        }

        let events = payloads.compactMap { payload -> ZMUpdateEvent? in
            var actualSource = source
            if let thresholdUUID = sourceThreshold, thresholdUUID.isType1UUID, uuid.isType1UUID, (thresholdUUID as NSUUID).compare(withType1UUID: uuid as NSUUID) != .orderedDescending {
                actualSource = .pushNotification
            }
            return ZMUpdateEvent(uuid: uuid, payload: payload, transient: transient, decrypted: false, source: actualSource)
        }
        return events
    }


    @objc(eventFromEventStreamPayload:uuid:)
    public static func eventFromEventStreamPayload(_ payload: ZMTransportData, uuid: UUID?) -> ZMUpdateEvent? {
        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: uuid)
    }

    /// Creates an update event
    public convenience init?(fromEventStreamPayload payload: ZMTransportData, uuid: UUID?) {
        let dictionary = payload.asDictionary()
        // Some payloads are wrapped inside "event" key (e.g. removing bot from conversation)
        // Check for this before
        let innerPayload = (dictionary?["event"] as? [AnyHashable : Any]) ?? dictionary

        self.init(uuid: uuid, payload: innerPayload, transient: false, decrypted: false, source: .download)
    }


    /// Creates an update event that was encrypted and it's now decrypted
    open class func decryptedUpdateEvent(fromEventStreamPayload payload: ZMTransportData, uuid: UUID?, transient: Bool, source: ZMUpdateEventSource) -> ZMUpdateEvent? {
        return ZMUpdateEvent(uuid: uuid, payload: payload.asDictionary(), transient: transient, decrypted: true, source: source)
    }

    @objc(eventsArrayFromTransportData:source:)
    open class func eventsArray(from transportData: ZMTransportData, source: ZMUpdateEventSource) -> [ZMUpdateEvent]? {
        return self.eventsArray(from: transportData, source: source, pushStartingAt: nil)
    }

    open class func eventsArray(from transportData: ZMTransportData, source: ZMUpdateEventSource, pushStartingAt threshold: UUID?) -> [ZMUpdateEvent]? {

        let dictionary = transportData.asDictionary()
        guard let uuidString = dictionary?["id"] as? String, let uuid = UUID(uuidString: uuidString) else { return nil }
        guard let payloadArray = dictionary?["payload"] as? [Any] else { return nil }
        let transient = (dictionary?["transient"] as? Bool) ?? false

        return eventsArray(with: uuid, payloadArray: payloadArray, transient: transient, source: source, pushStartingAt: threshold)
    }

    /// Adds debug information
    open func appendDebugInformation(_ debugInformation: String) {
        debugInformationArray.append(debugInformation)
    }
}

extension ZMUpdateEvent {
    open override var description: String {
        let uuidDescription = uuid?.transportString() ?? "<no uuid>"
        return "<\(Swift.type(of:self))> \(uuidDescription) \(payload) \n \(debugInformation)"
    }
}

extension ZMUpdateEvent {
    override open func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ZMUpdateEvent else { return false }
        return
            (self.uuid == other.uuid) &&
            (self.type == other.type) &&
            (self.payload as NSDictionary).isEqual(to: other.payload)
    }
}
