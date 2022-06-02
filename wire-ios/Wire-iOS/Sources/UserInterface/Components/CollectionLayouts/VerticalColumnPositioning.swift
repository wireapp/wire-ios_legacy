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
 * The positioning of the rows inside the collection container.
 *
 * The positioning is updated incrementally. Call `insertItem(ofSize:at:)` to
 * add the attributes for the new items, in the order of the collection.
 */

struct VerticalColumnPositioning {

    /// The height of the content displayed in the container.
    private(set) var contentHeight: CGFloat

    /// The attributes for the rows, in the order of their index path.
    private(set) var rows: [UICollectionViewLayoutAttributes]

    private var currentColumn: Int
    private var columnHeights: [CGFloat]
    private let context: VerticalColumnPositioningContext

    // MARK: - Calculating the position

    /**
     * Creates the positioning for an empty collection, displayed in the given context.
     *
     * - parameter context: The context where the items will be displayed. This will be used
     * to calculate the attributes of the items.
     */

    init(context: VerticalColumnPositioningContext) {
        self.context = context
        self.contentHeight = 0
        self.rows = []
        self.currentColumn = 0
        self.columnHeights = Array(repeating: 0, count: context.numberOfColumns)
    }

    /**
     * Add an item to the columns. It must be the item immediately succeding the current item.
     *
     * - parameter itemSize: The content size of the new item. This will be scaled appropriately
     * to fit the column it was assigned.
     *
     * - parameter indexPath: The index path of the new item.
     */

    mutating func insertItem(ofSize itemSize: CGSize, at indexPath: IndexPath) {

        // Compute the position of the item to add

        let itemVerticalSpacing = rows.count < context.numberOfColumns ? 0 : context.interItemSpacing
        var adjustedHeight = ((itemSize.height * context.columnWidth) / itemSize.width)

        if adjustedHeight.isSignalingNaN || adjustedHeight.isNaN {
            adjustedHeight = 0
        }

        let frame = CGRect(x: context.columns[currentColumn],
                           y: columnHeights[currentColumn] + itemVerticalSpacing,
                           width: context.columnWidth, height: adjustedHeight)

        // Create the attributes

        let rowAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        rowAttributes.frame = frame

        // Return the updated positioning

        contentHeight = max(contentHeight, frame.maxY)
        rows.append(rowAttributes)
        columnHeights[currentColumn] = frame.maxY
        currentColumn = nextColumn

    }

    private var nextColumn: Int {

        var smallestColumn: Int = 0

        for i in 0 ..< context.numberOfColumns {
            let currentValue = columnHeights[smallestColumn]
            let nextCandidate = columnHeights[i]
            smallestColumn = nextCandidate < currentValue ? i : smallestColumn
        }

        return smallestColumn

    }

}
