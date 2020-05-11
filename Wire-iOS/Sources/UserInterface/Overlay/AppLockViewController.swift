//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import Cartography
import WireSyncEngine
import UIKit

private let zmLog = ZMSLog(tag: "UI")

final class AppLockViewController: UIViewController {
    private var lockView: AppLockView!
    private let spinner = UIActivityIndicatorView(style: .white)

    // need to hold a reference onto `passwordController`,
    // otherwise it will be deallocated and `passwordController.alertController` reference will be lost
    private var passwordController: RequestPasswordController?
    private var appLockPresenter: AppLockPresenter?

    private var dimContents: Bool = false {
        didSet {
            view.window?.isHidden = !dimContents

            if dimContents {
                AppDelegate.shared.notificationsWindow?.makeKey()
            } else {
                AppDelegate.shared.window?.makeKey()
            }
        }
    }

    static let shared = AppLockViewController()

    static var isLocked: Bool {
        return shared.dimContents
    }

    convenience init() {
        self.init(nibName:nil, bundle:nil)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.appLockPresenter = AppLockPresenter(userInterface: self)

        lockView = AppLockView()
        self.lockView.onReauthRequested = { [weak self] in
            guard let `self` = self else { return }
            self.appLockPresenter?.requireAuthentication()
        }

        self.spinner.hidesWhenStopped = true
        self.spinner.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(self.lockView)
        self.view.addSubview(self.spinner)

        constrain(self.view, self.lockView) { view, lockView in
            lockView.edges == view.edges
        }
        constrain(self.view, self.spinner) { view, spinner in
            spinner.center == view.center
        }

        self.dimContents = false
    }
}

// MARK: - AppLockManagerDelegate
extension AppLockViewController: AppLockUserInterface {
    func presentRequestPasswordController(with message: String, callback: @escaping RequestPasswordController.Callback) {
        let passwordController = RequestPasswordController(context: .unlock(message: message.localized), callback: callback)
        self.passwordController = passwordController
        self.present(passwordController.alertController, animated: true, completion: nil)
    }

    func setSpinner(animating: Bool) {
        if animating {
            self.spinner.startAnimating()
        } else {
            self.spinner.stopAnimating()
        }
    }

    func setReauth(visible: Bool) {
        self.lockView.showReauth = visible
    }

    func setContents(dimmed: Bool) {
        self.dimContents = dimmed
    }
}
