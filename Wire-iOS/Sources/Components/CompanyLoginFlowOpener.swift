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
import SafariServices
import AuthenticationServices
import UIKit
import WireSyncEngine

protocol CompanyLoginFlowHandlerDelegate: class {
    /// Called when the user cancels the company login flow.
    func userDidCancelCompanyLoginFlow()
}

/**
 * Handles opening URLs to validate company login authentication.
 */

final class CompanyLoginFlowHandler {

    /// The delegate of the flow handler.
    weak var delegate: CompanyLoginFlowHandlerDelegate?

    /// Whether we allow the in-app browser. Defaults to `true`.
    var enableInAppBrowser: Bool = true

    /// Whether we allow the system authentication session. Defaults to `false`.
    var enableAuthenticationSession: Bool = false

    private let callbackScheme: String
    private var currentAuthenticationSession: NSObject?
    private var token: Any?

    private var activeWebBrowser: UIViewController? {
        didSet {
            startListeningToFlowCompletion()
        }
    }

    deinit {
        token.apply(NotificationCenter.default.removeObserver)
    }

    // MARK: - Initialization

    /// Creates the flow handler with the given callback URL scheme.
    init(callbackScheme: String) {
        self.callbackScheme = callbackScheme
    }

    // MARK: - Flow

    /// Opens the company login flow at the specified start URL.
    func open(authenticationURL: URL) {
        guard enableInAppBrowser else {
            UIApplication.shared.open(authenticationURL)
            return
        }

        guard enableAuthenticationSession else {
            openSafariEmbed(at: authenticationURL)
            return
        }

        if #available(iOS 11, *) {
            openSafariAuthenticationSession(at: authenticationURL)
        } else {
            openSafariEmbed(at: authenticationURL)
        }
    }

    private func startListeningToFlowCompletion() {
        token = NotificationCenter.default.addObserver(forName: .companyLoginDidFinish, object: nil, queue: .main) { [weak self] _ in
            self?.activeWebBrowser?.dismiss(animated: true, completion: nil)
            self?.activeWebBrowser = nil
        }
    }

    // MARK: - Utilities

    @available(iOS 11, *)
    private func openSafariAuthenticationSession(at url: URL) {
        if #available(iOS 12, *) {
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { url, error in
                if let url = url {
                    self.processURL(url)
                }
                
                self.currentAuthenticationSession = nil
            }

            currentAuthenticationSession = session
            session.start()
        } else {
            let session = SFAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { url, error in
                if let url = url {
                    self.processURL(url)
                }
                
                self.currentAuthenticationSession = nil
            }

            currentAuthenticationSession = session
            session.start()
        }
    }
    
    private func processURL(_ url: URL) {
        do {
            try SessionManager.shared?.openURL(url)
        } catch let error as LocalizedError {
            UIApplication.shared.topmostViewController()?.showAlert(for: error)
        } catch {
            // nop
        }
    }

    private func openSafariEmbed(at url: URL) {
        let safariViewController = BrowserViewController(url: url)
        safariViewController.completion = {
            self.delegate?.userDidCancelCompanyLoginFlow()
        }

        activeWebBrowser = safariViewController
        UIApplication.shared.topmostViewController()?.present(safariViewController, animated: true, completion: nil)
    }

}
