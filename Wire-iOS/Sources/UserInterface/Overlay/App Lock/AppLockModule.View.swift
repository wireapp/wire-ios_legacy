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

        var state: ViewState = .locked {
            didSet {
                refresh()
            }
        }

        override var prefersStatusBarHidden: Bool {
            return true
        }

        private let lockView = OldAppLockView()

        // MARK: - Life cycle

        override func viewDidLoad() {
            super.viewDidLoad()
            setUpViews()
            refresh()
            presenter.start()
        }

        // MARK: - Methods

        private func setUpViews() {
            view.addSubview(lockView)
            lockView.translatesAutoresizingMaskIntoConstraints = false
            lockView.fitInSuperview()
        }

        private func refresh() {
            switch state {
            case .locked:
                lockView.showReauth = true

            case .authenticating:
                lockView.showReauth = false
            }
        }

    }

}

// MARK: - View state

extension AppLockModule {

    enum ViewState: Equatable {

        /// The screen is currently locked.

        case locked

        /// The user is authenticating.

        case authenticating

    }

}

// MARK: - API for presenter

extension AppLockModule.View: AppLockViewPresenterInterface {}
