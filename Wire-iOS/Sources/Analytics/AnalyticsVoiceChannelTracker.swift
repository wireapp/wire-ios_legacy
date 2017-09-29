//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

fileprivate let zmLog = ZMSLog(tag: "calling")

struct CallInfo {
    var answeredDate : Date?
    var establishedDate : Date?
    let outgoing : Bool
}

class AnalyticsVoiceChannelTracker : NSObject {
    
    let analytics : Analytics
    var callInfos : [UUID : CallInfo] = [:]
    var callStateObserverToken : Any?
    
    init(analytics : Analytics) {
        self.analytics = analytics
        
        super.init()
        
        guard let userSession = ZMUserSession.shared() else {
            zmLog.error("UserSession not available when initializing \(type(of: self))")
            return
        }
        
        self.callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, context: userSession.managedObjectContext) // TODO jacob: don't access NSManagedObjectContext
    }
}

extension AnalyticsVoiceChannelTracker : WireCallCenterCallStateObserver {
    
    func callCenterDidChange(callState: CallState, conversationId: UUID, userId: UUID?, timeStamp: Date?) {
        
        guard let managedObjectContext = ZMUserSession.shared()?.managedObjectContext,
              let conversation = ZMConversation(remoteID: conversationId, createIfNeeded: false, in: managedObjectContext) else
        {
            return
        }
        
        switch callState {
        case .outgoing:
            analytics.tagInitiatedCall(in: conversation, video: conversation.voiceChannel?.isVideoCall ?? false)
            callInfos[conversationId] = CallInfo(answeredDate: nil, establishedDate: nil, outgoing: true)
        case .incoming(video: let video, shouldRing: _, degraded: _):
            analytics.tagReceivedCall(in: conversation, video: video)
            callInfos[conversationId] = CallInfo(answeredDate: nil, establishedDate: nil, outgoing: false)
        case .answered:
            if let callInfo = callInfos[conversationId] {
                analytics.tagJoinedCall(in: conversation, video: conversation.voiceChannel?.isVideoCall ?? false, initiatedCall: callInfo.outgoing)
                callInfos[conversationId] = CallInfo(answeredDate: Date(), establishedDate: nil, outgoing: callInfo.outgoing)
            }
        case .established:
            if let callInfo = callInfos[conversationId] {
                let video = conversation.voiceChannel?.isVideoCall ?? false
                let setupDuration = -(callInfo.answeredDate?.timeIntervalSinceNow ?? -999)
                analytics.tagEstablishedCall(in: conversation, video: video, initiatedCall: callInfo.outgoing, setupDuration: setupDuration)
                callInfos[conversationId] = CallInfo(answeredDate: callInfo.answeredDate, establishedDate: Date(), outgoing: callInfo.outgoing)
            }
            
        case .terminating(reason: let reason):
            if let callInfo = callInfos[conversationId] {
                let video = conversation.voiceChannel?.isVideoCall ?? false
                let duration = -(callInfo.establishedDate?.timeIntervalSinceNow ?? -0)
                analytics.tagEndedCall(in: conversation, video: video, initiatedCall: callInfo.outgoing, duration: duration, callEndReason: reason.analyticsValue)
            }
            callInfos[conversationId] = nil
            
            if case .inputOutputError = reason {
                presentIOErrorAlertIfAllowed()
            }
        default:
            break
        }
        
    }
    
    func presentIOErrorAlertIfAllowed() {
        guard DeveloperMenuState.developerMenuEnabled() else { return }
        
        let alert = UIAlertController(title: "Calling Error", message: "AVS I/O error", cancelButtonTitle: "OK")
        alert.presentTopmost()

    }
    
}

private extension CallClosedReason {
    
    var analyticsValue : String {
        switch self {
        case .canceled:
            return "canceled"
        case .normal, .stillOngoing:
            return "other" // Current API doesn't expose if we or the remote ended the call
        case .inputOutputError:
            return "io_error"
        case .internalError:
            return "internal_error"
        case .anweredElsewhere:
            return "answered_elsewhere"
        case .timeout:
            return "timeout"
        case .unknown:
            return "unknown"
        case .lostMedia:
            return networkQualityString()
        }
    }
    
    func networkQualityString() -> String {
        let qualityType = NetworkConditionHelper.sharedInstance().qualityType()
        
        switch qualityType {
        case .typeWifi:
            return  "drop_wifi"
        case .type2G:
            return "drop_2G"
        case .type3G:
            return "drop_3G"
        case .type4G:
            return "drop_4G"
        case .typeUnkown:
            return "drop_unknown"
        }
    }
    
}
