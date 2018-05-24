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

final class ThumbnailCornerPinningBehavior: UIDynamicBehavior {

    enum Corner: Int {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    // MARK: - Properties

    fileprivate let item: UIDynamicItem
    fileprivate let edgeInsets: CGPoint

    fileprivate let collisionBehavior: UICollisionBehavior
    fileprivate let itemTransformBehavior: UIDynamicItemBehavior
    fileprivate var fieldBehaviors: [UIFieldBehavior] = []

    // MARK: - Initialization

    init(item: UIDynamicItem, edgeInsets: CGPoint) {

        self.item = item
        self.edgeInsets = edgeInsets

        // Detect collisions

        self.collisionBehavior = UICollisionBehavior(items: [item])
        self.collisionBehavior.translatesReferenceBoundsIntoBoundary = true

        // Alter the properties of the item

        self.itemTransformBehavior = UIDynamicItemBehavior(items: [item])
        self.itemTransformBehavior.density = 0.01
        self.itemTransformBehavior.resistance = 7
        self.itemTransformBehavior.friction = 0.1
        self.itemTransformBehavior.allowsRotation = false
        super.init()

        // Add child behaviors

        addChildBehavior(collisionBehavior)
        addChildBehavior(itemTransformBehavior)

        // Add a spring field on each of the 4 corners of the screen
        // to confine the items in their zone once they reach them

        for _ in 0 ..< 4 {
            let fieldBehavior = UIFieldBehavior.springField()
            fieldBehavior.addItem(item)

            fieldBehaviors.append(fieldBehavior)
            addChildBehavior(fieldBehavior)

        }

    }

    // MARK: - Behavior

    var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                for fieldBehavior in fieldBehaviors {
                    fieldBehavior.addItem(item)
                }
                collisionBehavior.addItem(item)
                itemTransformBehavior.addItem(item)
            } else {
                for fieldBehavior in fieldBehaviors {
                    fieldBehavior.removeItem(item)
                }
                collisionBehavior.removeItem(item)
                itemTransformBehavior.removeItem(item)
            }
        }
    }

    var currentCorner: Corner? {
        guard dynamicAnimator != nil else { return nil }

        let position = item.center
        for (i, fieldBehavior) in fieldBehaviors.enumerated() {
            let fieldPosition = fieldBehavior.position
            let location = CGPoint(x: position.x - fieldPosition.x, y: position.y - fieldPosition.y)

            if fieldBehavior.region.contains(location) {
                // Force unwrap the result because we know we have an actual corner at this point.
                let corner = Corner(rawValue: i)!

                return corner
            }
        }

        return nil
    }

    override func willMove(to dynamicAnimator: UIDynamicAnimator?) {
        super.willMove(to: dynamicAnimator)

        guard let bounds = dynamicAnimator?.referenceView?.bounds else {
            return
        }

        updateFields(in: bounds)
    }

    func updateFields(in bounds: CGRect) {

        guard (bounds != .zero) && (bounds != .null) else {
            return
        }

        let itemBounds = item.bounds

        // Calculate spacing

        let horizontalPosition = edgeInsets.x + (itemBounds.width / 2)
        let verticalPosition = edgeInsets.y + (itemBounds.height / 2)

        let maxX = bounds.maxX
        let maxY = bounds.maxY

        // Calculate corners

        let topLeft = CGPoint(x: horizontalPosition, y: verticalPosition)
        let topRight = CGPoint(x: maxX - horizontalPosition, y: verticalPosition)
        let bottomLeft = CGPoint(x: horizontalPosition, y: maxY - verticalPosition)
        let bottomRight = CGPoint(x: maxX - horizontalPosition, y: maxY - verticalPosition)

        // Update regions for the new bounds

        func updateFieldRegion(at corner: Corner, point: CGPoint) {
            let field = fieldBehaviors[corner.rawValue]
            field.position = point
            field.region = UIRegion(size: CGSize(width: maxX - (horizontalPosition * 2),
                                                 height: maxY - (verticalPosition * 2)))
        }

        updateFieldRegion(at: .topLeft, point: topLeft)
        updateFieldRegion(at: .topRight, point: topRight)
        updateFieldRegion(at: .bottomLeft, point: bottomLeft)
        updateFieldRegion(at: .bottomRight, point: bottomRight)

    }

    // MARK: - Utilities

    func addLinearVelocity(_ velocity: CGPoint) {
        itemTransformBehavior.addLinearVelocity(velocity, for: item)
    }

    func position(for corner: Corner) -> CGPoint {
        return fieldBehaviors[corner.rawValue].position
    }

    func positionForCurrentCorner() -> CGPoint? {
        return currentCorner.flatMap(position)
    }

}
