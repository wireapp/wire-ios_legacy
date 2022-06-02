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

import Foundation
import UIKit

extension UIViewController {

    /// return true if the view controller's view is in a window, not covered by a modelled VC and the bounds is intersects with the screen's bound
    var isVisible: Bool {
        let isInWindow = view.window != nil
        let notCoveredModally = presentedViewController == nil
        let viewIsVisible = view.isVisible

        return isInWindow && notCoveredModally && viewIsVisible
    }

}

extension UIView {
    var isVisible: Bool {
        return convert(bounds, to: nil).intersects(UIScreen.main.bounds)
    }
}
