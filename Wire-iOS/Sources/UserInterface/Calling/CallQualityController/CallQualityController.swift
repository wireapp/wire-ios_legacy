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
import StoreKit

class CallQualityController: NSObject {
    
    weak var targetViewController: UIViewController? = nil
    
    fileprivate var answeredCalls: [UUID: Date] = [:]
    fileprivate var token: Any?
    
    override init() {
        super.init()
        
        if let userSession = ZMUserSession.shared() {
            token = WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession)
        }
        
    }
}
    
extension CallQualityController: WireCallCenterCallStateObserver {
    
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?, previousCallState: CallState?) {
        
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
        
        if let presentedController = targetViewController?.presentedViewController as? CallQualityViewController {
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
            targetViewController?.present(qualityController, animated: true)
        }
    }
    
}

extension CallQualityController : UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return (presented is CallQualityViewController) ? CallQualityPresentationTransition() : nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return (dismissed is CallQualityViewController) ? CallQualityDismissalTransition() : nil
    }
    
}

extension CallQualityController : CallQualityViewControllerDelegate {
    
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
