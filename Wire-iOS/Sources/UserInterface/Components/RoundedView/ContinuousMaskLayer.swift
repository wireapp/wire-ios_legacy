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
import WireSystem

/**
 * The dimension to use when calculating relative radii.
 */

enum MaskDimension: Int {
    case width, height
}

/**
 * The shape of a layer mask.
 */

enum MaskShape {
    case circle
    case rectangle
    case relative(multiplier: CGFloat, dimension: MaskDimension)
    case rounded(radius: CGFloat)
}

/**
 * A layer whose corners are rounded with a continuous mask (“squircle“).
 */

final class ContinuousMaskLayer: CALayer {

    override var cornerRadius: CGFloat {
        get {
            return 0
        }
        set {
            preconditionFailure("The layer is a `ContinuousMaskLayer`. The `cornerRadius` property is unavailable. Set the `shape` property.")
        }
    }

    public var shape: MaskShape = .rectangle {
        didSet {
            refreshMask()
        }
    }

    var roundedCorners: UIRectCorner = .allCorners {
        didSet {
            refreshMask()
        }
    }

    // MARK: - Initialization

    public override init(layer: Any) {
        super.init(layer: layer)

        if let otherMaskLayer = layer as? ContinuousMaskLayer {
            self.shape = otherMaskLayer.shape
            self.roundedCorners = otherMaskLayer.roundedCorners
        }
        else {
            fatal("Cannot init with \(layer)")
        }
    }

    public override init() {
        super.init()
        self.mask = CAShapeLayer()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSublayers() {
        super.layoutSublayers()
        refreshMask()
    }

    private func refreshMask() {

        guard let mask = mask as? CAShapeLayer else {
            return
        }

        let roundedPath: UIBezierPath

        switch shape {
        case .rectangle:
            roundedPath = UIBezierPath(rect: bounds)

        case .circle:
            roundedPath = UIBezierPath(ovalIn: bounds)

        case .rounded(let radius):
            roundedPath = roundedPathForBounds(radius: radius)

        case .relative(let multiplier, let dimension):

            let base: CGFloat

            switch dimension {
            case .width: base = bounds.width
            case .height: base = bounds.height
            }

            roundedPath = roundedPathForBounds(radius: base * multiplier)
        }

        mask.path = roundedPath.cgPath

    }

    private func roundedPathForBounds(radius: CGFloat) -> UIBezierPath {
        let radii = CGSize(width: radius, height: radius)
        return UIBezierPath(roundedRect: bounds, byRoundingCorners: roundedCorners, cornerRadii: radii)
    }

}
