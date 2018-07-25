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
import StoreKit

fileprivate let zmLog = ZMSLog(tag: "calling")

class ActiveVoiceChannelViewController : UIViewController {
    
    var callStateObserverToken : Any?
    var answeredCalls: [UUID: Date] = [:]
    var minimisedCall: UUID? = nil {
        didSet {
            updateVisibleVoiceChannelViewController()
        }
    }
    
    deinit {
        visibleVoiceChannelTopOverlayVoiceController?.stopCallDurationTimer()
    }
    
    var visibleVoiceChannelViewController : CallViewController? {
        didSet {
            if let newController = visibleVoiceChannelViewController {
                newController.dismisser = self
                transition(to: newController, from: oldValue)
            }
            else {
                transition(to: nil, from: oldValue)
            }
        }
    }
    
    var visibleVoiceChannelTopOverlayVoiceController: CallTopOverlayController? {
        didSet {
            visibleVoiceChannelTopOverlayVoiceController?.delegate = self
            ZClientViewController.shared()?.setTopOverlay(to: visibleVoiceChannelTopOverlayVoiceController)
        }
    }
    
    override func loadView() {
        view = PassthroughTouchesView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let userSession = ZMUserSession.shared() else {
            zmLog.error("UserSession not available when initializing \(type(of: self))")
            return
        }
        
        callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateVisibleVoiceChannelViewController()
    }

    override var prefersStatusBarHidden: Bool {
        return visibleVoiceChannelViewController?.prefersStatusBarHidden ?? false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return visibleVoiceChannelViewController?.preferredStatusBarStyle ?? .default
    }
    
    func updateVisibleVoiceChannelViewController() {
        let conversation = primaryCallingConversation
       
        if let conversation = conversation {
            // Call was minimized
            if conversation.remoteIdentifier == minimisedCall {
                guard visibleVoiceChannelTopOverlayVoiceController == nil ||
                    visibleVoiceChannelTopOverlayVoiceController!.conversation != conversation else {
                    return
                }
                
                visibleVoiceChannelViewController = nil
                visibleVoiceChannelTopOverlayVoiceController = CallTopOverlayController(conversation: conversation)
            }
            else {
                guard visibleVoiceChannelViewController == nil ||
                    visibleVoiceChannelViewController!.conversation != conversation else {
                    return
                }
                
                if let voiceChannel = conversation.voiceChannel, shouldPresentCallOverlay() {
                    visibleVoiceChannelViewController = CallViewController(voiceChannel: voiceChannel)
                }
                visibleVoiceChannelTopOverlayVoiceController = nil
            }
        } else {
            visibleVoiceChannelViewController = nil
            visibleVoiceChannelTopOverlayVoiceController = nil
        }
    }
    
    fileprivate func updateMinimisedCall(with callState: CallState,
                                         conversation: ZMConversation) {
        switch callState {
        case .terminating(_):
            if minimisedCall == conversation.remoteIdentifier! {
                minimisedCall = nil
            }
        default:
            break
        }
    }
    
    private func shouldPresentCallOverlay() -> Bool {
        switch (primaryCallingConversation?.voiceChannel?.state, SessionManager.shared?.callNotificationStyle) {
        case (.incoming?, .callKit?): return false
        default: return true
        }
    }
    
    func transition(to: UIViewController?, from: UIViewController?) {
        guard to != from else { return }
        
        zmLog.debug(String(format: "transitioning to VoiceChannelViewController: %p from: %p", to ?? 0, from ?? 0))
        
        UIApplication.shared.keyWindow?.endEditing(true)
        
        if let toViewController = to, let fromViewController = from {
            
            toViewController.view.frame = view.bounds
            toViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            addChildViewController(toViewController)
            
            transition(from: fromViewController,
                       to: toViewController,
                       duration: 0.35,
                       options: .transitionCrossDissolve,
                       animations: nil,
                       completion:
                { (finished) in
                    toViewController.didMove(toParentViewController: self)
                    fromViewController.removeFromParentViewController()
                    UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            })
        } else if let toViewController = to {
            addChildViewController(toViewController)
            
            toViewController.view.frame = view.bounds
            toViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            view.addSubview(toViewController.view)
            
            toViewController.view.alpha = 0
            
            UIView.animate(withDuration: 0.35, animations: {
                toViewController.view.alpha = 1
            }, completion: { (finished) in
                toViewController.didMove(toParentViewController: self)
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            })
        } else if let fromViewController = from {
            fromViewController.willMove(toParentViewController: nil)
            
            UIView.animate(withDuration: 0.35, animations: {
                fromViewController.view.alpha = 0
            }, completion: { (finished) in
                fromViewController.view.removeFromSuperview()
                fromViewController.removeFromParentViewController()
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            })
        }
    }
    
