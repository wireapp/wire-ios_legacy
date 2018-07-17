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
    func controllerShouldPresentLoginCodeAlert(_ controller: SingleSignOnController) -> Bool
    func controller(_ controller: SingleSignOnController, presentAlert: UIAlertController)
}

@objc public final class SingleSignOnController: NSObject {

    weak var delegate: SingleSignOnControllerDelegate?

    private var token: Any?
    private let detector = SharedIdentitySessionRequestDetector.shared
    private let requester: SharedIdentitySessionRequester

    public init(requester: SharedIdentitySessionRequester) {
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
    
    @objc public func showLoginAlert() {
        guard delegate?.controllerShouldPresentLoginCodeAlert(self) ?? true else { return }
        presentLoginAlert()
    }
    
    @objc private func detectLoginCode() {
        guard delegate?.controllerShouldPresentLoginCodeAlert(self) ?? true else { return }
        detector.detectCopiedRequestCode { [presentLoginAlert] code in
            code.apply {
                presentLoginAlert($0.transportString())
            }
        }
    }
    
    private func handleDetectedLoginCode(_ uuid: UUID) {
        presentLoginAlert(prefilledCode: uuid.transportString())
    }
    
    private func presentLoginAlert(prefilledCode: String? = nil) {
        let alertController = UIAlertController.companyLogin(prefilledCode: prefilledCode) { [attemptLogin] code in
            code.apply(attemptLogin)
        }
        
        delegate?.controller(self, presentAlert: alertController)
    }
    
    private func attemptLogin(using code: String) {
        guard let uuid = detector.detectRequestCode(in: code) else { return presentParsingErrorAlert(for: code) }
        requester.requestIdentity(for: uuid) { [handleResponse] response in
            handleResponse(response)
        }
    }
    
    private func presentParsingErrorAlert(for code: String) {
        delegate?.controller(self, presentAlert: .ssoError("login.sso.error.alert.wrong_format.message".localized))
    }
    
    private func handleResponse(_ response: SharedIdentitySessionResponse) {
        switch response {
        case .success(_): break // TODO
        case .pendingAdditionalInformation(_): break // TODO
        case .error(let error): presentError(error)
        }
    }
    
    private func presentError(_ error: LocalizedError) {
        delegate?.controller(self, presentAlert: .ssoError(error.localizedDescription))
    }

}
