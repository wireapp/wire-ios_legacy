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
import WireCommonComponents
import UIKit
import WireTransport
import WireSyncEngine

protocol CompanyLoginControllerDelegate: class {

    /// The `CompanyLoginController` will never present any alerts on its own and will
    /// always ask its delegate to handle the actual presentation of the alerts.
    func controller(_ controller: CompanyLoginController, presentAlert: UIAlertController)

    /// Called when the company login controller asks the presenter to show the login spinner
    /// when performing a required task.
    func controller(_ controller: CompanyLoginController, showLoadingView: Bool)

    /// Called when the company login controller is ready to switch backend
    func controllerDidStartBackendSwitch(_ controller: CompanyLoginController, toURL url: URL)

    /// Called when the company login controller starts the company login flow.
    func controllerDidStartCompanyLoginFlow(_ controller: CompanyLoginController)

    /// Called when the company login controller cancels the company login flow.
    func controllerDidCancelCompanyLoginFlow(_ controller: CompanyLoginController)
}

///
/// `CompanyLoginController` handles the logic of deciding when to present the company login alert.
/// The controller will ask its `CompanyLoginControllerDelegate` to present alerts and never do any
/// presentation on its own.
///
/// A concrete implementation of the internally used `SharedIdentitySessionRequester` and
/// `SharedIdentitySessionRequestDetector` can be provided.
///
final class CompanyLoginController: NSObject, CompanyLoginRequesterDelegate {

    weak var delegate: CompanyLoginControllerDelegate?

    var isAutoDetectionEnabled = true {
        didSet {
            isAutoDetectionEnabled ? startPollingTimer() : stopPollingTimer()
        }
    }

    // Whether the presence of a code should be checked periodically on iPad.
    // This is in order to work around https://openradar.appspot.com/28771678.
    private static let isPollingEnabled = true
    private static let fallbackURLScheme = "wire-sso"

    // Whether performing a company login is supported on the current build.
    static public let isCompanyLoginEnabled = true

    private var token: Any?
    private var pollingTimer: Timer?
    private let detector: CompanyLoginRequestDetector
    private let requester: CompanyLoginRequester
    private let flowHandler: CompanyLoginFlowHandler

    private weak var ssoAlert: UIAlertController?

    // MARK: - Initialization

    /// Create a new `CompanyLoginController` instance using the standard detector and requester.
    convenience init?(withDefaultEnvironment: ()) {
        guard CompanyLoginController.isCompanyLoginEnabled,
            let callbackScheme = Bundle.ssoURLScheme else { return nil } // Disable on public builds

        requireInternal(nil != Bundle.ssoURLScheme, "no valid callback scheme")

        let requester = CompanyLoginController.createRequester(with: callbackScheme)
        self.init(detector: .shared, requester: requester)
    }

    static private func createRequester(with scheme: String?) -> CompanyLoginRequester {
        return CompanyLoginRequester(
            callbackScheme: scheme ?? CompanyLoginController.fallbackURLScheme
        )
    }

    /// Create a new `CompanyLoginController` instance using the specified requester.
    public required init(detector: CompanyLoginRequestDetector, requester: CompanyLoginRequester) {
        self.detector = detector
        self.requester = requester
        self.flowHandler = CompanyLoginFlowHandler(callbackScheme: requester.callbackScheme)
        super.init()
        setupObservers()
        flowHandler.enableInAppBrowser = true
        flowHandler.delegate = self
    }

    deinit {
        token.apply(NotificationCenter.default.removeObserver)
    }

    private func setupObservers() {
        requester.delegate = self

        token = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main,
            using: { [internalDetectSSOCode] _ in internalDetectSSOCode(false) }
        )
    }

    private func startPollingTimer() {
        guard UIDevice.current.userInterfaceIdiom == .pad, CompanyLoginController.isPollingEnabled else { return }
        pollingTimer = .scheduledTimer(withTimeInterval: 1, repeats: true) { [internalDetectSSOCode] _ in
            internalDetectSSOCode(true)
        }
    }

    private func stopPollingTimer() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

}

