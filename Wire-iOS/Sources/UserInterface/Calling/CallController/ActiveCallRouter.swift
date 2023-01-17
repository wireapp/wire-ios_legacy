//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

// MARK: - ActiveCallRouterProtocol
protocol ActiveCallRouterProtocol: AnyObject {
    func presentActiveCall(for voiceChannel: VoiceChannel, animated: Bool)
    func dismissActiveCall(animated: Bool, completion: Completion?)
    func minimizeCall(animated: Bool, completion: Completion?)
    func showCallTopOverlay(for conversation: ZMConversation)
    func hideCallTopOverlay()
    func presentSecurityDegradedAlert(degradedUser: UserType?)
    func presentUnsupportedVersionAlert()
}

// MARK: - CallQualityRouterProtocol
protocol CallQualityRouterProtocol: AnyObject {
    func presentCallQualitySurvey(with callDuration: TimeInterval)
    func dismissCallQualitySurvey(completion: Completion?)
    func presentCallFailureDebugAlert()
    func presentCallQualityRejection()
}

// MARK: - ActiveCallRouter
class ActiveCallRouter: NSObject {

    // MARK: - Public Property
    var isActiveCallShown = false {
        didSet {
            if isActiveCallShown {
                isPresentingActiveCall = false
            }
        }
    }

    var isPresentingActiveCall = false

    // MARK: - Private Property
    private let rootViewController: RootViewController
    private let callController: CallController
    private let callQualityController: CallQualityController
    private var transitioningDelegate: CallQualityAnimator

    private var isCallQualityShown = false
    private var isCallTopOverlayShown = false
    private(set) var scheduledPostCallAction: (() -> Void)?

    private var zClientViewController: ZClientViewController? {
        return rootViewController.firstChild(ofType: ZClientViewController.self)
    }

    init(rootviewController: RootViewController) {
        self.rootViewController = rootviewController
        callController = CallController()
        callController.callConversationProvider = ZMUserSession.shared()
        callQualityController = CallQualityController()
        transitioningDelegate = CallQualityAnimator()

        super.init()

        callController.router = self
        callQualityController.router = self
    }

    // MARK: - Public Implementation
    func updateActiveCallPresentationState() {
        callController.updateActiveCallPresentationState()
    }
}

// MARK: - ActiveCallRouterProtocol
extension ActiveCallRouter: ActiveCallRouterProtocol {
    // MARK: - ActiveCall
    func presentActiveCall(for voiceChannel: VoiceChannel, animated: Bool) {
        guard
            !isPresentingActiveCall,
            !isActiveCallShown
        else {
            return
        }

        // NOTE: We resign first reponder for the input bar since it will attempt to restore
        // first responder when the call overlay is interactively dismissed but canceled.
        UIResponder.currentFirst?.resignFirstResponder()

        let activeCallViewController = ActiveCallViewController(voiceChannel: voiceChannel)
        activeCallViewController.delegate = callController

        let modalVC = ModalPresentationViewController(viewController: activeCallViewController, enableDismissOnPan: !CallingConfiguration.config.paginationEnabled)

        if rootViewController.isPresenting {
            dismissPresentedAndPresentActiveCall(modalViewController: modalVC, animated: animated)
        } else {
            presentActiveCall(modalViewController: modalVC, animated: animated)
        }
    }

    func dismissActiveCall(animated: Bool = true, completion: Completion? = nil) {
        guard isActiveCallShown else {
            completion?()
            return
        }
        rootViewController.dismiss(animated: animated, completion: { [weak self] in
            self?.isActiveCallShown = false
            self?.scheduledPostCallAction?()
            self?.scheduledPostCallAction = nil
            completion?()
        })
    }

    func minimizeCall(animated: Bool = true, completion: Completion? = nil) {
        guard isActiveCallShown else { completion?(); return }
        dismissActiveCall(animated: animated, completion: completion)
    }

    // MARK: - CallTopOverlay
    func showCallTopOverlay(for conversation: ZMConversation) {
        guard !isCallTopOverlayShown else { return }
        let callTopOverlayController = CallTopOverlayController(conversation: conversation)
        callTopOverlayController.delegate = self
        zClientViewController?.setTopOverlay(to: callTopOverlayController)
        isCallTopOverlayShown = true
    }

    func hideCallTopOverlay() {
        zClientViewController?.setTopOverlay(to: nil)
        isCallTopOverlayShown = false
    }

    // MARK: - Alerts
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
        isPresentingActiveCall = true
        rootViewController.present(modalViewController, animated: animated, completion: { [weak self] in
            self?.isActiveCallShown = true
        })
    }

    // MARK: - Helpers

    func executeOrSchedulePostCallAction(_ action: @escaping () -> Void) {
        if !isActiveCallShown {
            action()
        } else {
            scheduledPostCallAction = action
        }
    }
}

// MARK: - CallQualityRouterProtocol
extension ActiveCallRouter: CallQualityRouterProtocol {
    func presentCallQualitySurvey(with callDuration: TimeInterval) {
        let qualityController = buildCallQualitySurvey(with: callDuration)

        executeOrSchedulePostCallAction { [weak self] in
            self?.rootViewController.present(qualityController, animated: true, completion: { [weak self] in
                self?.isCallQualityShown = true
            })
        }
    }

    func dismissCallQualitySurvey(completion: Completion? = nil) {
        guard isCallQualityShown else { return }
        rootViewController.dismiss(animated: true, completion: { [weak self] in
            self?.isCallQualityShown = false
            completion?()
        })
    }

    func presentCallFailureDebugAlert() {
        let logsMessage = "The call failed. Sending the debug logs can help us troubleshoot the issue and improve the overall app experience."
        executeOrSchedulePostCallAction {
            DebugAlert.showSendLogsMessage(message: logsMessage)
        }
    }

    func presentCallQualityRejection() {
        let logsMessage = "Sending the debug logs can help us improve the quality of calls and the overall app experience."
        executeOrSchedulePostCallAction {
            DebugAlert.showSendLogsMessage(message: logsMessage)
        }
    }

    private func buildCallQualitySurvey(with callDuration: TimeInterval) -> CallQualityViewController {
        let questionLabelText = NSLocalizedString("calling.quality_survey.question", comment: "")
        let qualityController = CallQualityViewController(questionLabelText: questionLabelText,
                                                          callDuration: Int(callDuration))
        qualityController.delegate = callQualityController

        qualityController.modalPresentationCapturesStatusBarAppearance = true
        qualityController.modalPresentationStyle = .overFullScreen
        qualityController.transitioningDelegate = transitioningDelegate
        return qualityController
    }
}

// MARK: - CallTopOverlayControllerDelegate
extension ActiveCallRouter: CallTopOverlayControllerDelegate {
    func voiceChannelTopOverlayWantsToRestoreCall(voiceChannel: VoiceChannel?) {
        guard let voiceChannel = voiceChannel else { return }
        isActiveCallShown = false
        presentActiveCall(for: voiceChannel, animated: true)
    }
}
