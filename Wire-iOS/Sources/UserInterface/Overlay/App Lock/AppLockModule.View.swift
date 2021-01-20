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

        var state: ViewState = .locked(authenticationType: .passcode) {
            didSet {
                refresh()
            }
        }

        override var prefersStatusBarHidden: Bool {
            return true
        }

        let lockView = OldAppLockView()

        // MARK: - Life cycle

        override func viewDidLoad() {
            super.viewDidLoad()
            setUpViews()
            refresh()
            presenter.requestAuthentication()
        }

        // MARK: - Methods

        private func setUpViews() {
            view.addSubview(lockView)
            lockView.translatesAutoresizingMaskIntoConstraints = false
            lockView.fitInSuperview()

            lockView.onReauthRequested = presenter.requestAuthentication
        }

        private func refresh() {
            switch state {
            case let .locked(authenticationType):
                lockView.showReauth = true
                lockView.authenticateLabel.text = authenticationText(for: authenticationType)

            case .authenticating:
                lockView.showReauth = false
            }
        }

        private func authenticationText(for type: AuthenticationType) -> String {
            var key = "self.settings.privacy_security.lock_cancelled.description_"

            switch type {
            case .faceID:
                key.append("face_id")
            case .touchID:
                key.append("touch_id")
            case .passcode:
                key.append("passcode")
            case .unavailable:
                key.append("passcode_unavailable")
            }

            return key.localized
        }

    }

}

// MARK: - View state

extension AppLockModule {

    enum ViewState: Equatable {

        /// The screen is currently locked.

        case locked(authenticationType: AuthenticationType)

        /// The user is authenticating.

        case authenticating

    }

}

// MARK: - API for presenter

extension AppLockModule.View: AppLockViewPresenterInterface {}
