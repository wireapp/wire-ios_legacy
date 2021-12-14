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

/**
 * A view with rounded corners. Adopt this protocol if your view's layer is a `ContinuousMaskLayer`.
 * This protocol provides utilities to easily change the rounded corners.
 *
 * You need to override `+ (Class *)layerClass` on `UIView` before conforming to this protocol.
 */

protocol RoundedViewProtocol: AnyObject {
    var layer: CALayer { get }
}

extension RoundedViewProtocol {

    var shape: MaskShape {
        get {
            return roundedLayer.shape
        }
        set {
            roundedLayer.shape = newValue
        }
    }

    var roundedCorners: UIRectCorner {
        get {
            return roundedLayer.roundedCorners
        }
        set {
            roundedLayer.roundedCorners = newValue
        }
    }

    var roundedLayer: ContinuousMaskLayer {
        return layer as! ContinuousMaskLayer
    }

}
