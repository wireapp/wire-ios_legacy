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
import WireCommonComponents

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
                AppDelegate.shared.notificationsWindow?.isHidden = !dimContents
                AppDelegate.shared.window?.makeKey()
            }
        }
    }
    
    private weak var unlockViewController: UnlockViewController?
    private weak var unlockScreenWrapper: UIViewController?

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
    
    private func presentCustomPassCodeUnlockScreenIfNeeded(message: String,
                                                           callback: @escaping RequestPasswordController.Callback) {
        if unlockViewController == nil {
            let viewController = UnlockViewController()
            
            let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: viewController)
            let navigationController = keyboardAvoidingViewController.wrapInNavigationController(navigationBarClass: TransparentNavigationBar.self)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: false)
            
            unlockScreenWrapper = navigationController
            unlockViewController = viewController
        }
        
        guard let unlockViewController = unlockViewController else { return }
        
        if message == AuthenticationMessageKey.wrongPassword {
            unlockViewController.showWrongPasscodeMessage()
        }
        
        unlockViewController.callback = callback
    }
    
    private func presentRequestPasswordController(message: String,
                                                  callback: @escaping RequestPasswordController.Callback) {
        let passwordController = RequestPasswordController(context: .unlock(message: message.localized),
                                                           callback: callback)
        self.passwordController = passwordController
        present(passwordController.alertController, animated: true)
    }
}

// MARK: - AppLockManagerDelegate
extension AppLockViewController: AppLockUserInterface {
    func dismissUnlockScreen() {
        unlockScreenWrapper?.dismiss(animated: false)
    }
    
    func presentUnlockScreen(with message: String,
                             callback: @escaping RequestPasswordController.Callback) {
        
        if AppLock.rules.useCustomCodeInsteadOfAccountPassword {
            presentCustomPassCodeUnlockScreenIfNeeded(message: message, callback: callback)
        } else {
            presentRequestPasswordController(message: message, callback: callback)
        }
    }
    
    func presentCreatePasscodeScreen(callback: ResultHandler?) {
        present(PasscodeSetupViewController.createKeyboardAvoidingFullScreenView(callback: callback, variant: .dark),
                animated: false)
    }

    func setSpinner(animating: Bool) {
        if animating {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    func setReauth(visible: Bool) {
        lockView.showReauth = visible
    }

    func setContents(dimmed: Bool) {
        dimContents = dimmed
    }
}
