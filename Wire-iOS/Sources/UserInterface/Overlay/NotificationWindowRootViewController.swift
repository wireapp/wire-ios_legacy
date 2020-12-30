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

final class NotificationWindowRootViewController: UIViewController {

    override func loadView() {
        view = PassthroughTouchesView()
    }

    // MARK: - Rotation handling (should match up with root)

    private var topmostViewController: UIViewController? {
        guard let topmostViewController = UIApplication.shared.topmostViewController() else { return nil}

        if topmostViewController != self && !(topmostViewController is NotificationWindowRootViewController) {
            return topmostViewController
        }
        
        return nil
    }

    override var shouldAutorotate: Bool {
        return topmostViewController?.shouldAutorotate ?? true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topmostViewController?.supportedInterfaceOrientations ?? wr_supportedInterfaceOrientations
    }
    
    // MARK: - status bar

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
