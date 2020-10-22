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

import WireSyncEngine

extension Notification.Name {
    static let companyLoginDidFinish = Notification.Name("Wire.CompanyLoginDidFinish")
}

final class URLActionRouter {
    
    // MARK: - Private Property
    private let rootViewController: RootViewController
    
    // MARK: - Initialization
    public init(viewController: RootViewController) {
        self.rootViewController = viewController
    }
}

// MARK: - Public PresentationDelegate
extension URLActionRouter: PresentationDelegate {
    
    // MARK: - Public Implementation
    public func failedToPerformAction(_ action: URLAction, error: Error) {
        presentLocalizedErrorAlert(error)
    }
    
    public func completedURLAction(_ action: URLAction) {
        if case URLAction.companyLoginSuccess = action {
            notifyCompanyLoginCompletion()
        }
    }
    
    public func shouldPerformAction(_ action: URLAction, decisionHandler: @escaping (Bool) -> Void) {
        switch action {
        case .connectBot:
            presentConnectBotAlert(with: decisionHandler)
        case .accessBackend(configurationURL: let configurationURL):
            guard SecurityFlags.customBackend.isEnabled else { return }
            presentCustomBackendAlert(with: configurationURL)
        default:
            decisionHandler(true)
        }
    }
    
    // MARK: - Private Implementation
    private func notifyCompanyLoginCompletion() {
        NotificationCenter.default.post(name: .companyLoginDidFinish, object: self)
    }
    
    private func presentConnectBotAlert(with decisionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "url_action.title".localized,
                                      message: "url_action.connect_to_bot.message".localized,
                                      preferredStyle: .alert)
        
        let agreeAction = UIAlertAction(title: "url_action.confirm".localized,
                                        style: .default) { _ in
                                            decisionHandler(true)
        }
        
        alert.addAction(agreeAction)
        
        let cancelAction = UIAlertAction(title: "general.cancel".localized,
                                         style: .cancel) { _ in
                                            decisionHandler(false)
        }
        
        alert.addAction(cancelAction)
        
        rootViewController.present(alert, animated: true, completion: nil)
    }
    
    private func presentCustomBackendAlert(with configurationURL: URL) {
        let alert = UIAlertController(title: "url_action.switch_backend.title".localized,
                                      message: "url_action.switch_backend.message".localized(args: configurationURL.absoluteString),
                                      preferredStyle: .alert)
        
        let agreeAction = UIAlertAction(title: "general.ok".localized, style: .default) { [weak self] _ in
            self?.rootViewController.isLoadingViewVisible = true
            self?.switchBackend(with: configurationURL)
        }
        alert.addAction(agreeAction)
        
        let cancelAction = UIAlertAction(title: "general.cancel".localized, style: .cancel)
        alert.addAction(cancelAction)
        
        rootViewController.present(alert, animated: true, completion: nil)
    }
    
    private func switchBackend(with configurationURL: URL) {
        SessionManager.shared?.switchBackend(configuration: configurationURL) { [weak self] result in
            self?.rootViewController.isLoadingViewVisible = false
            switch result {
            case let .success(environment):
                BackendEnvironment.shared = environment
            case let .failure(error):
                self?.presentLocalizedErrorAlert(error)
            }
        }
    }
    
    private func presentLocalizedErrorAlert(_ error: Error) {
        guard let error = error as? LocalizedError else {
            return
        }
        let alertMessage = error.failureReason ?? "error.user.unkown_error".localized
        let alertController = UIAlertController.alertWithOKButton(title: error.errorDescription,
                                                                  message: alertMessage)
        rootViewController.present(alertController, animated: true)
    }

    public func showConnectionRequest(userId: UUID) {
        guard let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self) else {
            return
        }
        zClientViewController.showConnectionRequest(userId: userId)
    }

    public func showUserProfile(user: UserType) {
        guard let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self) else {
            return
        }
        zClientViewController.showUserProfile(user: user)
    }

    public func showConversation(_ conversation: ZMConversation, at message: ZMConversationMessage?) {
        guard let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self) else {
            return
        }
        zClientViewController.showConversation(conversation, at: message)
    }
    
    public func showConversationList() {
        guard let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self) else {
            return
        }
        zClientViewController.showConversationList()
    }
}
