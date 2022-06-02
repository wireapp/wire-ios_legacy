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

import UIKit
import Foundation
import WebKit
import WireUtilities

// MARK: - Error states
public enum DigitalSignatureVerificationError: Error {
    case postCodeRetry
    case authenticationFailed
    case otherError
}

class DigitalSignatureVerificationViewController: UIViewController {

    typealias DigitalSignatureCompletion = ((_ result: VoidResult) -> Void)

    // MARK: - Private Property
    private var completion: DigitalSignatureCompletion?

    private var webView = WKWebView(frame: .zero)
    private var url: URL?

    // MARK: - Init
    init(url: URL, completion: DigitalSignatureCompletion? = nil) {
        self.url = url
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadURL()
    }

    // MARK: - Private Method
    private func setupWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        updateButtonMode()

        view.addSubview(webView)
        webView.fitInSuperview()
    }

    private func updateButtonMode() {
        let buttonItem = UIBarButtonItem(title: "general.done".localized,
                                         style: .done,
                                         target: self,
                                         action: #selector(onClose))
        buttonItem.accessibilityIdentifier = "DoneButton"
        buttonItem.accessibilityLabel = "general.done".localized
        buttonItem.tintColor = UIColor.black
        navigationItem.leftBarButtonItem = buttonItem
    }

    private func loadURL() {
        guard let url = url else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    @objc private func onClose() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - WKNavigationDelegate
extension DigitalSignatureVerificationViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard
            let url = navigationAction.request.url,
            let response = parseVerificationURL(url)
        else {
            decisionHandler(.allow)
            return
        }

        switch response {
        case .success:
            completion?(.success)
            decisionHandler(.cancel)
        case .failure(let error):
            completion?(.failure(error))
            decisionHandler(.cancel)
        }
    }

    func parseVerificationURL(_ url: URL) -> VoidResult? {
        let urlComponents = URLComponents(string: url.absoluteString)
        let postCode = urlComponents?.queryItems?
            .first(where: { $0.name == "postCode" })
        guard let  postCodeValue = postCode?.value else {
            return nil
        }
        switch postCodeValue {
        case "sas-success":
            return .success
        case "sas-error-authentication-failed":
             return .failure(DigitalSignatureVerificationError.authenticationFailed)
        default:
            return .failure(DigitalSignatureVerificationError.otherError)
        }
    }
}
