//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import SafariServices

class TintColorOverrider: NSObject {
    private var windowTintColor: UIColor?

    func override() {
        windowTintColor = UIApplication.shared.delegate?.window??.tintColor
        UIApplication.shared.delegate?.window??.tintColor = UIColor.from(scheme: .textForeground, variant: .light)
    }

    func restore() {
        UIApplication.shared.delegate?.window??.tintColor = windowTintColor
    }
}

/// These classes should be subclass from when setting the tint color
/// of controls doesn't have any effect, see `TintCorrectedActivityViewController` and
/// https://stackoverflow.com/questions/25795065/ios-8-uiactivityviewcontroller-and-uialertcontroller-button-text-color-uses-wind

class TintColorCorrectedViewController: UIViewController {
    private var overrider = TintColorOverrider()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        overrider.override()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        overrider.restore()
    }
}
