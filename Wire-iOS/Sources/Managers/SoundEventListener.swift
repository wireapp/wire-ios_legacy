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
import WireSyncEngine
import avs

extension ZMConversationMessage {
    var isSentBySelfUser: Bool {
        return senderUser?.isSelfUser ?? false
    }

    var isRecentMessage: Bool {
        return (self.serverTimestamp?.timeIntervalSinceNow ?? -Double.infinity) >= -1.0
    }

    var isSystemMessageWithSoundNotification: Bool {
        guard isSystem, let data = systemMessageData else {
            return false
        }

        switch data.systemMessageType {
        // No sound must be played for the case when the user participated in the call.
        case .performedCall:
            return false

        default:
            return true
        }
    }
}

class SoundEventListener: NSObject {

    weak var userSession: ZMUserSession?

    static let SoundEventListenerIgnoreTimeForPushStart = 2.0

    let soundEventWatchDog = SoundEventRulesWatchDog(ignoreTime: SoundEventListenerIgnoreTimeForPushStart)
    var previousCallStates: [UUID: CallState] = [:]

    var unreadMessageObserverToken: NSObjectProtocol?
    var unreadKnockMessageObserverToken: NSObjectProtocol?
    var callStateObserverToken: Any?
    var networkAvailabilityObserverToken: Any?

    init(userSession: ZMUserSession) {
        self.userSession = userSession
        super.init()

        networkAvailabilityObserverToken = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(self, userSession: userSession)
        callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession)
        unreadMessageObserverToken = NewUnreadMessagesChangeInfo.add(observer: self, for: userSession)
        unreadKnockMessageObserverToken = NewUnreadKnockMessagesChangeInfo.add(observer: self, for: userSession)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        soundEventWatchDog.startIgnoreDate = Date()
        soundEventWatchDog.isMuted = UIApplication.shared.applicationState == .background
    }

    func playSoundIfAllowed(_ mediaManagerSound: MediaManagerSound) {
        guard soundEventWatchDog.outputAllowed else { return }
        AVSMediaManager.sharedInstance()?.play(sound: mediaManagerSound)
    }

    func provideHapticFeedback(for message: ZMConversationMessage) {
        if message.isNormal,
            message.isRecentMessage,
            message.isSentBySelfUser,
            let localMessage = message as? ZMMessage,
            localMessage.deliveryState == .pending
        {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

extension SoundEventListener: ZMNewUnreadMessagesObserver, ZMNewUnreadKnocksObserver {

    func didReceiveNewUnreadMessages(_ changeInfo: NewUnreadMessagesChangeInfo) {

        for message in changeInfo.messages {
            // Rules:
            // * Not silenced
            // * Only play regular message sound if it's not from the self user
            // * If this is the first message in the conversation, don't play the sound
            // * Message is new (recently sent)

            let isSilenced = message.isSilenced

            provideHapticFeedback(for: message)

            guard (message.isNormal || message.isSystemMessageWithSoundNotification) &&
                  message.isRecentMessage &&
                  !message.isSentBySelfUser &&
                  !isSilenced else {
                continue
            }

            let isFirstUnreadMessage = message.isEqual(message.conversation?.firstUnreadMessage)

            if isFirstUnreadMessage {
                playSoundIfAllowed(.firstMessageReceivedSound)
            } else {
                playSoundIfAllowed(.messageReceivedSound)
            }
        }
    }

    func didReceiveNewUnreadKnockMessages(_ changeInfo: NewUnreadKnockMessagesChangeInfo) {
        for message in changeInfo.messages {

            let isRecentMessage = (message.serverTimestamp?.timeIntervalSinceNow ?? -Double.infinity) >= -1.0
            let isSilenced = message.isSilenced
            let isSentBySelfUser = message.senderUser?.isSelfUser ?? false

            guard message.isKnock && isRecentMessage && !isSilenced && !isSentBySelfUser else {
                continue
            }

            playSoundIfAllowed(.incomingKnockSound)
        }
    }

}

extension SoundEventListener: WireCallCenterCallStateObserver {

    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {

        guard let mediaManager = AVSMediaManager.sharedInstance(),
              let userSession = userSession,
              let callCenter = userSession.callCenter
        else {
            return
        }

        let conversationId = conversation.remoteIdentifier!
        let previousCallState = previousCallStates[conversationId] ?? .none
        previousCallStates[conversationId] = callState

        switch callState {
        case .incoming(video: _, shouldRing: true, degraded: _):
            guard let sessionManager = SessionManager.shared, conversation.mutedMessageTypesIncludingAvailability == .none else { return }

            let otherNonIdleCalls = callCenter.nonIdleCalls.filter({ (key: UUID, callState: CallState) -> Bool in
                return key != conversationId
            })

            if otherNonIdleCalls.count > 0 {
                playSoundIfAllowed(.ringingFromThemInCallSound)
            } else if sessionManager.callNotificationStyle != .callKit {
                playSoundIfAllowed(.ringingFromThemSound)
            }
        case .incoming(video: _, shouldRing: false, degraded: _):
            mediaManager.stop(sound: .ringingFromThemInCallSound)
            mediaManager.stop(sound: .ringingFromThemSound)
        case .terminating(reason: let reason):
            switch reason {
            case .normal, .canceled:
                break
            default:
                playSoundIfAllowed(.callDropped)
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

            mediaManager.stop(sound: .ringingFromThemInCallSound)
            mediaManager.stop(sound: .ringingFromThemSound)
        }

    }

}

extension SoundEventListener {

    @objc
    func applicationWillEnterForeground() {
        soundEventWatchDog.startIgnoreDate = Date()
        soundEventWatchDog.isMuted = userSession?.networkState == .onlineSynchronizing

        if AppDelegate.shared.launchType == .push {
            soundEventWatchDog.ignoreTime = SoundEventListener.SoundEventListenerIgnoreTimeForPushStart
        } else {
            soundEventWatchDog.ignoreTime = 0.0
        }
    }

    @objc
    func applicationDidEnterBackground() {
        soundEventWatchDog.isMuted = true
    }
}

extension SoundEventListener: ZMNetworkAvailabilityObserver {

    func didChangeAvailability(newState: ZMNetworkState) {
        guard UIApplication.shared.applicationState != .background else { return }

        if newState == .online {
            soundEventWatchDog.isMuted = false
        }
    }

}