// MARK: - Company Login
extension CompanyLoginController {
    // MARK: - Login Prompt Presentation

    /// Presents the SSO login alert. If the code is available in the clipboard, we pre-fill it.
    /// Call this method when you need to present the alert in response to user interaction.
    func displayCompanyLoginPrompt(ssoOnly: Bool = false) {
        detector.detectCopiedRequestCode { [presentCompanyLoginAlert] result in
            presentCompanyLoginAlert(result?.code, nil, ssoOnly)
        }
    }

    /// Presents the email/SSO login alert
    /// - parameter prefilledInput: fills the alert input field (optional)
    /// - parameter error: displays error in the alert (optional)
    /// - parameter ssoOnly: determines the copy and inputHandler of the alert. default: false
    private func presentCompanyLoginAlert(
        prefilledInput: String? = nil,
        error: UIAlertController.CompanyLoginError? = nil,
        ssoOnly: Bool = false) {

        // Do not repeatly show alert if exist
        guard ssoAlert == nil else { return }

        let inputHandler = ssoOnly ? attemptLogin : parseAndHandle

        let alertController = UIAlertController.companyLogin(
            prefilledInput: prefilledInput,
            ssoOnly: ssoOnly,
            error: error,
            completion: { [weak self] input in
                self?.ssoAlert = nil
                input.apply(inputHandler)
            }
        )

        ssoAlert = alertController
        delegate?.controller(self, presentAlert: alertController)
    }

    // MARK: - Input Handling

    /// Parses the input and starts the corresponding flow
    ///
    /// - Parameter input: the input the user entered in the dialog
    private func parseAndHandle(input: String) {
        let parsingResult = CompanyLoginRequestDetector.parse(input: input)

        switch parsingResult {
        case .ssoCode(let uuid):
            attemptLoginWithSSOCode(uuid)
        case .domain(let domain):
            lookup(domain: domain)
        case .unknown:
            presentCompanyLoginAlert(prefilledInput: input, error: .invalidFormat)
        }
    }

    /// Attempt to login using the requester specified in `init`
    ///
    /// - Parameter ssoCode: the code used to attempt the SSO login.
    private func attemptLogin(using ssoCode: String) {
        guard let uuid = CompanyLoginRequestDetector.requestCode(in: ssoCode) else {
            presentCompanyLoginAlert(prefilledInput: ssoCode, error: .invalidFormat, ssoOnly: true)
            return
        }
        attemptLoginWithSSOCode(uuid)
    }

    /// Attemts to login with a SSO login code.
    ///
    /// - Parameter code: The SSO team code that was extracted from the link.
    func attemptLoginWithSSOCode(_ code: UUID) {
        guard !presentOfflineAlertIfNeeded() else { return }

        delegate?.controller(self, showLoadingView: true)

        let host = BackendEnvironment.shared.backendURL.host!
        requester.validate(host: host, token: code) {
            self.delegate?.controller(self, showLoadingView: false)
            guard !self.handleValidationErrorIfNeeded($0) else { return }
            self.requester.requestIdentity(host: host, token: code)
        }
    }

    // MARK: - Error Handling

    private func handleValidationErrorIfNeeded(_ error: ValidationError?) -> Bool {
        guard let error = error else { return false }

        switch error {
        case .invalidCode:
            presentCompanyLoginAlert(error: .invalidCode, ssoOnly: true)

        case .invalidStatus(let status):
            presentCompanyLoginAlert(error: .invalidStatus(status), ssoOnly: true)

        case .unknown:
            presentCompanyLoginAlert(error: .unknown, ssoOnly: true)
        }

        return true
    }

