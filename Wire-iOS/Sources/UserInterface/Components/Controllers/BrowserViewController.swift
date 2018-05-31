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

@objc class BrowserViewController: SFSafariViewController {

    // MARK: - Events

    private class BrowserDelegate: NSObject, SFSafariViewControllerDelegate {

        var completion: () -> Void

        init(completion: @escaping () -> Void) {
            self.completion = completion
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            completion()
        }

    }

    @objc var completion: (() -> Void)? {
        get {
            return (delegate as? BrowserDelegate)?.completion
        }
        set {
            guard let block = newValue else {
                delegate = nil
                return
            }
            delegate = BrowserDelegate(completion: block)
        }
    }

    // MARK: - Tint Color

    private var overrider = TintColorOverrider()
    private var originalStatusBarStyle: UIStatusBarStyle = .default

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 10, *) {
            preferredControlTintColor = .wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: .light)
        } else {
            view.tintColor = .wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: .light)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        originalStatusBarStyle = UIApplication.shared.statusBarStyle
        overrider.override()
        UIApplication.shared.wr_setStatusBarStyle(.default, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        overrider.restore()
        UIApplication.shared.wr_setStatusBarStyle(originalStatusBarStyle, animated: true)
    }

}
