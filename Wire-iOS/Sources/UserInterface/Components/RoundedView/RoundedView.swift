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

class RoundedView: UIView, RoundedViewProtocol {

    final override class var layerClass: AnyClass {
        return ContinuousMaskLayer.self
    }

    func toggleCircle() {
        shape = .circle
    }

    func toggleRectangle() {
        shape = .rectangle
    }

    func setRelativeCornerRadius(multiplier: CGFloat, dimension: MaskDimension) {
        shape = .relative(multiplier: multiplier, dimension: dimension)
    }

    func setCornerRadius(_ cornerRadius: CGFloat) {
        shape = .rounded(radius: cornerRadius)
    }

    func setRoundedCorners(_ corners: UIRectCorner) {
        roundedCorners = corners
    }

}
