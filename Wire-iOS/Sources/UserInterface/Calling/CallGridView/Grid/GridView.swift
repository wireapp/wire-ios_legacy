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

import UIKit

protocol GridViewDelegate: class {
    func gridView(_ gridView: GridView, didChangePageTo page: Int)
}

/// A collection view that displays its items in a dynamic grid layout
/// depending on the number of items.
///
/// In a vertical orientation the grid generally follows a 2 columns x n rows layout.
/// There are two special cases: firstly a single item will occupy the entire grid,
/// and secondly two items will form a 1 column x 2 rows layout. In a horizontal
/// orientation, columns and rows are swapped.

final class GridView: UICollectionView {

    // MARK: - Properties

    var layoutDirection: UICollectionView.ScrollDirection = .vertical {
        didSet {
            reloadData()
        }
    }

    weak var gridViewDelegate: GridViewDelegate?

    let maxItemsPerPage: Int
    private(set) var currentPage: Int = 0

    // MARK: - Private Properties

    private let layout = UICollectionViewFlowLayout()

    // MARK: - Initialization

    init(maxItemsPerPage: Int) {
        guard maxItemsPerPage > 0 else {
            fatalError("maxItemsPerPage needs to be greater than zero")
        }

        self.maxItemsPerPage = maxItemsPerPage
        super.init(frame: .zero, collectionViewLayout: layout)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Methods

    private func setupViews() {
        delegate = self
        register(GridCell.self, forCellWithReuseIdentifier: GridCell.reuseIdentifier)
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        isPagingEnabled = true

        contentInsetAdjustmentBehavior = .never
    }

    // MARK: - Public Interface

    var numberOfPages: Int {
        guard let numberOfItems = dataSource?.collectionView(self, numberOfItemsInSection: 0) else {
            return 0
        }

        return numberOfItems / maxItemsPerPage + (numberOfItems % maxItemsPerPage == 0 ? 0 : 1)
    }

}

// MARK: - Segment calculation

private extension GridView {

    enum SegmentType {

        case row
        case column

    }

    enum ParticipantAmount {

        case moreThanTwo
        case twoOrLess

        init(_ amount: Int) {
            self = amount > 2 ? .moreThanTwo : .twoOrLess
        }

    }

    enum SplitType {

        case middleSplit
        case proportionalSplit

        init(_ layoutDirection: UICollectionView.ScrollDirection, _ segmentType: SegmentType) {
            switch (layoutDirection, segmentType) {
            case (.vertical, .row), (.horizontal, .column):
                self = .middleSplit
            case (.horizontal, .row), (.vertical, .column):
                self = .proportionalSplit
            @unknown default:
                fatalError()
            }
        }

    }

    private func numberOfItemsInPage(indexPath: IndexPath) -> Int {
        guard let numberOfItems = dataSource?.collectionView(self, numberOfItemsInSection: indexPath.section) else {
            return 0
        }

        // The result will be floored because the operation is on two Ints. This makes pages start from 0.
        let page = indexPath.row / maxItemsPerPage

        let itemsInPastPages = page * maxItemsPerPage
        let itemsRemaining = numberOfItems - itemsInPastPages
        return itemsRemaining > maxItemsPerPage ? maxItemsPerPage : itemsRemaining
    }

    func numberOfItemsIn(_ segmentType: SegmentType, for indexPath: IndexPath) -> Int {
        let numberOfItemsInPage = self.numberOfItemsInPage(indexPath: indexPath)

        let participantAmount = ParticipantAmount(numberOfItemsInPage)
        let splitType = SplitType(layoutDirection, segmentType)

        switch (participantAmount, splitType) {
        case (.moreThanTwo, .proportionalSplit):
            return numberOfItemsInPage.evenlyCeiled / 2
        case (.moreThanTwo, .middleSplit):
            let isOddLastRow = self.isOddLastRow(indexPath)
            let isLayoutDirectionVertical = layoutDirection == .vertical
            return isOddLastRow && isLayoutDirectionVertical ? 1 : 2
        case (.twoOrLess, .proportionalSplit):
            return numberOfItemsInPage
        case (.twoOrLess, .middleSplit):
            return 1
        }
    }

    func isOddLastRow(_ indexPath: IndexPath) -> Bool {
        guard let numberOfItems = dataSource?.collectionView(self, numberOfItemsInSection: indexPath.section) else {
            return false
        }

        let isLastRow = numberOfItems == indexPath.row + 1
        let isOdd = !numberOfItems.isEven
        return isOdd && isLastRow
    }

}

// MARK: - UICollectionViewDelegateFlowLayout

extension GridView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxWidth = collectionView.bounds.size.width
        let maxHeight = collectionView.bounds.size.height

        let itemsInRow = numberOfItemsIn(.row, for: indexPath)
        let itemsInColumn = numberOfItemsIn(.column, for: indexPath)

        let width = maxWidth / CGFloat(itemsInRow)
        let height = maxHeight / CGFloat(itemsInColumn)

        return CGSize(width: width, height: height)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int) -> UIEdgeInsets {

        return .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        return .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {

        return .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int) -> CGSize {

        return .zero
    }
}

// MARK: - UIScrollViewDelegate

extension GridView: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var page: CGFloat

        switch layout.scrollDirection {
        case .horizontal:
            page = scrollView.contentOffset.x / scrollView.frame.size.width
        case .vertical:
            page = scrollView.contentOffset.y / scrollView.frame.size.height
        @unknown default:
            return
        }

        currentPage = Int(page)
        gridViewDelegate?.gridView(self, didChangePageTo: currentPage)
    }

}
