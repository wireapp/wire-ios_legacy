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
import WireSystem
import WireDataModel

/**
 * Provides information to the event responder chain and executes actions.
 */

protocol AuthenticationEventResponderChainDelegate: AnyObject {

    /// The object providing authentication status info.
    var statusProvider: AuthenticationStatusProvider { get }

    /// The object providing the current authentication state.
    var stateController: AuthenticationStateController { get }

    /**
     * Executes the specified actions.
     * - parameter actions: The actions to execute.
     */

    func executeActions(_ actions: [AuthenticationCoordinatorAction])

}

/**
 * The authentication responder chain is responsible for dispatching events to supported
 * handlers, and determining what actions to execute in response.
 *
 * You configure the responder chain with a delegate, that will be responsible for providing
 * state and who will be responsible from
 */

class AuthenticationEventResponderChain {

    /**
     * The supported event types.
     */

    enum EventType {
        case flowStart(NSError?, Int)
        case initialSyncCompleted
        case backupReady(Bool)
        case clientRegistrationError(NSError, UUID)
        case clientRegistrationSuccess
        case authenticationFailure(NSError)
        case loginCodeAvailable
        case registrationError(NSError)
        case registrationStepSuccess
        case userProfileChange(UserChangeInfo)
        case userInput(Any)
    }

    // MARK: - Properties

    /// The handle to the OS log for authentication events.
    private let log = ZMSLog(tag: "Authentication")

    /// The object assisting the responder chain.
    weak var delegate: AuthenticationEventResponderChainDelegate?

    // MARK: - Initialization

    let featureProvider: AuthenticationFeatureProvider

    init(featureProvider: AuthenticationFeatureProvider) {
        self.featureProvider = featureProvider
    }

    // MARK: - Configuration

    var flowStartHandlers: [AnyAuthenticationEventHandler<(NSError?, Int)>] = []
    var initialSyncHandlers: [AnyAuthenticationEventHandler<Void>] = []
    var backupEventHandlers: [AnyAuthenticationEventHandler<Bool>] = []
    var clientRegistrationErrorHandlers: [AnyAuthenticationEventHandler<(NSError, UUID)>] = []
    var clientRegistrationSuccessHandlers: [AnyAuthenticationEventHandler<Void>] = []
    var loginErrorHandlers: [AnyAuthenticationEventHandler<NSError>] = []
    var loginCodeHandlers: [AnyAuthenticationEventHandler<Void>] = []
    var registrationErrorHandlers: [AnyAuthenticationEventHandler<NSError>] = []
    var registrationSuccessHandlers: [AnyAuthenticationEventHandler<Void>] = []
    var userProfileChangeObservers: [AnyAuthenticationEventHandler<UserChangeInfo>] = []
    var userInputObservers: [AnyAuthenticationEventHandler<Any>] = []

    /**
     * Configures the object with the given delegate and registers the default observers.
     * - parameter delegate: The object assisting the responder chain.
     */

    func configure(delegate: AuthenticationEventResponderChainDelegate) {
        self.delegate = delegate
        self.registerDefaultEventHandlers()
    }

    /**
     * Creates and registers the default error handlers.
     */

