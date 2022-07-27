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

import UIKit

extension UIScreen {

    static var safeArea: UIEdgeInsets {
        if hasNotch {
            return UIApplication.shared.firstKeyWindow!.safeAreaInsets
        }
        return UIEdgeInsets(top: 20.0, left: 0.0, bottom: 0.0, right: 0.0)
    }

    static var hasBottomInset: Bool {
        guard let window = UIApplication.shared.firstKeyWindow else { return false }
        let insets = window.safeAreaInsets

        return insets.bottom > 0
    }

    static var hasNotch: Bool {
        // On iOS12 insets.top == 20 on device without notch.
        // insets.top == 44 on device with notch.
        guard let window = UIApplication.shared.firstKeyWindow else { return false }
        let insets = window.safeAreaInsets

        return insets.top > 20 || insets.bottom > 0
    }

    var isCompact: Bool {
        return bounds.size.height <= 568
    }
}