    /// Attempt to login using the requester specified in `init`
    /// - returns: `true` when the application is offline and an alert was presented, `false` otherwise.
    private func presentOfflineAlertIfNeeded() -> Bool {
        guard AppDelegate.isOffline else { return false }
        delegate?.controller(self, presentAlert: .noInternetError())
        return true
    }
}

// MARK: - Automatic SSO flow
extension CompanyLoginController {

    /// Fetches SSO code and starts flow automatically if code is returned on completion
    /// - Parameter promptOnError: Prompt the user for SSO code if there is an error fetching code
    func startAutomaticSSOFlow(promptOnError: Bool = true) {
        delegate?.controller(self, showLoadingView: true)
        SessionManager.shared?.activeUnauthenticatedSession.fetchSSOSettings { [weak self] result in
            guard let `self` = self else { return }
            self.delegate?.controller(self, showLoadingView: false)
            guard let ssoCode = result.value?.ssoCode else {
                guard promptOnError else { return }
                return self.displayCompanyLoginPrompt(ssoOnly: true)
            }
            self.attemptLoginWithSSOCode(ssoCode)
        }
    }
}

// MARK: - Custom Backend Switch
extension CompanyLoginController {
    /// Looks up if the specified domain is registered as custom backend
    ///
    /// - Parameter domain: domain to look up
    private func lookup(domain: String) {
        delegate?.controller(self, showLoadingView: true)
        SessionManager.shared?.activeUnauthenticatedSession.lookup(domain: domain) { [weak self] result in
            guard let `self` = self else { return }
            self.delegate?.controller(self, showLoadingView: false)
            guard let domainInfo = result.value else {
                return self.presentCompanyLoginAlert(error: .domainNotRegistered)
            }
            self.delegate?.controllerDidStartBackendSwitch(self, toURL: domainInfo.configurationURL)
        }
    }


    /// Updates backend environment to the specified url
    ///
    /// - Parameter url: backend url to switch to
    func updateBackendEnvironment(with url: URL) {
        delegate?.controller(self, showLoadingView: true)
        SessionManager.shared?.switchBackend(configuration: url) { [weak self] result in
            guard let `self` = self else { return }
            self.delegate?.controller(self, showLoadingView: false)
            guard let backendEnvironment = result.value else {
                if case SessionManager.SwitchBackendError.loggedInAccounts? = result.error {
                    self.presentCompanyLoginAlert(error: .domainAssociatedWithWrongServer)
                } else {
                    self.presentCompanyLoginAlert(error: .domainNotRegistered)
                }
                return
            }
            BackendEnvironment.shared = backendEnvironment
            self.startAutomaticSSOFlow(promptOnError: false)
        }
    }
}

// MARK: - SSO code detection
extension CompanyLoginController {

    func detectSSOCode() {
        internalDetectSSOCode(onlyNew: false)
    }

    /// This method will be called when the app comes back to the foreground.
    /// We then check if the clipboard contains a valid SSO login code.
    /// This method will check the `isAutoDetectionEnabled` flag in order to decide if it should run.
    private func internalDetectSSOCode(onlyNew: Bool) {
        guard isAutoDetectionEnabled else { return }
        detector.detectCopiedRequestCode { [isAutoDetectionEnabled, presentCompanyLoginAlert] result in
            // This might have changed in the meantime.
            guard isAutoDetectionEnabled else { return }
            guard let result = result, !onlyNew || result.isNew else { return }
            presentCompanyLoginAlert(result.code, nil, true)
        }
    }
}

// MARK: - Flow
extension CompanyLoginController: CompanyLoginFlowHandlerDelegate {
    public func companyLoginRequester(_ requester: CompanyLoginRequester, didRequestIdentityValidationAtURL url: URL) {
        delegate?.controllerDidStartCompanyLoginFlow(self)
        flowHandler.open(authenticationURL: url)
    }

    func userDidCancelCompanyLoginFlow() {
        delegate?.controllerDidCancelCompanyLoginFlow(self)
    }

}
