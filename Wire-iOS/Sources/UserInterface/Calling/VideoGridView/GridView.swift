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

class GridView: UIView {
    private let collectionView: UICollectionView
    private let layout = UICollectionViewFlowLayout()
    private(set) var videoStreamViews = [UIView]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var layoutDirection: UICollectionView.ScrollDirection = .vertical {
        didSet {
            layout.scrollDirection = layoutDirection
            collectionView.reloadData()
        }
    }
    
    init() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: GridCell.reuseIdentifier)
        collectionView.isScrollEnabled = false
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.fitInSuperview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Interface
extension GridView {
    func append(view: UIView) {
        videoStreamViews.append(view)
    }
    
    func remove(view: UIView) {
        videoStreamViews.firstIndex(of: view).apply { videoStreamViews.remove(at: $0) }
    }
}

// MARK: - Segment calculation
extension GridView {
    private func numberOfItems(in segmentType: SegmentType, for indexPath: IndexPath) -> Int {
        let participantAmount = ParticipantAmount(videoStreamViews.count)
        let splitType = SplitType(layoutDirection, segmentType)
        
        switch (participantAmount, splitType) {
        case (.moreThanTwo, .proportionalSplit):
            return videoStreamViews.count.evenlyCeiled / 2
        case (.moreThanTwo, .middleSplit):
            return isOddLastRow(indexPath) ? 1 : 2
        case (.twoAndLess, .proportionalSplit):
            return videoStreamViews.count
        case (.twoAndLess, .middleSplit):
            return 1
        }
    }

    private enum SegmentType {
        case row
        case column
    }
    
    private enum ParticipantAmount {
        case moreThanTwo
        case twoAndLess
        
        init(_ amount: Int) {
            self = amount > 2 ? .moreThanTwo : .twoAndLess
        }
    }
    
    private enum SplitType {
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
    
    private func isOddLastRow(_ indexPath: IndexPath) -> Bool {
        let isLastRow = videoStreamViews.count == indexPath.row + 1
        let isOdd = !videoStreamViews.count.isEven
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
}

// MARK: - UICollectionViewDataSource
extension GridView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoStreamViews.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridCell.reuseIdentifier, for: indexPath) as? GridCell else {
            return UICollectionViewCell()
        }
        
        let streamView = videoStreamViews[indexPath.row]
        cell.add(streamView: streamView)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension GridView: UICollectionViewDelegate {}
