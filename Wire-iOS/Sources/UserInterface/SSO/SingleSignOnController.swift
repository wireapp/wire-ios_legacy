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

protocol SingleSignOnControllerDelegate: class {
    /// Whether or not the SSO login alert should be shown or not. A delegate can use this method
    /// to decide if it current context allows fot the controller to be shown.
    func controllerShouldPresentLoginCodeAlert(_ controller: SingleSignOnController) -> Bool
    
    /// The `SingleSignOnController` will never present any alerts on its own and will
    /// always ask its delegate to handle the actual presentation of the alerts.
    func controller(_ controller: SingleSignOnController, presentAlert: UIAlertController)
}

/// `SingleSignOnController` handles the logic of deciding when to present the SSO login alert.
/// The controller will ask its `SingleSignOnControllerDelegate` to present alerts and never do any
/// presentation on it's own. It will also query its delegate before presenting any SSO login alert.
/// A concrete implementation of the internally used `SharedIdentitySessionRequester` can be provided.
@objc public final class SingleSignOnController: NSObject {

    weak var delegate: SingleSignOnControllerDelegate?

    private var token: Any?
    private let detector = SharedIdentitySessionRequestDetector.shared
    private let requester: SharedIdentitySessionRequester
    
    /// Create a new `SingleSignOnController` instance using the standard requester.
    @objc public override convenience init() {
        self.init(requester: TimeoutIdentitySessionRequester(delay: 2))
    }

    /// Create a new `SingleSignOnController` instance using the specified requester.
    public required init(requester: SharedIdentitySessionRequester) {
        self.requester = requester
        super.init()
        setupObservers()
    }

    deinit {
        token.apply(NotificationCenter.default.removeObserver)
    }
    
    private func setupObservers() {
        token = NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: .main) { [detectLoginCode] _ in
            detectLoginCode()
        }
    }
    
    /// Presents the SSO login alert without any prefilled code.
    /// This method will trigger the delegate (if set) to be queried if the alert should be shown or not.
    @objc public func showLoginAlert() {
        guard delegate?.controllerShouldPresentLoginCodeAlert(self) ?? true else { return }
        presentLoginAlert()
    }
    
    /// This method will be called when the app comes back to the foreground.
    /// We then check if the clipboard contains a valid SSO login code.
    /// This method will trigger the delegate (if set) to be queried if the alert should be shown or not.
    @objc private func detectLoginCode() {
        guard delegate?.controllerShouldPresentLoginCodeAlert(self) ?? true else { return }
        detector.detectCopiedRequestCode { [presentLoginAlert] code in
            code.apply {
                presentLoginAlert($0.transportString())
            }
        }
    }
    
    /// Presents the SSO login alert without an optional prefilled code.
    /// This method will *NOT* trigger the delegate to be queried if the alert should be shown or not.
    private func presentLoginAlert(prefilledCode: String? = nil) {
        let alertController = UIAlertController.companyLogin(prefilledCode: prefilledCode) { [attemptLogin] code in
            code.apply(attemptLogin)
        }
        
        delegate?.controller(self, presentAlert: alertController)
    }
    
    /// Attempt to login using the requester specified in `init`
    /// - parameter code: the code used to attempt the SSO login.
    private func attemptLogin(using code: String) {
        guard let uuid = detector.detectRequestCode(in: code) else { return presentParsingError() }
        requester.requestIdentity(for: uuid) { [handleResponse] response in
            handleResponse(response)
        }
    }
    
    private func presentParsingError() {
        delegate?.controller(self, presentAlert: .ssoError("login.sso.error.alert.wrong_format.message".localized))
    }
    
    private func handleResponse(_ response: SharedIdentitySessionResponse) {
        switch response {
        case .success(_): preconditionFailure("unimplemented") // TODO
        case .pendingAdditionalInformation(_): preconditionFailure("unimplemented") // TODO
        case .error(let error): presentError(error)
        }
    }
    
    private func presentError(_ error: LocalizedError) {
        delegate?.controller(self, presentAlert: .ssoError(error.localizedDescription))
    }

}
