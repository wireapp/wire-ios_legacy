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

extension UIScreen {
    @objc var isSmall: Bool {
        return self.nativeBounds.size.height <= 1136
    }
}

/// Enum for replacing IS_IPHONE, IS_IPHONE_4, IS_IPHONE_5, IS_IPHONE_6, IS_IPHONE_6_PLUS_OR_BIGGER objc macros. Each value represents a native screen size of the device.
enum DeviceNativeBoundsSize: CGSize {

    case iPhone3_5Inch = "{640, 960}"
    case iPhone4Inch = "{640, 1136}"
    case iPhone4_7Inch = "{750, 1334}"
    case iPhone5_5Inch = "{1080, 1920}"
    case iPhone5_8Inch = "{946, 2048}"
    case iPhoneBiggerThan5_8Inch = "{99999, 99999}"
    case iPad = "{768, 1024}"
    case iPadRetina = "{1536, 2048}"
    case iPadRetina10_5Inch = "{1668, 2224}"
    case iPadRetina12_9Inch = "{2048, 2732}"
    case unknown = "{0, 0}"


    /// Return native screen bound of this device. Support up to iPhone X of 2017 and iPad Pro 12.9 Inch.
    static var nativeScreenBoundOfThisDevice: DeviceNativeBoundsSize {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            let screenHeight = UIScreen.main.nativeBounds.size.height

            switch screenHeight {
            case 768:
                return .iPad
            case 1536:
                return .iPadRetina
            case 1668:
                return .iPadRetina10_5Inch
            case 2048:
                return .iPadRetina12_9Inch
            default:
                return .unknown
            }
        case .phone:
            let screenHeight = UIScreen.main.nativeBounds.size.height

            switch screenHeight {
            case 960:
                return .iPhone3_5Inch
            case 1136:
                return .iPhone4Inch
            case 1334:
                return .iPhone4_7Inch
            case 1920:
                return .iPhone5_5Inch
            case 2436:
                return .iPhone5_8Inch
            default:
                if screenHeight > 2436 {
                    return .iPhoneBiggerThan5_8Inch
                }
                else {
                    return .unknown
                }
            }
        default:
            return .unknown
        }
    }
}

extension CGSize: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        let size = NSCoder.cgSize(for: value)
        self.init(width: size.width, height: size.height)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        let size = NSCoder.cgSize(for: value)
        self.init(width: size.width, height: size.height)
    }

    public init(unicodeScalarLiteral value: String) {
        let size = NSCoder.cgSize(for: value)
        self.init(width: size.width, height: size.height)
    }
}
