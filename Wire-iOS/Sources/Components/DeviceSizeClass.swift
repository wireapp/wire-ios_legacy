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

/// Enum for replacing IS_IPAD_FULLSCREEN, IS_IPAD_PORTRAIT_LAYOUT and IS_IPAD_LANDSCAPE_LAYOUT objc macros.
enum Device {
    enum HorizontalSizeClass {
        enum Orientation {
            case landscape
            case portrait
            case unknown
        }

        case regular(Orientation?)
        case compact
        case unknown
    }

    case iPad(HorizontalSizeClass?)
    case other
}

extension Device {
    static var currentDeviceSizeClass: Device {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            switch UIApplication.shared.keyWindow?.traitCollection.horizontalSizeClass {
            case .regular?:
                let statusBarOrientation = UIApplication.shared.statusBarOrientation
                if UIInterfaceOrientationIsLandscape(statusBarOrientation) {
                    return .iPad(.regular(.landscape))
                }
                else if UIInterfaceOrientationIsPortrait(statusBarOrientation) {
                    return .iPad(.regular(.portrait))
                }
                else {
                    return .iPad(.regular(.unknown))
                }
            default:
                return .iPad(.unknown)
            }
        default:
            return .other
        }
    }

    static var isIPadRegular: Bool {
        switch Device.currentDeviceSizeClass {
        case .iPad(.regular?):
            return true
        default:
            return false
        }
    }
}
