//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireDataModel
import WireSyncEngine

extension AnalyticsEvent {

    static func initiatedCall(in conversation: ZMConversation, callInfo: CallInfo) -> AnalyticsEvent {
        var event = AnalyticsEvent(name: "calling.initiated_call")
        event.attributes = conversation.analyticsAttributes
        event.attributes[.isVideoCall] = callInfo.video
        return event
    }

    static func receivedCall(in conversation: ZMConversation, callInfo: CallInfo) -> AnalyticsEvent {
        var event = AnalyticsEvent(name: "calling.received_call")
        event.attributes = conversation.analyticsAttributes
        event.attributes[.isVideoCall] = callInfo.video
        return event
    }

    static func joinedCall(in conversation: ZMConversation, callInfo: CallInfo) -> AnalyticsEvent {
        var event = AnalyticsEvent(name: "calling.joined_call")
        event.attributes = conversation.analyticsAttributes
        event.attributes[.callDirection] = callInfo.callDirection
        event.attributes[.isVideoCall] = callInfo.video
        return event
    }

    static func establishedCall(in conversation: ZMConversation, callInfo: CallInfo) -> AnalyticsEvent {
        var event = AnalyticsEvent(name: "calling.established_call")
        event.attributes = conversation.analyticsAttributes
        event.attributes[.callDirection] = callInfo.callDirection
        event.attributes[.isVideoCall] = callInfo.video
        return event
    }

    static func endedCall(in conversation: ZMConversation, reason: CallClosedReason, callInfo: CallInfo) -> AnalyticsEvent {
        var event = AnalyticsEvent(name: "calling.ended_call")
        event.attributes = conversation.analyticsAttributes
        event.attributes[.callDirection] = callInfo.callDirection
        event.attributes[.callDuration] = callInfo.callDuration
        event.attributes[.peakCallParticipantsCount] = callInfo.maximumCallParticipants.rounded(byFactor: 6)
        event.attributes[.videoWasToggled] = callInfo.toggledVideo
        event.attributes[.isVideoCall] = callInfo.video
        // TODO: [John] Add this information to call info.
        //event.attributes[.screenShareWasToggled] = callInfo.
        event.attributes[.callEndReason] = reason
        return event
    }

    static func screenShare(in conversation: ZMConversation, duration: TimeInterval, callInfo: CallInfo) -> AnalyticsEvent {
        var event = AnalyticsEvent(name: "calling.screen_share")
        event.attributes = conversation.analyticsAttributes
        event.attributes[.screenShareDirection] = AnalyticsCallDirection.incoming
        event.attributes[.screenShareDuration] = AnalyticsDuration(exactValue: duration)
        return event
    }

}

private extension AnalyticsAttributeKey {

    /// Whether the call started as a video call.
    ///
    /// Expected to refer to a value of type `Bool`.

    static let isVideoCall = AnalyticsAttributeKey(rawValue: "call_video")

    /// The direction of the call.
    ///
    /// Expected to refer to a value of type `AnalyticsCallDirection`.

    static let callDirection = AnalyticsAttributeKey(rawValue: "call_direction")

    /// The duration of the call in seconds.
    ///
    /// Expected to refer to a value of type `AnalyticsDuration`.

    static let callDuration = AnalyticsAttributeKey(rawValue: "call_duration")

    /// The peak number of participants in the call.
    ///
    /// Expected to refer to a value of type `RoundedInt`.

    static let peakCallParticipantsCount = AnalyticsAttributeKey(rawValue: "call_participants")

    /// Whether the audio / video switch was toggled at least once.
    ///
    /// Expected to refer to a value of type `Bool`.

    static let videoWasToggled = AnalyticsAttributeKey(rawValue: "call_AV_switch_toggle")

    /// Whether screen share was toggled at least once during the call.
    ///
    /// Expected to refer to a value of type `Bool`.

    static let screenShareWasToggled = AnalyticsAttributeKey(rawValue: "call_screen_share")

    /// The direction of the screen share.
    ///
    /// Expected to refer to a value of type `AnalyticsCallDirection`.

    static let screenShareDirection = AnalyticsAttributeKey(rawValue: "screen_share_direction")

    /// The duration of the screen share in seconds.
    ///
    /// Expected to refer to a value of type `AnalyticsDuration`.

    static let screenShareDuration = AnalyticsAttributeKey(rawValue: "screen_share_duration")

    /// The reason why the call ended.
    ///
    /// Expected to refer to a vale of type `CallClosedReason`.

    static let callEndReason = AnalyticsAttributeKey(rawValue: "call_end_reason")

}

private extension CallInfo {

    var callDirection: AnalyticsCallDirection {
        return outgoing ? .outgoing : .incoming
    }

    var callDuration: AnalyticsDuration? {
        return establishedDate.map {
            AnalyticsDuration(exactValue: -$0.timeIntervalSinceNow)
        }
    }

}

private enum AnalyticsCallDirection: String, AnalyticsAttributeValue {

    case incoming
    case outgoing

    var analyticsValue: String {
        return rawValue
    }

}

private struct AnalyticsDuration: AnalyticsAttributeValue {

    let analyticsValue: String

    init(exactValue: TimeInterval) {
        let roundedToNearestFive = Int(round(exactValue / 5)) * 5
        analyticsValue = String(describing: roundedToNearestFive)
    }

}

extension CallClosedReason: AnalyticsAttributeValue {

    public var analyticsValue: String {
        switch self {
        case .canceled:
            return "canceled"

        case .normal, .stillOngoing:
            return "normal"

        case .inputOutputError:
            return "io_error"

        case .internalError:
            return "internal_error"

        case .securityDegraded:
            return "security_degraded"

        case .anweredElsewhere:
            return "answered_elsewhere"

        case .timeout:
            return "timeout"

        case .unknown:
            return "unknown"

        case .lostMedia:
            return "drop"

        case .rejectedElsewhere:
            return "rejected_elsewhere"

        case .outdatedClient:
            return "outdated_client"

        }
    }

}
