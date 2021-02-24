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
            layout.scrollDirection = layoutDirection
            reloadData()
        }
    }

    // MARK: - Private Properties

    private let layout = UICollectionViewFlowLayout()

    // MARK: - Initialization

    init() {
        super.init(frame: .zero, collectionViewLayout: layout)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Methods

    private func setUp() {
        delegate = self
        register(GridCell.self, forCellWithReuseIdentifier: GridCell.reuseIdentifier)
        isScrollEnabled = false
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
                self = .proportionalSplit
            case (.horizontal, .row), (.vertical, .column):
                self = .middleSplit
            @unknown default:
                fatalError()
            }
        }

    }

    func numberOfItems(in segmentType: SegmentType, for indexPath: IndexPath) -> Int {
        guard let numberOfItems = dataSource?.collectionView(self, numberOfItemsInSection: indexPath.section) else {
            return 0
        }

        let participantAmount = ParticipantAmount(numberOfItems)
        let splitType = SplitType(layoutDirection, segmentType)

        switch (participantAmount, splitType) {
        case (.moreThanTwo, .proportionalSplit):
            return numberOfItems.evenlyCeiled / 2
        case (.moreThanTwo, .middleSplit):
            return isOddLastRow(indexPath) ? 1 : 2
        case (.twoOrLess, .proportionalSplit):
            return numberOfItems
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

        let rows = numberOfItems(in: .row, for: indexPath)
        let columns = numberOfItems(in: .column, for: indexPath)

        let width = maxWidth / CGFloat(columns)
        let height = maxHeight / CGFloat(rows)

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
