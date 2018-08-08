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

/**
 * Provides information to the event handling manager and executes actions.
 */

protocol AuthenticationEventHandlingManagerDelegate: class {
    var statusProvider: AuthenticationStatusProvider? { get }
    var currentStep: AuthenticationFlowStep { get }
    func executeActions(_ actions: [AuthenticationCoordinatorAction])
}

/**
 * Manages the event handlers for authentication.
 */

class AuthenticationEventHandlingManager {

    /**
     * The supported event types.
     */

    enum EventType {
        case initialSyncCompleted
        case backupReady(Bool)
        case clientRegistrationError(NSError, UUID)
        case clientRegistrationSuccess
    }

    // MARK: - Properties

    weak var delegate: AuthenticationEventHandlingManagerDelegate?

    // MARK: - Configuration

    var initialSyncHandlers: [AnyAuthenticationEventHandler<Void>] = []
    var backupEventHandlers: [AnyAuthenticationEventHandler<Bool>] = []
    var clientRegistrationErrorHandlers: [AnyAuthenticationEventHandler<(NSError, UUID)>] = []
    var clientRegistrationSuccessHandlers: [AnyAuthenticationEventHandler<Void>] = []

    /**
     * Configures the object with the given delegate and registers the default observers.
     */

    func configure(delegate: AuthenticationEventHandlingManagerDelegate) {
        self.delegate = delegate
        self.registerDefaultEventHandlers()
    }

    /**
     * Creates and registers the default error handlers.
     */

    fileprivate func registerDefaultEventHandlers() {
        // initialSyncHandlers
        registerHandler(AuthenticationInitialSyncEventHandler(), to: &initialSyncHandlers)

        // clientRegistrationErrorHandlers
        registerHandler(AuthenticationClientLimitErrorHandler(), to: &clientRegistrationErrorHandlers)
        registerHandler(AuthenticationNoCredentialsErrorHandler(), to: &clientRegistrationErrorHandlers)
        registerHandler(AuthenticationNeedsReauthenticationErrorHandler(), to: &clientRegistrationErrorHandlers)

        // backupEventHandlers
        registerHandler(AuthenticationBackupReadyEventHandler(), to: &backupEventHandlers)

        // clientRegistrationSuccessHandlers
        registerHandler(AuthenticationClientRegistrationSuccessHandler(), to: &clientRegistrationSuccessHandlers)
    }

    fileprivate func registerHandler<Handler: AuthenticationEventHandler>(_ handler: Handler, to handlerList: inout [AnyAuthenticationEventHandler<Handler.Context>]) {
        let box = AnyAuthenticationEventHandler(handler)
        handlerList.append(box)
    }

    // MARK: - Event Handling

    /**
     * Handles the event using the current delegate.
     */

    func handleEvent(ofType eventType: EventType) {
        switch eventType {
        case .initialSyncCompleted:
            handleEvent(with: initialSyncHandlers, context: ())
        case .backupReady(let existingAccount):
            handleEvent(with: backupEventHandlers, context: existingAccount)
        case .clientRegistrationError(let error, let accountID):
            handleEvent(with: clientRegistrationErrorHandlers, context: (error, accountID))
        case .clientRegistrationSuccess:
            handleEvent(with: clientRegistrationSuccessHandlers, context: ())
        }
    }

    /**
     * Requests the coordinator to handle the event with the specified context, using the given handlers.
     */

    private func handleEvent<Context>(with handlers: [AnyAuthenticationEventHandler<Context>], context: Context) {
        guard let delegate = self.delegate else {
            return
        }

        var actions: [AuthenticationCoordinatorAction]?

        for handler in handlers {
            handler.statusProvider = delegate.statusProvider

            if let responseActions = handler.handleEvent(currentStep: delegate.currentStep, context: context) {
                actions = responseActions
                break
            }
        }

        let resolvedActions = actions ?? []
        delegate.executeActions(resolvedActions)
    }

}
