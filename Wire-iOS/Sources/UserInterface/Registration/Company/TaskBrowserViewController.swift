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

import UIKit
import WebKit

/// The delegate of a task browser.
protocol TaskBrowserViewControllerDelegate: class {

    /// Browsing was cancelled by the user.
    func taskBrowserViewControllerDidCancel(_ controller: TaskBrowserViewController)
}

/**
 * A browser view controller that allows completing the task depending on the
 * response provided by the server.
 */

class TaskBrowserViewController: UIViewController, WKNavigationDelegate {

    weak var delegate: TaskBrowserViewControllerDelegate?

    private let webView = WKWebView()
    private let loadIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    private var titleObservationToken: NSKeyValueObservation?
    private var loadObservationToken: NSKeyValueObservation?

    // MARK: - Configuration

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadIndicator)

        setUpSubviews()
        setUpObservers()
    }

    private func setUpObservers() {
        webView.navigationDelegate = self

        titleObservationToken = webView.observe(\WKWebView.title) { webView, _ in
            self.title = webView.title
        }

        loadObservationToken = webView.observe(\.isLoading) { webView, _ in
            if webView.isLoading {
                self.loadIndicator.startAnimating()
            } else {
                self.loadIndicator.stopAnimating()
            }
        }
    }

    private func setUpSubviews() {
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false

        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    // MARK: - Tear Down

    @objc private func cancel() {
        self.dismiss(animated: true) {
            self.delegate?.taskBrowserViewControllerDidCancel(self)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        titleObservationToken?.invalidate()
        loadObservationToken?.invalidate()
        webView.navigationDelegate = nil
    }

    // MARK: - Web View

    /// Opens the website at the given URL.
    func open(_ url: URL) {
        let request = URLRequest(url: url)
        self.webView.load(request)
    }

}
