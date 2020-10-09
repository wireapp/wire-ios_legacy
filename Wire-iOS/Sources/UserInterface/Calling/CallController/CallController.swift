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

    weak var targetViewController: UIViewController?
    private(set) weak var activeCallViewController: ActiveCallViewController?
    private let callQualityController = CallQualityController()
    private var scheduledPostCallAction: (() -> Void)?
    private var observerTokens: [Any] = []
    private var minimizedCall: ZMConversation?
    private var topOverlayCall: ZMConversation? = nil {
        didSet {
            guard  topOverlayCall != oldValue else { return }

            if let conversation = topOverlayCall {
                let callTopOverlayController = CallTopOverlayController(conversation: conversation)
                callTopOverlayController.delegate = self
                ZClientViewController.shared?.setTopOverlay(to: callTopOverlayController)
            } else {
                ZClientViewController.shared?.setTopOverlay(to: nil)
            }
        }
    }

    override init() {
        super.init()
        callQualityController.delegate = self

        if let userSession = ZMUserSession.shared() {
            observerTokens.append(WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession))
            observerTokens.append(WireCallCenterV3.addCallErrorObserver(observer: self, userSession: userSession))
        }
    }
}

// MARK: - Call State Observer

extension CallController: WireCallCenterCallStateObserver {

    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        if isClientOutdated(callState: callState) {
            scheduleUnsupportedVersionAlert()
        }
        handleDegradedConversationIfNeeded(conversation)
        updateState()
    }
    
    private func handleDegradedConversationIfNeeded(_ conversation: ZMConversation) {
        guard let degradationState = conversation.voiceChannel?.degradationState else {
            return
        }
        switch degradationState {
        case .incoming(degradedUser: let user):
            scheduleSecurityDegradedAlert(degradedUser: user)
        default:
            break
        }
    }
    
    private func scheduleSecurityDegradedAlert(degradedUser: UserType?) {
        executeOrSchedulePostCallAction { [weak self] in
            self?.targetViewController?.present(UIAlertController.degradedCall(degradedUser: degradedUser, callEnded: true), animated: true)
        }
    }
    
    private func scheduleUnsupportedVersionAlert() {
        executeOrSchedulePostCallAction { [weak self] in
            self?.targetViewController?.present(UIAlertController.unsupportedVersionAlert, animated: true)
        }
    }

    func updateState() {
        guard let userSession = ZMUserSession.shared() else { return }
        
        guard let priorityCallConversation = userSession.priorityCallConversation else {
            dismissCall()
            return
        }
        
        topOverlayCall = priorityCallConversation
        
        if priorityCallConversation == minimizedCall {
            minimizeCall(in: priorityCallConversation)
        } else {
            presentCall(in: priorityCallConversation,
                        animated: shouldAnimate(call: priorityCallConversation))
        }
    }
}

// MARK: - Call Presentation

extension CallController {

    func minimizeCall(animated: Bool, completion: (() -> Void)?) {
        guard let activeCallViewController = activeCallViewController else {
            completion?()
            return
        }

        activeCallViewController.dismiss(animated: animated, completion: completion)
    }

    private func minimizeCall(in conversation: ZMConversation) {
        activeCallViewController?.dismiss(animated: true)
    }

    private func presentCall(in conversation: ZMConversation, animated: Bool = true) {
        guard
            activeCallViewController == nil,
            let voiceChannel = conversation.voiceChannel
        else {
            return
        }

        if minimizedCall == conversation {
            minimizedCall = nil
        }

        let viewController = ActiveCallViewController(voiceChannel: voiceChannel)
        viewController.dismisser = self
        activeCallViewController = viewController

        // NOTE: We resign first reponder for the input bar since it will attempt to restore
        // first responder when the call overlay is interactively dismissed but canceled.
        UIResponder.currentFirst?.resignFirstResponder()

        let modalVC = ModalPresentationViewController(viewController: viewController)

        let presentClosure: Completion = {
            self.targetViewController?.present(modalVC, animated: animated)
        }

        if targetViewController?.presentedViewController != nil {
            targetViewController?.presentedViewController?.dismiss(animated: true, completion: presentClosure)
        } else {
            presentClosure()
        }
    }

    private func dismissCall() {
        minimizedCall = nil
        topOverlayCall = nil

        activeCallViewController?.dismiss(animated: true) { [weak self] in
            if let postCallAction = self?.scheduledPostCallAction {
                postCallAction()
                self?.scheduledPostCallAction = nil
            }
            self?.activeCallViewController = nil
        }
    }
}

// MARK: - ViewControllerDismisser

extension CallController: ViewControllerDismisser {

    func dismiss(viewController: UIViewController, completion: Completion? = nil) {
        guard let callViewController = viewController as? CallViewController,
            let conversation = callViewController.conversation else { return }

        minimizedCall = conversation
        activeCallViewController = nil
    }

}

// MARK: - CallTopOverlayControllerDelegate

extension CallController: CallTopOverlayControllerDelegate {

    func voiceChannelTopOverlayWantsToRestoreCall(_ controller: CallTopOverlayController) {
        presentCall(in: controller.conversation)
    }

}

// MARK: - CallQualityControllerDelegate

extension CallController: CallQualityControllerDelegate {

    func dismissCurrentSurveyIfNeeded() {
        if let survey = targetViewController?.presentedViewController as? CallQualityViewController {
            survey.dismiss(animated: true)
        }
    }

    func callQualityControllerDidScheduleSurvey(with controller: CallQualityViewController) {
        executeOrSchedulePostCallAction { [weak self] in
            self?.targetViewController?.present(controller, animated: true, completion: nil)
        }
    }

    func callQualityControllerDidScheduleDebugAlert() {
        executeOrSchedulePostCallAction {
            DebugAlert.showSendLogsMessage(message: "The call failed. Sending the debug logs can help us troubleshoot the issue and improve the overall app experience.")
        }
    }

}

// MARK: - WireCallCenterCallErrorObserver

extension CallController: WireCallCenterCallErrorObserver {

    private static var dateOfLastErrorAlertByConversationId = [UUID: Date]()

    private var alertDebounceInterval: TimeInterval { 15 * .oneMinute  }

    private func shouldDisplayErrorAlert(for conversation: UUID) -> Bool {
        guard let dateOfLastErrorAlert = type(of: self).dateOfLastErrorAlertByConversationId[conversation] else {
            return true
        }

        let elapsedTimeIntervalSinceLastAlert = -dateOfLastErrorAlert.timeIntervalSinceNow
        return elapsedTimeIntervalSinceLastAlert > alertDebounceInterval
    }

    func callCenterDidReceiveCallError(_ error: CallError, conversationId: UUID) {
        guard
            error == .unknownProtocol,
            shouldDisplayErrorAlert(for: conversationId)
        else {
            return
        }

        type(of: self).dateOfLastErrorAlertByConversationId[conversationId] = .init()
        targetViewController?.present(UIAlertController.unsupportedVersionAlert, animated: true)
    }
}

// MARK: - Helpers

extension CallController {
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
    
    private func executeOrSchedulePostCallAction(_ action: @escaping () -> Void) {
        if self.activeCallViewController == nil {
            action()
        } else {
            scheduledPostCallAction = action
        }
    }
}

