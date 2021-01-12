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

final class OldAppLockViewController: UIViewController {

    // MARK: - Properties

    private let session: AppLockInteractorUserSession

    private var lockView: OldAppLockView!
    private let spinner = UIActivityIndicatorView(style: .white)

    // need to hold a reference onto `passwordController`,
    // otherwise it will be deallocated and `passwordController.alertController` reference will be lost
    private var passwordController: RequestPasswordController?
    private var appLockPresenter: OldAppLockPresenter?

    private weak var unlockViewController: UnlockViewController?
    private weak var unlockScreenWrapper: UIViewController?

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Life cycle

    init(session: AppLockInteractorUserSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        appLockPresenter = OldAppLockPresenter(userInterface: self, session: session)
        lockView = OldAppLockView()

        lockView.onReauthRequested = { [weak self] in
            guard let `self` = self else { return }
            self.appLockPresenter?.requireAuthentication()
        }

        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(self.lockView)
        view.addSubview(self.spinner)

        constrain(view, lockView) { view, lockView in
            lockView.edges == view.edges
        }

        constrain(view, spinner) { view, spinner in
            spinner.center == view.center
        }

        appLockPresenter?.requireAuthenticationIfNeeded()
    }

    // MARK: - Methods
    
    private func presentUnlockScreenIfNeeded(message: String, callback: @escaping RequestPasswordController.Callback) {
        if unlockViewController == nil {
            // TODO: [John] Avoid static methods.
            let viewController = UnlockViewController(selfUser: ZMUser.selfUser(), userSession: ZMUserSession.shared())
            
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
    
    private func presentRequestPasswordController(message: String, callback: @escaping RequestPasswordController.Callback) {
        let passwordController = RequestPasswordController(context: .unlock(message: message.localized), callback: callback)
        self.passwordController = passwordController
        present(passwordController.alertController, animated: true)
    }
}

// MARK: - AppLockManagerDelegate

extension OldAppLockViewController: AppLockUserInterface {
    func dismissUnlockScreen() {
        unlockScreenWrapper?.dismiss(animated: false)
    }
    
    func presentUnlockScreen(with message: String, callback: @escaping RequestPasswordController.Callback) {
        presentUnlockScreenIfNeeded(message: message, callback: callback)
    }
    
    func presentCreatePasscodeScreen(callback: ResultHandler?) {
        let viewController = PasscodeSetupViewController.createKeyboardAvoidingFullScreenView(variant: .dark,
                                                                                              context: .forcedForTeam,
                                                                                              callback: callback)
        present(viewController, animated: false)
    }
    
    func presentWarningScreen(callback: ResultHandler?) {
        let warningVC = AppLockChangeWarningViewController(callback: callback)
        warningVC.modalPresentationStyle = .fullScreen
        present(warningVC, animated: false)
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

}
