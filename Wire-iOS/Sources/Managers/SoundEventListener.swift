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

fileprivate let zmLog = ZMSLog(tag: "Sounds")

class SoundEventListener : NSObject {
    
    static let SoundEventListenerIgnoreTimeForPushStart = 2.0
    
    let soundEventWatchDog = SoundEventRulesWatchDog(ignoreTime: SoundEventListenerIgnoreTimeForPushStart)
    var previousCallStates : [UUID : CallState] = [:]
    
    var unreadMessageObserverToken : NSObjectProtocol?
    var unreadKnockMessageObserverToken : NSObjectProtocol?
    var callStateObserverToken : Any?
    var initialSyncObserverToken : Any?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init() {
        super.init()
        
        guard let userSession = ZMUserSession.shared() else {
            zmLog.error("UserSession not available when initializing \(type(of: self))")
            return
        }
        
        initialSyncObserverToken = userSession.addInitialSyncCompletionObserver(self)
        callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, context: userSession.managedObjectContext) // TODO jacob: don't access NSManagedObjectContext
        unreadMessageObserverToken = NewUnreadMessagesChangeInfo.add(observer: self, for: userSession)
        unreadKnockMessageObserverToken = NewUnreadKnockMessagesChangeInfo.add(observer: self, for: userSession)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        soundEventWatchDog.startIgnoreDate = Date()
    }
    
    func playSoundIfAllowed(_ name : String) {
        guard !name.isEmpty, soundEventWatchDog.outputAllowed else { return }
        
        // TODO this should be handled by AVS
        guard AVAudioSession.sharedInstance().category != AVAudioSessionCategoryPlayAndRecord else {
            return
        }
        
        AVSProvider.shared.mediaManager?.playSound(name)
    }
    
}

extension SoundEventListener : ZMNewUnreadMessagesObserver, ZMNewUnreadKnocksObserver {
    
    func didReceiveNewUnreadMessages(_ changeInfo: NewUnreadMessagesChangeInfo) {
        
        for message in changeInfo.messages {
            // Rules:
            // * Not silenced
            // * Only play regular message sound if it's not from the self user
            // * If this is the first message in the conversation, don't play the sound
            // * Message is new (recently sent)
            
            let isRecentMessage = (message.serverTimestamp?.timeIntervalSinceNow ?? -Double.infinity) >= -1.0
            let isFirstMessage = (message.conversation?.messages.count ?? 0) == 1
            let isSentBySelfUser = message.sender?.isSelfUser ?? false
            let isSilencedConversation = message.conversation?.isSilenced ?? false
            
            guard message.isNormal || message.isSystem &&
                  isRecentMessage &&
                  !isSentBySelfUser &&
                  !isFirstMessage &&
                  !isSilencedConversation else {
                continue
            }
            
            var isFirstUnreadMessage = false
            
            if let conversation = message.conversation,
               let lastReadMessage = conversation.lastReadMessage
            {
                let lastReadIndex = conversation.messages.index(of: lastReadMessage)
                let messageIndex = conversation.messages.index(of: message)
                
                if lastReadIndex != NSNotFound && lastReadIndex + 1 == messageIndex {
                    isFirstUnreadMessage = true
                }
            }
            
            if isFirstUnreadMessage {
                playSoundIfAllowed(MediaManagerSoundFirstMessageReceivedSound)
            } else {
                playSoundIfAllowed(MediaManagerSoundMessageReceivedSound)
            }
        }
    }
    
    func didReceiveNewUnreadKnockMessages(_ changeInfo: NewUnreadKnockMessagesChangeInfo) {
        for message in changeInfo.messages {
            
            let isRecentMessage = (message.serverTimestamp?.timeIntervalSinceNow ?? -Double.infinity) >= -1.0
            let isSilencedConversation = message.conversation?.isSilenced ?? false
            let isSentBySelfUser = message.sender?.isSelfUser ?? false
            
            guard message.isKnock && isRecentMessage && !isSilencedConversation && !isSentBySelfUser else {
                continue
            }
            
            playSoundIfAllowed(MediaManagerSoundIncomingKnockSound)
        }
    }
    
}

extension SoundEventListener : WireCallCenterCallStateObserver {
    
    func callCenterDidChange(callState: CallState, conversationId: UUID, userId: UUID?, timeStamp: Date?) {
        
        guard let mediaManager = AVSProvider.shared.mediaManager,
              let userSession = ZMUserSession.shared(),
              let callCenter = userSession.callCenter,
              let conversation = ZMConversation(remoteID: conversationId, createIfNeeded: false, in: userSession.managedObjectContext)
        else {
            return
        }

        let previousCallState = previousCallStates[conversationId] ?? .none
        previousCallStates[conversationId] = callState
        
        switch callState {
        case .outgoing:
            if callCenter.isVideoCall(conversationId: conversationId) {
                mediaManager.playSound(MediaManagerSoundRingingFromMeVideoSound)
            } else {
                mediaManager.playSound(MediaManagerSoundRingingFromMeSound)
            }
        case .established:
            mediaManager.playSound(MediaManagerSoundUserJoinsVoiceChannelSound)
        case .incoming(video: _, shouldRing: true, degraded: _):
            guard userSession.callNotificationStyle != .callKit && !conversation.isSilenced else { return }
            
            let otherNonIdleCalls = callCenter.nonIdleCalls.filter({ (key: UUID, callState: CallState) -> Bool in
                return key != conversationId
            })
            
            if otherNonIdleCalls.count > 0 {
                mediaManager.playSound(MediaManagerSoundRingingFromThemInCallSound)
            } else {
                mediaManager.playSound(MediaManagerSoundRingingFromThemSound)
            }
        case .incoming(video: _, shouldRing: false, degraded: _):
            mediaManager.stopSound(MediaManagerSoundRingingFromThemInCallSound)
            mediaManager.stopSound(MediaManagerSoundRingingFromThemSound)
        case .terminating(reason: let reason):
            switch reason {
            case .normal, .canceled:
                mediaManager.playSound(MediaManagerSoundUserLeavesVoiceChannelSound)
            default:
                mediaManager.playSound(MediaManagerSoundCallDropped)
            }
        default:
            break
        }
        
        switch callState {
        case .outgoing, .incoming:
            break
        default:
            if case .outgoing = previousCallState {
                return
            }
            
            mediaManager.stopSound(MediaManagerSoundRingingFromThemInCallSound)
            mediaManager.stopSound(MediaManagerSoundRingingFromThemSound)
            mediaManager.stopSound(MediaManagerSoundRingingFromMeVideoSound)
            mediaManager.stopSound(MediaManagerSoundRingingFromMeSound)
        }
        
    }
    
}

extension SoundEventListener {
    
    func applicationWillEnterForeground() {
        soundEventWatchDog.startIgnoreDate = Date()
        soundEventWatchDog.isMuted = ZMUserSession.shared()?.networkState == .onlineSynchronizing
        
        if AppDelegate.shared().launchType == ApplicationLaunchPush {
            soundEventWatchDog.ignoreTime = SoundEventListener.SoundEventListenerIgnoreTimeForPushStart
        } else {
            soundEventWatchDog.ignoreTime = 0.0
        }
    }
}

extension SoundEventListener : ZMInitialSyncCompletionObserver {
    
    func initialSyncCompleted() {
        soundEventWatchDog.isMuted = false
    }
        
}
