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

extension UIViewController {

    var safeBottomAnchor: NSLayoutYAxisAnchor {
        return self.view.safeAreaLayoutGuide.bottomAnchor
    }

    var safeTopAnchor: NSLayoutYAxisAnchor {
        return self.view.safeAreaLayoutGuide.topAnchor
    }

    var safeCenterYAnchor: NSLayoutYAxisAnchor {
        return view.safeAreaLayoutGuide.centerYAnchor
    }

}

extension UIView {
    var safeAreaLayoutGuideOrFallback: UILayoutGuide {
        return safeAreaLayoutGuide
    }

    var safeAreaInsetsOrFallback: UIEdgeInsets {
        return safeAreaInsets
    }

    var safeLeadingAnchor: NSLayoutXAxisAnchor {
        return safeAreaLayoutGuide.leadingAnchor
    }

    var safeTrailingAnchor: NSLayoutXAxisAnchor {
        return safeAreaLayoutGuide.trailingAnchor
    }

    var safeBottomAnchor: NSLayoutYAxisAnchor {
        return safeAreaLayoutGuide.bottomAnchor
    }

    var safeTopAnchor: NSLayoutYAxisAnchor {
        return safeAreaLayoutGuide.topAnchor
    }

    var safeCenterYAnchor: NSLayoutYAxisAnchor {
        return safeAreaLayoutGuide.centerYAnchor
    }

    var safeCenterXAnchor: NSLayoutXAxisAnchor {
        return safeAreaLayoutGuide.centerXAnchor
    }

}
