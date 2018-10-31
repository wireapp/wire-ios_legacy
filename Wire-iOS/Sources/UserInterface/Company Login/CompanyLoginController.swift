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

@objc protocol CompanyLoginControllerDelegate: class {

    /// The `CompanyLoginController` will never present any alerts on its own and will
    /// always ask its delegate to handle the actual presentation of the alerts.
    func controller(_ controller: CompanyLoginController, presentAlert: UIAlertController)

    /// Called when the company login controller asks the presenter to show the login spinner
    /// when performing a required task.
    func controller(_ controller: CompanyLoginController, showLoadingView: Bool)

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
@objc public final class CompanyLoginController: NSObject, CompanyLoginRequesterDelegate, CompanyLoginFlowHandlerDelegate {

    @objc weak var delegate: CompanyLoginControllerDelegate?

    @objc(autoDetectionEnabled) var isAutoDetectionEnabled = true {
        didSet {
            isAutoDetectionEnabled ? startPollingTimer() : stopPollingTimer()
        }
    }

    // Whether the presence of a code should be checked periodically on iPad.
    // This is in order to work around https://openradar.appspot.com/28771678.
    private static let isPollingEnabled = true
    private static let fallbackURLScheme = "wire-sso"

    // Whether performing a company login is supported on the current build.
    @objc(companyLoginEnabled) static public let isCompanyLoginEnabled = true

    private var token: Any?
    private var pollingTimer: Timer?
    private let detector: CompanyLoginRequestDetector
    private let requester: CompanyLoginRequester
    private let flowHandler: CompanyLoginFlowHandler

    // MARK: - Initialization

    /// Create a new `CompanyLoginController` instance using the standard detector and requester.
    @objc(initWithDefaultEnvironment) public convenience init?(withDefaultEnvironment: ()) {
        guard CompanyLoginController.isCompanyLoginEnabled else { return nil } // Disable on public builds
        
        let callbackScheme = wr_companyLoginURLScheme()
        requireInternal(nil != callbackScheme, "no valid callback scheme")

        let requester = CompanyLoginRequester(
            backendHost: BackendEnvironment.shared.backendURL.host!,
            callbackScheme: callbackScheme ?? CompanyLoginController.fallbackURLScheme
        )
        self.init(detector: .shared, requester: requester)
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
            using: { [internalDetectLoginCode] _ in internalDetectLoginCode(false) }
        )
    }
    
    private func startPollingTimer() {
        guard UIDevice.current.userInterfaceIdiom == .pad, CompanyLoginController.isPollingEnabled else { return }
        pollingTimer = .scheduledTimer(withTimeInterval: 1, repeats: true) {
            [internalDetectLoginCode] _ in internalDetectLoginCode(true)
        }
    }
    
    private func stopPollingTimer() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Login Prompt Presentation
    
    @objc func detectLoginCode() {
        internalDetectLoginCode(onlyNew: false)
    }

    /// This method will be called when the app comes back to the foreground.
    /// We then check if the clipboard contains a valid SSO login code.
    /// This method will check the `isAutoDetectionEnabled` flag in order to decide if it should run.
    @objc func internalDetectLoginCode(onlyNew: Bool) {
        guard isAutoDetectionEnabled else { return }
        detector.detectCopiedRequestCode { [isAutoDetectionEnabled, presentLoginAlert] result in
            // This might have changed in the meantime.
            guard isAutoDetectionEnabled else { return }

            guard let result = result, !onlyNew || result.isNew else { return }
            presentLoginAlert(result.code)
        }
    }

    /// Presents the SSO login alert. If the code is available in the clipboard, we pre-fill it.
    /// Call this method when you need to present the alert in response to user interaction.
    @objc func displayLoginCodePrompt() {
        detector.detectCopiedRequestCode { [presentLoginAlert] result in
            presentLoginAlert(result?.code)
        }
    }

    /// Presents the SSO login alert with an optional prefilled code.
    private func presentLoginAlert(prefilledCode: String?) {
        let alertController = UIAlertController.companyLogin(
            prefilledCode: prefilledCode,
            validator: CompanyLoginRequestDetector.isValidRequestCode,
            completion: { [attemptLogin] code in code.apply(attemptLogin) }
        )

        delegate?.controller(self, presentAlert: alertController)
    }

    // MARK: - Login Handling

    /// Attempt to login using the requester specified in `init`
    /// - parameter code: the code used to attempt the SSO login.
    private func attemptLogin(using code: String) {
        guard !presentOfflineAlertIfNeeded() else { return }

        guard let uuid = CompanyLoginRequestDetector.requestCode(in: code) else {
            return requireInternalFailure("Should never try to login with invalid code.")
        }

        delegate?.controller(self, showLoadingView: true)

        requester.validate(token: uuid) {
            self.delegate?.controller(self, showLoadingView: false)
            guard !self.handleValidationErrorIfNeeded($0) else { return }
            self.requester.requestIdentity(for: uuid)
        }
    }

    private func handleValidationErrorIfNeeded(_ error: ValidationError?) -> Bool {
        guard let error = error else { return false }

        switch error {
        case .invalidCode:
            delegate?.controller(self, presentAlert: .invalidCodeError())

        case .invalidStatus(let status):
            let message = "login.sso.error.alert.invalid_status.message".localized(args: String(status))
            delegate?.controller(self, presentAlert: .companyLoginError(message))

        case .unknown:
            let message = "login.sso.error.alert.unknown.message".localized
            delegate?.controller(self, presentAlert: .companyLoginError(message))
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

    // MARK: - Flow

    public func companyLoginRequester(_ requester: CompanyLoginRequester, didRequestIdentityValidationAtURL url: URL) {
        delegate?.controllerDidStartCompanyLoginFlow(self)
        flowHandler.open(authenticationURL: url)
    }

    func userDidCancelCompanyLoginFlow() {
        delegate?.controllerDidCancelCompanyLoginFlow(self)
    }

}
