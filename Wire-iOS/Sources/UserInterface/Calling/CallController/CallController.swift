//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import UIKit
import WireSyncEngine

final class CallController: NSObject {

    // MARK: - Public Implentation
    weak var router: CallRouterProtocol?
    
    // MARK: - Private Implentation
    private var observerTokens: [Any] = []
    private var minimizedCall: ZMConversation?
    private var topOverlayCall: ZMConversation? = nil {
        didSet {
            guard topOverlayCall != oldValue else { return }
            guard let conversation = topOverlayCall else {
                ZClientViewController.shared?.setTopOverlay(to: nil)
                return
            }
            router?.showCallTopOverlayController(for: conversation)
        }
    }
    
    private var dateOfLastErrorAlertByConversationId = [UUID: Date]()
    private var alertDebounceInterval: TimeInterval { 15 * .oneMinute  }
    
    // MARK: - Init
    override init() {
        super.init()
        addObservers()
    }
    
    // MARK: - Public Impletation
    func updateState() {
        guard let userSession = ZMUserSession.shared() else { return }
        guard let priorityCallConversation = userSession.priorityCallConversation else { dismissCall(); return }
        
        topOverlayCall = priorityCallConversation
        
        priorityCallConversation == minimizedCall
            ? minimizeCall()
            : presentCall(in: priorityCallConversation)
    }
    
    // MARK: - Private Implementation
    private func addObservers() {
        if let userSession = ZMUserSession.shared() {
            observerTokens.append(WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession))
            observerTokens.append(WireCallCenterV3.addCallErrorObserver(observer: self, userSession: userSession))
        }
    }
    
    private func minimizeCall() {
        router?.minimizeCall(animated: true, completion: nil)
    }

    private func presentCall(in conversation: ZMConversation) {
        guard let voiceChannel = conversation.voiceChannel else { return }
        if minimizedCall == conversation { minimizedCall = nil }
        
        let animated = shouldAnimate(call: conversation)
        router?.presentActiveCall(for: voiceChannel, animated: animated)
    }

    private func dismissCall() {
        router?.dismissActiveCall(animated: true, completion: { [weak self] in
            self?.minimizedCall = nil
            self?.topOverlayCall = nil
        })
    }
    
    private func shouldAnimate(call: ZMConversation) -> Bool {
        guard SessionManager.shared?.callNotificationStyle == .callKit else {
            return true
        }
        
        switch call.voiceChannel?.state {
        case .outgoing?:
            return true
        default:
            return false // We don't want animate when transition from CallKit screen
        }
    }
    
    private func isClientOutdated(callState: CallState) -> Bool {
        switch callState {
        case .terminating(let reason) where reason == .outdatedClient:
            return true
        default:
            return false
        }
    }
}

// MARK: - WireCallCenterCallStateObserver
extension CallController: WireCallCenterCallStateObserver {

    func callCenterDidChange(callState: CallState,
                             conversation: ZMConversation,
                             caller: UserType,
                             timestamp: Date?,
                             previousCallState: CallState?) {
        presentUnsupportedVersionAlertIfNecessary(callState: callState)
        handleDegradedConversationIfNecessary(conversation)
        updateState()
    }
    
    private func presentUnsupportedVersionAlertIfNecessary(callState: CallState) {
        guard isClientOutdated(callState: callState) else { return }
        router?.presentUnsupportedVersionAlert()
    }
    
    private func handleDegradedConversationIfNecessary(_ conversation: ZMConversation) {
        guard let degradationState = conversation.voiceChannel?.degradationState else {
            return
        }
        switch degradationState {
        case .incoming(degradedUser: let user):
            router?.presentSecurityDegradedAlert(degradedUser: user)
        default:
            break
        }
    }
}

// MARK: - ActiveCallViewControllerDelegate
extension CallController: ActiveCallViewControllerDelegate {
    func callControllerDidDisappear(_ callController: CallViewController) {
        router?.dismissActiveCall(animated: true, completion: nil)
        minimizedCall = callController.conversation
    }
}

// MARK: - WireCallCenterCallErrorObserver
extension CallController: WireCallCenterCallErrorObserver {
    func callCenterDidReceiveCallError(_ error: CallError, conversationId: UUID) {
        guard
            error == .unknownProtocol,
            shouldDisplayErrorAlert(for: conversationId)
        else {
            return
        }

        dateOfLastErrorAlertByConversationId[conversationId] = Date()
        router?.presentUnsupportedVersionAlert()
    }
    
    private func shouldDisplayErrorAlert(for conversation: UUID) -> Bool {
           guard let dateOfLastErrorAlert = dateOfLastErrorAlertByConversationId[conversation] else {
               return true
           }

           let elapsedTimeIntervalSinceLastAlert = -dateOfLastErrorAlert.timeIntervalSinceNow
           return elapsedTimeIntervalSinceLastAlert > alertDebounceInterval
       }
}
