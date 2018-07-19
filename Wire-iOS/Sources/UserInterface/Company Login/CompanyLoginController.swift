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
    
    /// The `CompanyLoginController` will never present any loading views on its own and will
    /// always ask its delegate to handle the actual presentation of loading indicators.
    func controller(_ controller: CompanyLoginController, showLoadingView: Bool)

}

///
/// `CompanyLoginController` handles the logic of deciding when to present the company login alert.
/// The controller will ask its `CompanyLoginControllerDelegate` to present alerts and never do any
/// presentation on its own.
///
/// A concrete implementation of the internally used `SharedIdentitySessionRequester` and
/// `SharedIdentitySessionRequestDetector` can be provided.
///
@objc public final class CompanyLoginController: NSObject {

    @objc weak var delegate: CompanyLoginControllerDelegate?

    @objc(autoDetectionEnabled) var isAutoDetectionEnabled = true {
        didSet {
            isAutoDetectionEnabled ? startPollingTimer() : stopPollingTimer()
        }
    }

    // Whether the presence of a code should be checked periodically on iPad.
    // This is in order to work around https://openradar.appspot.com/28771678.
    private static let isPollingEnabled = true

    private var token: Any?
    private var pollingTimer: Timer?
    private let detector: SharedIdentitySessionRequestDetector
    private let requester: SharedIdentitySessionRequester

    // MARK: - Initialization

    /// Create a new `CompanyLoginController` instance using the standard detector and requester.
    @objc public override convenience init() {
        self.init(detector: .shared, requester: TimeoutIdentitySessionRequester(delay: 2))
    }

    /// Create a new `CompanyLoginController` instance using the specified requester.
    public required init(detector: SharedIdentitySessionRequestDetector, requester: SharedIdentitySessionRequester) {
        self.detector = detector
        self.requester = requester
        super.init()
        setupObservers()
    }

    deinit {
        token.apply(NotificationCenter.default.removeObserver)
    }
    
    private func setupObservers() {
        token = NotificationCenter.default.addObserver(
            forName: .UIApplicationWillEnterForeground,
            object: nil,
            queue: .main,
            using: { [internalDetectLoginCode] _ in internalDetectLoginCode(false) }
        )
    }
    
    private func startPollingTimer() {
        guard UIDevice.current.userInterfaceIdiom == .pad, CompanyLoginController.isPollingEnabled else { return }
        pollingTimer = Timer.allVersionCompatibleScheduledTimer(
            withTimeInterval: 1,
            repeats: true,
            block: { [internalDetectLoginCode] _ in internalDetectLoginCode(true) }
        )
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
        detector.detectCopiedRequestCode { [presentLoginAlert] result in
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
            validator: SharedIdentitySessionRequestDetector.isValidRequestCode,
            completion: { [attemptLogin] code in code.apply(attemptLogin) }
        )
        
        delegate?.controller(self, presentAlert: alertController)
    }

    // MARK: - Login Handling

    /// Attempt to login using the requester specified in `init`
    /// - parameter code: the code used to attempt the SSO login.
    private func attemptLogin(using code: String) {
        guard !presentOfflineAlertIfNeeded() else { return }

        guard let uuid = SharedIdentitySessionRequestDetector.requestCode(in: code) else {
            return requireInternalFailure("Should never try to login with invalid code.")
        }

        delegate?.controller(self, showLoadingView: true)
        requester.requestIdentity(for: uuid) { [delegate, handleResponse] response in
            delegate?.controller(self, showLoadingView: false)
            handleResponse(response)
        }
    }
    
    /// Attempt to login using the requester specified in `init`
    /// - returns: `true` when the application is offline and an alert was presented, `false` otherwise.
    private func presentOfflineAlertIfNeeded() -> Bool {
        guard AppDelegate.isOffline else { return false }
        delegate?.controller(self, presentAlert: .noInternetError())
        return true
    }
    
    private func handleResponse(_ response: SharedIdentitySessionResponse) {
        switch response {
        case .success(_): preconditionFailure("unimplemented") // TODO
        case .pendingAdditionalInformation(_): preconditionFailure("unimplemented") // TODO
        case .error(let error): presentError(error)
        }
    }
    
    private func presentError(_ error: LocalizedError) {
        delegate?.controller(self, presentAlert: .companyLoginError(error.localizedDescription))
    }

}
