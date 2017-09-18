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

class ProximityMonitorManager : NSObject {
    
    var callStateObserverToken : WireCallCenterObserverToken?
    
    deinit {
        AVSMediaManagerClientChangeNotification.remove(self)
    }
    
    override init() {
        super.init()
        
        callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self)
        AVSMediaManagerClientChangeNotification.add(self)
        
        updateProximityMonitorState()
    }
    
    func updateProximityMonitorState() {
        // Only do proximity monitoring on phones
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        let ongoingCalls = WireCallCenterV3.activeInstance?.nonIdleCalls.filter({ (key: UUID, callState: CallState) -> Bool in
            switch callState {
            case .established, .establishedDataChannel, .answered(degraded: false), .outgoing(degraded: false):
                return true
            default:
                return false
            }
        })
        
        let hasOngoingCall = (ongoingCalls?.count ?? 0) > 0
        let speakerIsEnabled = AVSProvider.shared.mediaManager?.isSpeakerEnabled ?? false
        
        UIDevice.current.isProximityMonitoringEnabled = !speakerIsEnabled && hasOngoingCall
    }
    
}

extension ProximityMonitorManager : WireCallCenterCallStateObserver {
    
    func callCenterDidChange(callState: CallState, conversationId: UUID, userId: UUID?, timeStamp: Date?) {
        updateProximityMonitorState()
    }
    
}

extension ProximityMonitorManager : AVSMediaManagerClientObserver {
    
    func mediaManagerDidChange(_ notification: AVSMediaManagerClientChangeNotification!) {
        if notification.speakerEnableChanged {
            updateProximityMonitorState()
        }
    }
    
}
