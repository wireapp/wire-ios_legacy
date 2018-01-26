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

enum DeviceScreenSize {
    case iPhone3_5Inch
    case iPhone4Inch
    case iPhone4_7Inch
    case iPhone5_5Inch
    case iPhone5_8Inch
    case iPhoneBiggerThan5_8Inch
    case iPad
    case unknown

    static var screenSizeOfThisDevice: DeviceScreenSize {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return .iPad
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
