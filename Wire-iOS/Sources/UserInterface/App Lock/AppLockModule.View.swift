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
            presenter.processEvent(.viewDidLoad)
        }

        // MARK: - Methods

        private func setUpViews() {
            view.addSubview(lockView)
            lockView.translatesAutoresizingMaskIntoConstraints = false
            lockView.fitInSuperview()

            lockView.onReauthRequested = { [weak self] in
                self?.presenter.processEvent(.unlockButtonTapped)
            }
        }

        func refresh(with model: ViewModel) {
            lockView.showReauth = model.showReauth
            lockView.message = model.message
        }

    }

}

// MARK: - View state

extension AppLockModule {

    struct ViewModel: Equatable {

        let showReauth: Bool
        let authenticationType: AuthenticationType

        var message: String {
            var key = "self.settings.privacy_security.lock_cancelled.description_"

            switch authenticationType {
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

extension AppLockModule.ViewModel {

    static let authenticating = Self.init(
        showReauth: false,
        authenticationType: .current
    )

    static func locked(_ authenticationType: AuthenticationType = .current) -> Self {
        Self.init(
            showReauth: true,
            authenticationType: authenticationType
        )
    }

}

// MARK: - API for presenter

extension AppLockModule.View: AppLockViewPresenterInterface {}
