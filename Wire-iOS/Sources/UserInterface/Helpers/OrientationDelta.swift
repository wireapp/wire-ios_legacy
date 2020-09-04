//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

/// Represents the orientation delta between the interface orientation (as a reference) and the device orientation
enum OrientationDelta {
    case rotatedRight
    case rotatedLeft
    case upsideDown
    case equal
    case unknown
    
    init(interfaceOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation,
         deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation) {
        let angle = deviceOrientation.rotationAngle + interfaceOrientation.rotationAngle
        self.init(angle: angle)
    }
    
    init(angle: CGFloat) {
        switch angle {
        case OrientationAngle.straight.radians:
            self = .upsideDown
        case OrientationAngle.right.radians:
            self = .rotatedLeft
        case -OrientationAngle.right.radians:
            self = .rotatedRight
        case OrientationAngle.none.radians:
            self = .equal
        default:
            self = .unknown
        }
    }
    
    var radians: CGFloat {
        switch self {
        case .upsideDown:
            return OrientationAngle.straight.radians
        case .rotatedLeft:
            return OrientationAngle.right.radians
        case .rotatedRight:
            return -OrientationAngle.right.radians
        default:
            return OrientationAngle.none.radians
        }
    }
    
    var edgeInsetsShiftAmount: Int {
        switch self {
        case .rotatedLeft:
            return 1
        case .rotatedRight:
            return -1
        case .upsideDown:
            return 2
        default:
            return 0
        }
    }
}

enum OrientationAngle {
    case none // 0°
    case right // 90°
    case straight // 180°
    case full // 360°
    
    var radians: CGFloat {
        switch self {
        case .none:
            return 0
        case .right:
            return .pi / 2
        case .straight:
            return .pi
        case .full:
            return .pi * 2
        }
    }
}

private extension UIDeviceOrientation {
    var rotationAngle: CGFloat {
        switch self {
        case .landscapeLeft:
            return OrientationAngle.right.radians
        case .landscapeRight:
            return -OrientationAngle.right.radians
        case .portraitUpsideDown:
            return OrientationAngle.straight.radians
        default:
            return OrientationAngle.none.radians
        }
    }
    
}

private extension UIInterfaceOrientation {
    var rotationAngle: CGFloat {
        switch self {
        case .landscapeLeft:
            return OrientationAngle.right.radians
        case .landscapeRight:
            return -OrientationAngle.right.radians
        case .portraitUpsideDown:
            return OrientationAngle.straight.radians
        default:
            return OrientationAngle.none.radians
        }
    }
}
