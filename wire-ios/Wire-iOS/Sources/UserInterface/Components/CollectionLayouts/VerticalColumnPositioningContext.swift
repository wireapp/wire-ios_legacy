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
 * The context for computing the position of items.
 */

struct VerticalColumnPositioningContext {

    /// The width of the collection view container, minus insets.
    let contentWidth: CGFloat

    /// The number of columns that will organize the contents.
    let numberOfColumns: Int

    /// The spacing between items inside the same column.
    let interItemSpacing: CGFloat

    /// The spacing between columns.
    let interColumnSpacing: CGFloat

    /// The start position of each columns.
    let columns: [CGFloat]

    /// The width of a single column.
    let columnWidth: CGFloat

    init(contentWidth: CGFloat, numberOfColumns: Int, interItemSpacing: CGFloat, interColumnSpacing: CGFloat) {
        self.contentWidth = contentWidth
        self.numberOfColumns = numberOfColumns
        self.interItemSpacing = interItemSpacing
        self.interColumnSpacing = interColumnSpacing

        let totalSpacing = (CGFloat(numberOfColumns - 1) * interColumnSpacing)
        let columnWidth = ((contentWidth - totalSpacing) / CGFloat(numberOfColumns))

        self.columns = (0 ..< numberOfColumns).map {
            let base = CGFloat($0) * columnWidth
            let precedingSpacing = CGFloat($0) * interColumnSpacing
            return base + precedingSpacing
        }

        self.columnWidth = columnWidth
    }

}