    var voiceChannelIsActive : Bool {
        return visibleVoiceChannelViewController != nil
    }
    
    var primaryCallingConversation : ZMConversation? {
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
        
        return ongoingCallConversation
    }
    
    
    var ongoingCallConversation : ZMConversation? {
        guard let userSession = ZMUserSession.shared(), let callCenter = userSession.callCenter else { return nil }
        
        return callCenter.nonIdleCallConversations(in: userSession).first { (conversation) -> Bool in
            guard let callState = conversation.voiceChannel?.state else { return false }
            
            switch callState {
            case .answered, .established, .establishedDataChannel, .outgoing:
                return true
            default:
                return false
            }
        }
        
    }
    
}

extension ActiveVoiceChannelViewController : WireCallCenterCallStateObserver {
    
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?, previousCallState: CallState?)  {
        updateVisibleVoiceChannelViewController()
        updateMinimisedCall(with: callState, conversation: conversation)
        
        let changeDate = Date()

        // Only show the survey in internal builds (review required)
        guard DeveloperMenuState.developerMenuEnabled() else { return }

        guard !Analytics.shared().isOptedOut,
            !TrackingManager.shared.disableCrashAndAnalyticsSharing else {
                return
        }

        switch callState {
        case .established:
            answeredCalls[conversation.remoteIdentifier!] = Date()
        default:
            break
        }

        if let presentedController = self.presentedViewController as? CallQualityViewController {
            presentedController.dismiss(animated: true, completion: nil)
        }

        if case let .terminating(reason) = callState {
            
            guard let callStartDate = answeredCalls[conversation.remoteIdentifier!] else {
                return
            }

            // Only show the survey if the call was longer that 10 seconds

            let callDuration = changeDate.timeIntervalSince(callStartDate)

            guard AutomationHelper.sharedHelper.useAnalytics else {
                CallQualityScoreProvider.shared.recordCallQualityReview(.notDisplayed(reason: .callTooShort, duration: Int(callDuration)))
                return
            }
            
            guard callDuration > 10 else {
                CallQualityScoreProvider.shared.recordCallQualityReview(.notDisplayed(reason: .callTooShort, duration: Int(callDuration)))
                return
            }

            // Only show the survey if the call finished without errors
            guard reason == .normal || reason == .stillOngoing else {
                CallQualityScoreProvider.shared.recordCallQualityReview(.notDisplayed(reason: .callFailed, duration: Int(callDuration)))
                return
            }
            
            guard let qualityController = CallQualityViewController.requestSurveyController(callDuration: callDuration) else {
                CallQualityScoreProvider.shared.recordCallQualityReview(.notDisplayed(reason: .muted, duration: Int(callDuration)))
                return
            }
            
            qualityController.delegate = self
            qualityController.transitioningDelegate = self
            
            answeredCalls[conversation.remoteIdentifier!] = nil
            present(qualityController, animated: true)
        }
    }
    
}

extension ActiveVoiceChannelViewController : UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return (presented is CallQualityViewController) ? CallQualityPresentationTransition() : nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return (dismissed is CallQualityViewController) ? CallQualityDismissalTransition() : nil
    }
    
}

extension ActiveVoiceChannelViewController : CallQualityViewControllerDelegate {
    
    func callQualityController(_ controller: CallQualityViewController, didSelect score: Int) {
        if score >= 4, #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }
        
        controller.dismiss(animated: true, completion: nil)
        
        CallQualityScoreProvider.updateLastSurveyDate(Date())
        CallQualityScoreProvider.shared.recordCallQualityReview(.answered(score: score, duration: controller.callDuration))
    }
    
    func callQualityControllerDidFinishWithoutScore(_ controller: CallQualityViewController) {
        CallQualityScoreProvider.updateLastSurveyDate(Date())
        CallQualityScoreProvider.shared.recordCallQualityReview(.dismissed(duration: controller.callDuration))
        controller.dismiss(animated: true, completion: nil)
    }

}

extension ActiveVoiceChannelViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        minimisedCall = visibleVoiceChannelViewController?.conversation?.remoteIdentifier
        completion?()
    }
}

extension ActiveVoiceChannelViewController: CallTopOverlayControllerDelegate {
    func voiceChannelTopOverlayWantsToRestoreCall(_ controller: CallTopOverlayController) {
        minimisedCall = nil
    }
}
