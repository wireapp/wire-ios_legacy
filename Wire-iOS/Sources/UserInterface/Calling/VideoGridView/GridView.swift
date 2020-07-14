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

    private var numberOfItems: Int {
        return dataSource?.collectionView(self, numberOfItemsInSection: 0) ?? 0
    }

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

    func numberOfItems(in segmentType: SegmentType, for indexPath: IndexPath) -> Int {
        let participantAmount = ParticipantAmount(numberOfItems)
        let splitType = SplitType(layoutDirection, segmentType)
        
        switch (participantAmount, splitType) {
        case (.moreThanTwo, .proportionalSplit):
            return numberOfItems.evenlyCeiled / 2
        case (.moreThanTwo, .middleSplit):
            return isOddLastRow(indexPath) ? 1 : 2
        case (.twoAndLess, .proportionalSplit):
            return numberOfItems
        case (.twoAndLess, .middleSplit):
            return 1
        }
    }

    enum SegmentType {

        case row
        case column

    }
    
    enum ParticipantAmount {

        case moreThanTwo
        case twoAndLess
        
        init(_ amount: Int) {
            self = amount > 2 ? .moreThanTwo : .twoAndLess
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
    
    func isOddLastRow(_ indexPath: IndexPath) -> Bool {
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
