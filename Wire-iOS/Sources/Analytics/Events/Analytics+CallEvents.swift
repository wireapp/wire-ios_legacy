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
import UIKit

enum CallEvent {
    case initiated, received, answered, established, ended(reason: String)
}

extension CallEvent {
    
    var eventName: String {
        switch self {
        case .initiated: return "calling.initiated_call"
        case .received: return "calling.received_call"
        case .answered: return "calling.joined_call"
        case .established: return "calling.established_call"
        case .ended: return "calling.ended_call"
        }
    }
    
}

extension Analytics {

    func tagCallQualityReview(_ feedback: CallQualitySurveyReview) {
        var attributes: [AnyHashable: Any] = [:]
        attributes["label"] = feedback.label
        attributes["score"] = feedback.score
        attributes["ignore-reason"] = feedback.ignoreReason

        tagEvent("calling.call_quality_review", attributes: attributes)
    }
    
    func tag(callEvent: CallEvent, in conversation: ZMConversation, callInfo: CallInfo) {        
        tagEvent(callEvent.eventName, attributes: attributes(for: callEvent, callInfo: callInfo, conversation: conversation))
    }
    
    private func attributes(for event: CallEvent, callInfo: CallInfo, conversation: ZMConversation) -> [String : Any] {
        var attributes = attributesForConversation(conversation)
        attributes.merge(attributesForUser(in: conversation), strategy: .preferNew)
        attributes.merge(attributesForParticipants(in: conversation), strategy: .preferNew)
        attributes.merge(attributesForCallParticipants(with: callInfo), strategy: .preferNew)
        attributes.merge(attributesForVideo(with: callInfo), strategy: .preferNew)
        attributes.merge(attributesForDirection(with: callInfo), strategy: .preferNew)
        
        switch event {
        case .ended(reason: let reason):
            attributes.merge(attributesForSetupTime(with: callInfo), strategy: .preferNew)
            attributes.merge(attributesForCallDuration(with: callInfo), strategy: .preferNew)
            attributes.merge(attributesForVideoToogle(with: callInfo), strategy: .preferNew)
            attributes.merge(["reason" : reason], strategy: .preferNew)
        default: break
        }
        
        
        return attributes
    }
    
    private func attributesForUser(in conversation: ZMConversation) -> [String : Any] {
        var userType: String
        
        if ZMUser.selfUser().isWirelessUser {
            userType = "temporary_guest"
        } else if ZMUser.selfUser().isGuest(in: conversation) {
            userType = "guest"
        } else {
            userType = "user"
        }
        
        return ["user_type": userType]
    }
    
    private func attributesForVideoToogle(with callInfo: CallInfo) -> [String : Any] {
        return ["AV_switch_toggled": callInfo.toggledVideo ? true : false]
    }
    
    private func attributesForVideo(with callInfo: CallInfo) -> [String : Any] {
        return ["started_as_video": callInfo.video ? true : false]
    }
    
    private func attributesForDirection(with callInfo: CallInfo) -> [String : Any] {
        return ["direction": callInfo.outgoing ? "outgoing" : "incoming"]
    }
    
    private func attributesForParticipants(in conversation: ZMConversation) -> [String : Any] {
        return ["conversation_participants": conversation.activeParticipants.count]
    }
    
    private func attributesForCallParticipants(with callInfo: CallInfo) -> [String : Any] {
        return ["conversation_participants_in_call_max": callInfo.maximumCallParticipants]
    }
    
    private func attributesForSetupTime(with callInfo: CallInfo) -> [String : Any] {
        guard let establishedDate = callInfo.establishedDate, let connectingDate = callInfo.connectingDate else {
            return [:]
        }
        return ["setup_time": Int(establishedDate.timeIntervalSince(connectingDate))]
    }
    
    private func attributesForCallDuration(with callInfo: CallInfo) -> [String : Any] {
        guard let establishedDate = callInfo.establishedDate else {
            return [:]
        }
        return ["duration": Int(-establishedDate.timeIntervalSinceNow)]
    }
    
    private func attributesForConversation(_ conversation: ZMConversation) -> [String : Any] {
        
        let attributes: [String : Any] = [
            "conversation_type": conversation.analyticsTypeString() ?? "invalid",
            "with_service": conversation.includesServiceUser ? true : false,
            "is_allow_guests": conversation.accessMode == ConversationAccessMode.allowGuests ? true : false
        ]
        
        return attributes.updated(other: guestAttributes(in: conversation))
    }
    
}
