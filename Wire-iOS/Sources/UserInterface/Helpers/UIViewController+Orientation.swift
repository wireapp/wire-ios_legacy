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

import Foundation

extension UIViewController {
    var wr_supportedInterfaceOrientations: UIInterfaceOrientationMask {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:

            switch (self.traitCollection.horizontalSizeClass) {
            case .compact:
                return .portrait
            case .regular:
                return .all
            default:
                /// Notice: for iPad with iOS9 in landscape mode, horizontalSizeClass is .unspecified (it is .regular in iOS11).
                return .all
            }
        case .phone:
            return .portrait
        default:
            return .portrait
        }
    }
}

