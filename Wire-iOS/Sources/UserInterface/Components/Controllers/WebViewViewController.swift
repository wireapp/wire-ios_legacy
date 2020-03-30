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


enum WebViewError: Error {
    case authenticationFailed
    case serverError
}

class WebViewViewController: UIViewController {

    var completion: ((_ result: VoidResult?) -> Void)?
    
    private var webView: WKWebView!
    private var url: URL?
    
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
        createConstraints()
        loadURL()
    }
    
    private func setupWebView() {
        webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        updateButtonMode()

        self.view.addSubview(webView)
    }
    
    private func updateButtonMode() {
        let buttonItem = UIBarButtonItem(title: "general.done".localized, style: .done, target: self, action: #selector(WebViewViewController.onClose))
        buttonItem.accessibilityIdentifier = "DoneButton"
        buttonItem.accessibilityLabel = "general.done".localized
        navigationItem.leftBarButtonItem = buttonItem
    }
    
    private func createConstraints() {
        webView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
        webView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0).isActive = true
        webView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0).isActive = true
    }
    
    private func loadURL() {
        guard let url = url else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @objc private func onClose() {
        completion?(nil)
        self.dismiss(animated: true, completion: nil)
    }
}

extension WebViewViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if let _ = url.absoluteString.range(of: "success") {
            completion?(.success)
            decisionHandler(.cancel)
        } else if let _ = url.absoluteString.range(of: "failed") {
            completion?(.failure(WebViewError.authenticationFailed))
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
