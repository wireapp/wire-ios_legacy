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


extension ZMConversation {
    
    var isCallingSupported : Bool {
        return activeParticipants.count > 1
    }
    
    var firstCallingParticipantOtherThanSelf : ZMUser? {
        return voiceChannel?.participants.first(where: { (user) -> Bool in
            return !ZMUser.selfUser().isEqual(user)
        }) as? ZMUser
    }
    
    func startAudioCall(completionHandler: ((_ joined: Bool) -> Void)?) {
        joinVoiceChannel(video: false, completionHandler: completionHandler)
    }
    
    func startVideoCall(completionHandler: ((_ joined: Bool) -> Void)?) {
        warnAboutSlowConnection { (abortCall) in
            guard !abortCall else { completionHandler?(false); return }
            
            self.joinVoiceChannel(video: true, completionHandler: completionHandler)
        }
    }
    
    func joinCall() {
        joinVoiceChannel(video: voiceChannel?.isVideoCall ?? false, completionHandler: nil)
    }
    
    func joinVoiceChannel(video: Bool, completionHandler: ((_ joined: Bool) -> Void)?) {
        
        if warnAboutNoInternetConnection() {
            completionHandler?(false)
            return
        }
        
        let onGranted : (_ granted : Bool ) -> Void = { granted in
            if granted {
                self.joinVoiceChannelWithoutAskingForPermission(video: video, completionHandler: completionHandler)
            } else {
                completionHandler?(false)
            }
        }
        
        UIApplication.wr_requestOrWarnAboutMicrophoneAccess { (granted) in
            if video {
                UIApplication.wr_requestOrWarnAboutVideoAccess(onGranted)
            } else {
                onGranted(granted)
            }
        }
        
    }
    
    func joinVoiceChannelWithoutAskingForPermission(video: Bool, completionHandler: ((_ joined: Bool) -> Void)?) {
        guard let userSession = ZMUserSession.shared() else { completionHandler?(false); return }
        
        leaveOtherActiveCalls {
            let joined = self.voiceChannel?.join(video: video, userSession: userSession) ?? false
            
            if joined {
                Analytics.shared()?.tagMediaAction(video ? .videoCall : .audioCall, inConversation: self)
            }
            
            completionHandler?(joined)
        }
    }
    
    func leaveOtherActiveCalls(completionHandler: (() -> Void)?) -> Void {
        guard let userSession = ZMUserSession.shared(), let callCenter = userSession.callCenter else { completionHandler?(); return }
        
        callCenter.nonIdleCallConversations(in: userSession).forEach({ (conversation) in
            if conversation != self {
                conversation.voiceChannel?.leave(userSession: userSession)
            }
        })
        
        completionHandler?()
    }

    func warnAboutSlowConnection(handler : @escaping (_ abortCall : Bool) -> Void) {
        if NetworkConditionHelper.sharedInstance().qualityType() == .type2G {
            let badConnectionController = UIAlertController(title: "error.call.slow_connection.title".localized, message: "error.call.slow_connection".localized, preferredStyle: .alert)
            
            badConnectionController.addAction(UIAlertAction(title: "error.call.slow_connection.call_anyway".localized, style: .default, handler: { (_) in
                handler(false)
            }))
            
            badConnectionController.addAction(UIAlertAction(title: "general.cancel", style: .cancel, handler: { (_) in
                handler(true)
            }))
            
            
            ZClientViewController.shared().present(badConnectionController, animated: true)
        } else {
            handler(false)
        }
    }
    
    func warnAboutNoInternetConnection() -> Bool {
        if AppDelegate.checkNetworkAndFlashIndicatorIfNecessary() {
            let internetConnectionAlert = UIAlertController(title: "voice.network_error.title".localized, message: "voice.network_error.body".localized, cancelButtonTitle: "general.ok".localized)
            AppDelegate.shared().notificationsWindow?.rootViewController?.present(internetConnectionAlert, animated: true)
            return true
        } else {
            return false
        }
    }

}
