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

// MARK: - URLActionRouterDelegete
protocol URLActionRouterDelegete: class {
    func urlActionRouterWillShowCompanyLoginError()
}

// MARK: - URLActionRouterProtocol
protocol URLActionRouterProtocol {
    func openDeepLink(needsAuthentication: Bool)
    func open(url: URL) -> Bool
}

// MARK: - URLActionRouter
class URLActionRouter: URLActionRouterProtocol {

    // MARK: - Public Property
    var sessionManager: SessionManager?
    weak var delegate: URLActionRouterDelegete?

    // MARK: - Private Property
    private let rootViewController: RootViewController
    private var url: URL?

    // MARK: - Initialization
    public init(viewController: RootViewController,
                sessionManager: SessionManager? = nil,
                url: URL? = nil) {
        self.rootViewController = viewController
        self.sessionManager = sessionManager
        self.url = url
    }

    // MARK: - Public Implementation
    @discardableResult
    func open(url: URL) -> Bool {
        do {
            return try sessionManager?.openURL(url) ?? false
        } catch let error as LocalizedError {
            if error is CompanyLoginError {
                delegate?.urlActionRouterWillShowCompanyLoginError()

                UIApplication.shared.topmostViewController()?.dismissIfNeeded(animated: true, completion: {
                    UIApplication.shared.topmostViewController()?.showAlert(for: error)
                })
            } else {
                UIApplication.shared.topmostViewController()?.showAlert(for: error)
            }
            return false
        } catch {
            return false
        }
    }

    func openDeepLink(needsAuthentication: Bool = false) {
        do {
            guard let deeplink = url else { return }
            guard let action = try URLAction(url: deeplink) else { return }
            guard action.requiresAuthentication == needsAuthentication else { return }
            open(url: deeplink)
            resetDeepLinkURL()
        } catch {
            print("Cuold not open deepLink for url: \(String(describing: url?.absoluteString))")
        }
    }

    // MARK: - Private Implementation
    private func resetDeepLinkURL() {
        url = nil
    }
}

// MARK: - PresentationDelegate
extension URLActionRouter: PresentationDelegate {

    // MARK: - Public Implementation
    func failedToPerformAction(_ action: URLAction, error: Error) {
        presentLocalizedErrorAlert(error)
    }

    func completedURLAction(_ action: URLAction) {
        guard case URLAction.companyLoginSuccess = action else { return }
        notifyCompanyLoginCompletion()
    }

    func shouldPerformAction(_ action: URLAction, decisionHandler: @escaping (Bool) -> Void) {
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

    func showConnectionRequest(userId: UUID) {
        guard let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self) else {
            return
        }
        zClientViewController.showConnectionRequest(userId: userId)
    }

    func showUserProfile(user: UserType) {
        guard let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self) else {
            return
        }
        zClientViewController.showUserProfile(user: user)
    }

    func showConversation(_ conversation: ZMConversation, at message: ZMConversationMessage?) {
        guard let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self) else {
            return
        }
        zClientViewController.showConversation(conversation, at: message)
    }

    func showConversationList() {
        guard let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self) else {
            return
        }
        zClientViewController.showConversationList()
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
        sessionManager?.switchBackend(configuration: configurationURL) { [weak self] result in
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
}
