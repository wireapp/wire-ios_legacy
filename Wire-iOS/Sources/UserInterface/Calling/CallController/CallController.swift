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

class CallController: NSObject {
    
    weak var targetViewController: UIViewController? = nil
    private(set) weak var activeCallViewController: ActiveCallViewController?
    fileprivate var token: Any?
    
    override init() {
        super.init()
        
        if let userSession = ZMUserSession.shared() {
            token = WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession)
        }
        
    }
}

extension CallController: WireCallCenterCallStateObserver {
    
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?, previousCallState: CallState?) {
        
        if let callingConversation = callingConversation {
            presentCall(in: callingConversation)
        } else {
            dismissCall()
        }
    }
    
    func minimizeCall(completion: (() -> Void)?) {
        guard let activeCallViewController = activeCallViewController else { return completion?() }
        
        activeCallViewController.dismiss(animated: true, completion: completion)
    }
    
    fileprivate var callingConversation : ZMConversation? {
        guard let userSession = ZMUserSession.shared(), let callCenter = userSession.callCenter else { return nil }
        
        let conversationsWithIncomingCall = callCenter.nonIdleCallConversations(in: userSession).filter({ conversation -> Bool in
            guard let callState = conversation.voiceChannel?.state else { return false }
            
            switch callState {
            case .incoming(video: _, shouldRing: true, degraded: _):
                return !conversation.isSilenced
            default:
                return false
            }
        })
        
        if conversationsWithIncomingCall.count > 0 {
            return conversationsWithIncomingCall.last
        }
        
        return ZMUserSession.shared()?.ongoingCallConversation
    }
    
    fileprivate func minimizeCall(in conversation: ZMConversation) {
        let callTopOverlayController = CallTopOverlayController(conversation: conversation)
        callTopOverlayController.delegate = self
        ZClientViewController.shared()?.setTopOverlay(to: callTopOverlayController)
    }
    
    fileprivate  func presentCall(in conversation: ZMConversation) {
        guard activeCallViewController == nil else { return }
        guard let voiceChannel = conversation.voiceChannel else { return }
        
        let viewController = ActiveCallViewController(voiceChannel: voiceChannel)
        viewController.dismisser = self
        activeCallViewController = viewController
        
        let modalVC = ModalPresentationViewController(viewController: viewController)
        ZClientViewController.shared()?.setTopOverlay(to: nil)
        targetViewController?.present(modalVC, animated: true)
    }
    
    fileprivate func dismissCall() {
        ZClientViewController.shared()?.setTopOverlay(to: nil, animated: true)
        activeCallViewController?.dismiss(animated: true)
    }
}

extension CallController: ViewControllerDismisser {
    
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        guard let callViewController = viewController as? CallViewController, let conversation = callViewController.conversation else { return }
        
        minimizeCall(in: conversation)
    }
    
}

extension CallController: CallTopOverlayControllerDelegate {
    
    func voiceChannelTopOverlayWantsToRestoreCall(_ controller: CallTopOverlayController) {
        presentCall(in: controller.conversation)
        ZClientViewController.shared()?.setTopOverlay(to: nil, animated: false)
    }
    
}
