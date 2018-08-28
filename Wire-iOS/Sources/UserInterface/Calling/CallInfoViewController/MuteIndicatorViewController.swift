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
import Cartography

final class MuteIndicatorViewController: UIViewController {

    let dssa

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createConstraints()
    }

    private func createConstraints() {
        constrain(view) { view in

        }
    }

}

// MARK: - iPad size class switching

//extension MuteIndicatorViewController {
//
//    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//
//        ///TODO: change the UI config, constraints, font size and etc here if this VC has different UI design pattern on iPad compact/regular mode
//
//    }
//
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//
//        ///TODO: change the UI config, constraints, font size and etc here if this VC has different UI design pattern on iPad landscape/portrait
//
//    }
//
//}

// MARK: - Status Bar / Supported Orientations

extension MuteIndicatorViewController {

    override var shouldAutorotate: Bool {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:

        switch (self.traitCollection.horizontalSizeClass) {
        case .compact:
            ///TODO: if this should auto rotate, return true
            return false
        default:
            return true
        }
        default:
            ///TODO: if this should auto rotate, return true
            return false
        }
    }

//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return UIViewController.wr_supportedInterfaceOrientations()
//    }

//    override var prefersStatusBarHidden: Bool {
//        ///TODO: if this VC does not show status bar, return false
//        return true
//    }
}
