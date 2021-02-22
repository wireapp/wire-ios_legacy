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

import Foundation
import UIKit

extension AppLockModule {

    final class View: UIViewController, ViewInterface {

        // MARK: - Properties

        var presenter: AppLockPresenterViewInterface!

        override var prefersStatusBarHidden: Bool {
            return true
        }

        let lockView = LockView()

        // MARK: - Life cycle

        override func viewDidLoad() {
            super.viewDidLoad()
            setUpViews()
            setUpObserver()
            presenter.processEvent(.viewDidLoad)
        }

        // MARK: - Methods

        private func setUpViews() {
            view.addSubview(lockView)
            lockView.translatesAutoresizingMaskIntoConstraints = false
            lockView.fitInSuperview()
        }

        private func setUpObserver() {
            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
        
        @objc
        func applicationWillEnterForeground() {
            presenter.processEvent(.applicationWillEnterForeground)
        }

    }

}

// MARK: - View model

extension AppLockModule {

    enum ViewModel: Equatable {

        case locked(AuthenticationType)
        case authenticating

        var showReauth: Bool {
            switch self {
            case .locked:
                return true

            case .authenticating:
                return false
            }
        }

        var message: String {
            guard case let .locked(authenticationType) = self else { return "" }

            switch authenticationType {
            case .faceID:
                return Strings.Message.faceID

            case .touchID:
                return Strings.Message.touchID

            case .passcode:
                return Strings.Message.passcode

            case .unavailable:
                return Strings.Message.passcodeUnavailable
            }
        }
        
        var buttonTitle: String {
            switch self {
            case .locked(.unavailable):
                return Strings.GoToSettingsButton.title
            default:
                return Strings.UnlockButton.title
            }
        }
        
        var buttonEvent: AppLockModule.Event {
            switch self {
            case .locked(.unavailable):
                return .openDeviceSettingsButtonTapped
            default:
                return .unlockButtonTapped
            }
        }
    }

}

// MARK: - Refresh

extension AppLockModule.View: AppLockViewPresenterInterface {

    func refresh(withModel model: AppLockModule.ViewModel) {
        lockView.showReauth = model.showReauth
        lockView.message = model.message
        lockView.buttonTitle = model.buttonTitle
        lockView.actionRequested = { [weak self] in
            self?.presenter.processEvent(model.buttonEvent)
        }
    }

}

// MARK: - Delegates

extension AppLockModule.View: PasscodeSetupViewControllerDelegate {

    func passcodeSetupControllerDidFinish() {
        presenter.processEvent(.passcodeSetupCompleted)
    }

    func passcodeSetupControllerWasDismissed() {

    }

}

extension AppLockModule.View: UnlockViewControllerDelegate {

    func unlockViewControllerDidUnlock() {
        presenter.processEvent(.customPasscodeVerified)
    }

}

extension AppLockModule.View: AppLockChangeWarningViewControllerDelegate {

    func appLockChangeWarningViewControllerDidDismiss() {
        presenter.processEvent(.configChangeAcknowledged)
    }

}
