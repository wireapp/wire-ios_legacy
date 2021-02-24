//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ScreenCurtain {

    final class RootViewController: UIViewController {

        // MARK: - Properties

        override var prefersStatusBarHidden: Bool {
            return true
        }

        override var shouldAutorotate: Bool {
            return topmostViewController?.shouldAutorotate ?? true
        }

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return topmostViewController?.supportedInterfaceOrientations ?? wr_supportedInterfaceOrientations
        }

        private var topmostViewController: UIViewController? {
            guard
                let topmostViewController = UIApplication.shared.topmostViewController(),
                !(topmostViewController is Self)
            else {
                return nil
            }

            return topmostViewController
        }

        // MARK: - Life cycle

        override func viewDidLoad() {
            super.viewDidLoad()
            setUpView()
        }

        // MARK: - Set up

        private func setUpView() {
            let shieldView = UIView.shieldView()
            view.addSubview(shieldView)

            shieldView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                shieldView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                shieldView.topAnchor.constraint(equalTo: view.topAnchor),
                shieldView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                shieldView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

    }

}