    fileprivate func registerDefaultEventHandlers() {
        // flowStartHandlers
        registerHandler(AuthenticationStartMissingCredentialsErrorHandler(), to: &flowStartHandlers)
        registerHandler(AuthenticationStartReauthenticateErrorHandler(), to: &flowStartHandlers)
        registerHandler(AuthenticationStartCompanyLoginLinkEventHandler(), to: &flowStartHandlers)
        registerHandler(AuthenticationStartAddAccountEventHandler(featureProvider: featureProvider), to: &flowStartHandlers)

        // initialSyncHandlers
        registerHandler(AuthenticationInitialSyncEventHandler(), to: &initialSyncHandlers)

        // clientRegistrationErrorHandlers
        registerHandler(AuthenticationClientLimitErrorHandler(), to: &clientRegistrationErrorHandlers)
        registerHandler(AuthenticationNoCredentialsErrorHandler(), to: &clientRegistrationErrorHandlers)
        registerHandler(AuthenticationNeedsReauthenticationErrorHandler(), to: &clientRegistrationErrorHandlers)
        registerHandler(ClientRegistrationErrorEventHandler(), to: &clientRegistrationErrorHandlers)

        // backupEventHandlers
        registerHandler(AuthenticationBackupReadyEventHandler(), to: &backupEventHandlers)

        // clientRegistrationSuccessHandlers
        registerHandler(RegistrationSessionAvailableEventHandler(), to: &clientRegistrationSuccessHandlers)
        registerHandler(AuthenticationClientRegistrationSuccessHandler(), to: &clientRegistrationSuccessHandlers)

        // loginErrorHandlers
        registerHandler(AuthenticationPhoneLoginErrorHandler(), to: &loginErrorHandlers)
        registerHandler(AuthenticationEmailVerificationRequiredErrorHandler(), to: &loginErrorHandlers)
        registerHandler(AuthenticationEmailLoginUnknownErrorHandler(), to: &loginErrorHandlers)
        registerHandler(AuthenticationEmailFallbackErrorHandler(), to: &loginErrorHandlers)
        registerHandler(UserEmailUpdateFailureErrorHandler(), to: &loginErrorHandlers)

        // loginCodeHandlers
        registerHandler(AuthenticationLoginCodeAvailableEventHandler(), to: &loginCodeHandlers)
        registerHandler(UserEmailUpdateCodeSentEventHandler(), to: &loginCodeHandlers)

        // registrationErrorHandlers
        registerHandler(RegistrationActivationExistingAccountPolicyHandler(), to: &registrationErrorHandlers)
        registerHandler(RegistrationActivationErrorHandler(), to: &registrationErrorHandlers)
        registerHandler(RegistrationFinalErrorHandler(), to: &registrationErrorHandlers)

        // registrationSuccessHandlers
        registerHandler(RegistrationActivationCodeSentEventHandler(), to: &registrationSuccessHandlers)
        registerHandler(RegistrationCredentialsVerifiedEventHandler(), to: &registrationSuccessHandlers)
        registerHandler(RegistrationIncrementalUserDataChangeHandler(), to: &registrationSuccessHandlers)

        // userProfileChangeObservers
        registerHandler(UserEmailChangeEventHandler(), to: &userProfileChangeObservers)

        // userInputObservers
        registerHandler(AuthenticationCodeVerificationInputHandler(), to: &userInputObservers)
        registerHandler(AuthenticationCredentialsCreationInputHandler(), to: &userInputObservers)
        registerHandler(AuthenticationIncrementalUserCreationInputHandler(), to: &userInputObservers)
        registerHandler(AuthenticationLoginCredentialsInputHandler(), to: &userInputObservers)
        registerHandler(AuthenticationButtonTapInputHandler(), to: &userInputObservers)
        registerHandler(AuthenticationAddEmailPasswordInputHandler(), to: &userInputObservers)
        registerHandler(AuthenticationReauthenticateInputHandler(), to: &userInputObservers)
    }

    /// Registers a handler inside the specified type erased array.
    fileprivate func registerHandler<Handler: AuthenticationEventHandler>(_ handler: Handler, to handlerList: inout [AnyAuthenticationEventHandler<Handler.Context>]) {
        let box = AnyAuthenticationEventHandler(handler)
        handlerList.append(box)
    }

    // MARK: - Event Handling

    /**
     * Call this method to notify the responder chain that a supported event occured.
     * - parameter eventType: The type of event that occured, and any required context.
     */

    func handleEvent(ofType eventType: EventType) {
        log.info("Event handling manager received event: \(eventType)")

        switch eventType {
        case .flowStart(let error, let numberOfAccounts):
            handleEvent(with: flowStartHandlers, context: (error, numberOfAccounts))
        case .initialSyncCompleted:
            handleEvent(with: initialSyncHandlers, context: ())
        case .backupReady(let existingAccount):
            handleEvent(with: backupEventHandlers, context: existingAccount)
        case .clientRegistrationError(let error, let accountID):
            handleEvent(with: clientRegistrationErrorHandlers, context: (error, accountID))
        case .clientRegistrationSuccess:
            handleEvent(with: clientRegistrationSuccessHandlers, context: ())
        case .authenticationFailure(let error):
            handleEvent(with: loginErrorHandlers, context: error)
        case .loginCodeAvailable:
            handleEvent(with: loginCodeHandlers, context: ())
        case .registrationError(let error):
            handleEvent(with: registrationErrorHandlers, context: error)
        case .registrationStepSuccess:
            handleEvent(with: registrationSuccessHandlers, context: ())
        case .userProfileChange(let changeInfo):
            handleEvent(with: userProfileChangeObservers, context: changeInfo)
        case .userInput(let value):
            handleEvent(with: userInputObservers, context: value)
        }
    }

    /// Start handling the event with the specified context, using the given handlers and delegate.
    private func handleEvent<Context>(with handlers: [AnyAuthenticationEventHandler<Context>], context: Context) {
        guard let delegate = self.delegate else {
            log.error("The event will not be handled because the responder chain does not have a delegate.")
            return
        }

        var lookupResult: (String, [AuthenticationCoordinatorAction])?

        for handler in handlers {
            handler.statusProvider = delegate.statusProvider

            defer {
                handler.statusProvider = nil
            }

            if let responseActions = handler.handleEvent(currentStep: delegate.stateController.currentStep,
                                                         context: context) {
                lookupResult = (handler.name, responseActions)
                break
            }
        }

        guard let (name, actions) = lookupResult else {
            log.error("No handler was found to handle the event.\nCurrentStep = \(delegate.stateController.currentStep)")
            return
        }

        log.info("Handing event using \(name), and \(actions.count) actions.")
        delegate.executeActions(actions)
    }

}
