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

class DigitalSignatureVerificationViewController: UIViewController {

    typealias Result = ((_ result: VoidResult?) -> Void)
    
    // MARK: - Error states
    private enum VerificationError: Error {
        case authenticationFailed
        case internalServerError
    }
    
    // MARK: - Private Property
    private var webView = WKWebView(frame: .zero)
    private var url: URL?
    
    private let success: String = "success"
    private let failed: String = "failed"
    
    // MARK: - Public Property
    var completion: Result?
    
    // MARK: - Init
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
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
        let buttonItem = UIBarButtonItem(title: "general.done".localized, style: .done, target: self, action: #selector(DigitalSignatureVerificationViewController.onClose))
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
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard 
            let url = navigationAction.request.url,
            let response = parse(url) else {
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
    
    func parse(_ url: URL) -> VoidResult? {
        let urlComponents = URLComponents(string: url.absoluteString)
        let postCode = urlComponents?.queryItems?.first(where: { $0.name == "postCode" })
        if let _ = postCode?.value?.range(of: success) {
            return .success
        } else if let _ = postCode?.value?.range(of: failed) {
            let errorCode = urlComponents?.queryItems?.first(where: { $0.name == "errorCode" })
            guard let error = errorCode?.value else {
                return nil
            }
            return error.contains("authenticationFailed")
                ? .failure(VerificationError.authenticationFailed)
                : .failure(VerificationError.internalServerError)
        } else {
            return nil
        }
    }
}
