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
 * A number of columns that changes depending on the width of the container.
 */

public struct AdaptiveColumnCount {

    /// The number of columns when the container has a compact horizontal size class.
    let compact: Int

    /// The number of columns when the container has a regular horizontal size class,
    /// and a width smaller than 1024pt.
    let regular: Int

    /// The number of columns when the container has a regular horizontal size class,
    /// and a width larger than 1024pt.
    let large: Int

    public init(compact: Int, regular: Int, large: Int) {
        self.compact = compact
        self.regular = regular
        self.large = large
    }

}

/**
 * An abstract collection view container that allows displaying the cells into columns.
 *
 * You must implement the `collectionView(_:, sizeOfItemAt:)` method in your subclasses.
 */

class VerticalColumnCollectionViewController: UICollectionViewController, VerticalColumnCollectionViewLayoutDelegate {

    fileprivate let layout: VerticalColumnCollectionViewLayout
    fileprivate let columnCount: AdaptiveColumnCount

    /**
     * Creates the view controller.
     * - parameter interItemSpacing: The spacing between items in the same column.
     * - parameter interColumnSpacing: The spacing between columns.
     * - parameter columnCount: The number of columns to show depending on the current size class.
     */

    init(interItemSpacing: CGFloat, interColumnSpacing: CGFloat, columnCount: AdaptiveColumnCount) {
        layout = VerticalColumnCollectionViewLayout()
        layout.interItemSpacing = interItemSpacing
        layout.interColumnSpacing = interColumnSpacing

        self.columnCount = columnCount
        super.init(collectionViewLayout: layout)
        layout.delegate = self

        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = .never
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.updateLayout(for: size)
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLayout()
    }

    // MARK: - Size Changes

    /**
     * Whether the current layout is in regular mode.
     *
     * The default implementation returns `true` if the horizontal size class of the view
     * is regular. You can override this method for testing purposes.
     */

    var isRegularLayout: Bool {
        return view.traitCollection.horizontalSizeClass == .regular
    }

    /**
     * Updates the layout of the view in response to a size change.
     *
     * - parameter size: The current size of the view. Defaults to the size of the view's bounds.
     *
     * You can override this method if you need to perform other layout updates when the
     * size of the view changes.
     */

    func updateLayout(for size: CGSize? = nil) {
        layout.numberOfColumns = numberOfColumns(inContainer: size?.width ?? view.bounds.width)
        collectionView?.collectionViewLayout.invalidateLayout()
        navigationItem.titleView?.setNeedsLayout()
    }

    private func numberOfColumns(inContainer width: CGFloat) -> Int {
        if isRegularLayout {
            return width < 1024 ? columnCount.regular : columnCount.large
        }
        return columnCount.compact
    }

    // MARK: - Sizing

    func collectionView(_ collectionView: UICollectionView, sizeOfItemAt indexPath: IndexPath) -> CGSize {
        fatalError("Subclasses of 'VerticalColumnCollectionViewController' must implement this method.")
    }

}
