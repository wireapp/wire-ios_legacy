//
//  ZMConversation+Calling.swift
//  Wire-iOS
//
//  Created by Jacob on 15.09.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
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
        guard let userSession = ZMUserSession.shared() else { completionHandler?(); return }
        
        WireCallCenterV3.activeInstance?.nonIdleCallConversations(in: userSession).forEach({ (conversation) in
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
