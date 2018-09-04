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
    
    func startAudioCall() {
        if warnAboutNoInternetConnection() {
            return
        }
        
        joinVoiceChannel(video: false)
    }
    
    func startVideoCall() {
        if warnAboutNoInternetConnection() {
            return
        }
        
        warnAboutSlowConnection { (abortCall) in
            guard !abortCall else { return }
            self.joinVoiceChannel(video: true)
        }
    }
    
    func joinCall() {
        joinVoiceChannel(video: false)
    }
    
    func joinVoiceChannel(video: Bool) {
        guard let userSession = ZMUserSession.shared() else { return }

        let onGranted : (_ granted : Bool ) -> Void = { granted in
            if granted {
                let joined = self.voiceChannel?.join(video: video, userSession: userSession) ?? false
                
                if joined {
                    Analytics.shared().tagMediaActionCompleted(video ? .videoCall : .audioCall, inConversation: self)
                }
            } else {
                self.voiceChannel?.leave(userSession: userSession)
            }
        }
        
        UIApplication.wr_requestOrWarnAboutMicrophoneAccess { granted in
            if video {
                UIApplication.wr_requestOrWarnAboutVideoAccess { _ in
                    // We still allow starting the call, even if the video permissions were not granted.
                    onGranted(granted)
                }
            } else {
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
                onGranted(granted)
            }
        }
        
    }
    
    func warnAboutSlowConnection(handler : @escaping (_ abortCall : Bool) -> Void) {
        if NetworkConditionHelper.sharedInstance().qualityType() == .type2G {
            let badConnectionController = UIAlertController(title: "error.call.slow_connection.title".localized, message: "error.call.slow_connection".localized, preferredStyle: .alert)
            
            badConnectionController.addAction(UIAlertAction(title: "error.call.slow_connection.call_anyway".localized, style: .default, handler: { (_) in
                handler(false)
            }))
            
            badConnectionController.addAction(UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: { (_) in
                handler(true)
            }))
            
            
            ZClientViewController.shared()?.present(badConnectionController, animated: true)
        } else {
            handler(false)
        }
    }
    
    func warnAboutNoInternetConnection() -> Bool {
        if AppDelegate.isOffline {
            let internetConnectionAlert = UIAlertController(title: "voice.network_error.title".localized, message: "voice.network_error.body".localized, cancelButtonTitle: "general.ok".localized)
            AppDelegate.shared().notificationsWindow?.rootViewController?.present(internetConnectionAlert, animated: true)
            return true
        } else {
            return false
        }
    }

    func confirmJoiningCallIfNeeded(alertPresenter: UIViewController, forceAlertModal: Bool = false, completion: @escaping () -> Void) {
        guard ZMUserSession.shared()?.isCallOngoing == true else {
            return completion()
        }

        let controller = UIAlertController.ongoingCallJoinCallConfirmation(forceAlertModal: forceAlertModal) { confirmed in
            guard confirmed else { return }
            self.endAllCallsExceptIncoming()
            completion()
        }

        alertPresenter.present(controller, animated: true)
    }

    /// Ends all the active calls, except the conversation's incoming call, if any.
    private func endAllCallsExceptIncoming() {
        switch voiceChannel?.state {
        case .incoming?:
            guard let sharedSession = ZMUserSession.shared() else { return }

            sharedSession.callCenter?.activeCallConversations(in: sharedSession)
                .filter { $0.remoteIdentifier != self.remoteIdentifier }
                .forEach { $0.voiceChannel?.leave() }

        default:
            ZMUserSession.shared()?.callCenter?.endAllCalls()
        }
    }

}
