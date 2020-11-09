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

// MARK: - CallRouterProtocol
protocol CallRouterProtocol: class {
    func presentActiveCall(for voiceChannel: VoiceChannel, animated: Bool)
    func dismissActiveCall(animated: Bool, completion: (()-> Void)?)
    func minimizeCall(animated: Bool, completion: (() -> Void)?)
    func showCallTopOverlayController(for conversation: ZMConversation)
    func hideCallTopOverlayController()
    func presentSecurityDegradedAlert(degradedUser: UserType?)
    func presentUnsupportedVersionAlert()
}

// MARK: - CallQualityRouterProtocol
protocol CallQualityRouterProtocol: class {
    func presentCallQualitySurvey(with callDuration: TimeInterval)
    func dismissCallQualitySurvey(completion: (()-> Void)?)
    func presentCallFailureDebugAlert()
    func presentCallQualityRejection()
}

// MARK: - CallRouter
class CallRouter: NSObject {
    
    // MARK: - Private Property
    private let rootViewController: RootViewController
    private let callController: CallController
    private let callQualityController: CallQualityController
    
    private var isActiveCallShown = false
    private var isCallQualityShown = false
    private var scheduledPostCallAction: (() -> Void)?
        
    init(rootviewController: RootViewController) {
        self.rootViewController = rootviewController
        callController = CallController()
        callQualityController = CallQualityController()
        
        super.init()
        
        callController.router = self
        callQualityController.router = self
    }
        
    // MARK: - Public Implementation
    func updateCallState() {
        callController.updateState()
    }
}

// MARK: - CallRouterProtocol
extension CallRouter: CallRouterProtocol {
    func presentActiveCall(for voiceChannel: VoiceChannel, animated: Bool) {
        guard !isActiveCallShown else { return }
        
        // NOTE: We resign first reponder for the input bar since it will attempt to restore
        // first responder when the call overlay is interactively dismissed but canceled.
        UIResponder.currentFirst?.resignFirstResponder()

        let activeCallViewController = ActiveCallViewController(voiceChannel: voiceChannel)
        activeCallViewController.delegate = callController
        
        let modalVC = ModalPresentationViewController(viewController: activeCallViewController)

        rootViewController.isPresenting
            ? dismissPresentedAndPresentActiveCall(modalViewController: modalVC, animated: animated)
            : presentActiveCall(modalViewController: modalVC, animated: animated)
    }
    
    func dismissActiveCall(animated: Bool = true, completion: (()-> Void)? = nil) {
        rootViewController.dismiss(animated: animated, completion: { [weak self] in
            self?.isActiveCallShown = false
            self?.scheduledPostCallAction?()
            self?.scheduledPostCallAction = nil
            completion?()
        })
    }
    
    func minimizeCall(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard isActiveCallShown else { completion?(); return }
        dismissActiveCall(animated: animated, completion: completion)
    }
    
    func showCallTopOverlayController(for conversation: ZMConversation) {
        let callTopOverlayController = CallTopOverlayController(conversation: conversation)
        callTopOverlayController.delegate = self
        let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self)
        zClientViewController?.setTopOverlay(to: callTopOverlayController)
    }
    
    func hideCallTopOverlayController() {
        let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self)
        zClientViewController?.setTopOverlay(to: nil)
    }
    
    func presentSecurityDegradedAlert(degradedUser: UserType?) {
        executeOrSchedulePostCallAction { [weak self] in
            let alert = UIAlertController.degradedCall(degradedUser: degradedUser, callEnded: true)
            self?.rootViewController.present(alert, animated: true)
        }
    }
    
    func presentUnsupportedVersionAlert() {
        executeOrSchedulePostCallAction { [weak self] in
            let alert = UIAlertController.unsupportedVersionAlert
            self?.rootViewController.present(alert, animated: true)
        }
    }
    
    // MARK: - Private Navigation Helpers
    
    private func dismissPresentedAndPresentActiveCall(modalViewController: ModalPresentationViewController,
                                                      animated: Bool) {
        rootViewController.presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.presentActiveCall(modalViewController: modalViewController, animated: animated)
        })
    }
    
    private func presentActiveCall(modalViewController: ModalPresentationViewController, animated: Bool) {
        rootViewController.present(modalViewController, animated: animated, completion: { [weak self] in
            self?.isActiveCallShown = true
        })
    }
    
    // MARK: - Helpers
    
    private func executeOrSchedulePostCallAction(_ action: @escaping () -> Void) {
        if isActiveCallShown {
            action()
        } else {
            scheduledPostCallAction = action
        }
    }
}

// MARK: - CallRouterProtocol
extension CallRouter: CallQualityRouterProtocol {
    func presentCallQualitySurvey(with callDuration: TimeInterval) {
        let qualityController = buildCallQualitySurvey(with: callDuration)
        
        executeOrSchedulePostCallAction { [weak self] in
            self?.rootViewController.present(qualityController, animated: true, completion: { [weak self] in
                self?.isCallQualityShown = true
            })
        }
    }
    
    func dismissCallQualitySurvey(completion: (()-> Void)? = nil) {
        guard isCallQualityShown else { return }
        rootViewController.dismiss(animated: true, completion: { [weak self] in
            self?.isCallQualityShown = false
            completion?()
        })
    }

    func presentCallFailureDebugAlert() {
        executeOrSchedulePostCallAction {
            DebugAlert.showSendLogsMessage(message: "The call failed. Sending the debug logs can help us troubleshoot the issue and improve the overall app experience.")
        }
    }
    
    func presentCallQualityRejection() {
        DebugAlert.showSendLogsMessage(message: "Sending the debug logs can help us improve the quality of calls and the overall app experience.")
    }
    
    private func buildCallQualitySurvey(with callDuration: TimeInterval) -> CallQualityViewController {
        let questionLabelText = NSLocalizedString("calling.quality_survey.question", comment: "")
        let qualityController = CallQualityViewController(questionLabelText: questionLabelText,
                                                          callDuration: Int(callDuration))
        qualityController.delegate = callQualityController
        
        qualityController.modalPresentationCapturesStatusBarAppearance = true
        qualityController.modalPresentationStyle = .overFullScreen
        qualityController.transitioningDelegate = self
        return qualityController
    }
}

// MARK: - CallTopOverlayControllerDelegate
extension CallRouter: CallTopOverlayControllerDelegate {
    func voiceChannelTopOverlayWantsToRestoreCall(voiceChannel:VoiceChannel?) {
        guard let voiceChannel = voiceChannel else { return }
        presentActiveCall(for: voiceChannel, animated: true)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension CallRouter: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return (presented is CallQualityViewController) ? CallQualityPresentationTransition() : nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return (dismissed is CallQualityViewController) ? CallQualityDismissalTransition() : nil
    }
}
