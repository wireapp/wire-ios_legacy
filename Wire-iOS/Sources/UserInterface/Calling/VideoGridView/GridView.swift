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

class GridView: NSObject {
    let collectionView: UICollectionView
    private let layout = UICollectionViewFlowLayout()
    private(set) var videoStreamViews = [UIView]()
    
    var layoutDirection: UICollectionView.ScrollDirection = .vertical {
        didSet {
            layout.scrollDirection = layoutDirection
            collectionView.reloadData()
        }
    }
    
    override init() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: GridCell.reuseIdentifier)
        collectionView.isScrollEnabled = false
    }
    
    func append(view: UIView) {
        videoStreamViews.append(view)
        collectionView.reloadData()
    }
    
    func remove(view: UIView) {
        videoStreamViews.firstIndex(of: view).apply { videoStreamViews.remove(at: $0) }
        collectionView.reloadData()
    }
}

extension GridView: UICollectionViewDelegate {

}

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

extension GridView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxWidth = collectionView.bounds.size.width
        let maxHeight = collectionView.bounds.size.height
        
        let rows = calculateRows(for: indexPath)
        let columns = calculateColumns(for: indexPath)
        
        let width = maxWidth / CGFloat(columns)
        let height = maxHeight / CGFloat(rows)

        return CGSize(width: width, height: height)
    }
    
    private func calculateRows(for indexPath: IndexPath) -> Int {
        let verticalLayout = layoutDirection == .vertical
        if videoStreamViews.count > 2 {
            if verticalLayout {
                return videoStreamViews.count.evened / 2
            } else {
                return (!videoStreamsViewsIsEven && isLastRow(indexPath)) ? 1 : 2
            }
        } else {
            return verticalLayout ? videoStreamViews.count : 1
        }
    }
    
    private func calculateColumns(for indexPath: IndexPath) -> Int {
        let verticalLayout = layoutDirection == .vertical
        if videoStreamViews.count > 2 {
            if verticalLayout {
                return (!videoStreamsViewsIsEven && isLastRow(indexPath)) ? 1 : 2
            } else {
                return videoStreamViews.count.evened / 2
            }
        } else {
            return verticalLayout ? 1 : videoStreamViews.count
        }
    }
    
    private var videoStreamsViewsIsEven: Bool {
        return videoStreamViews.count.isEven
    }
    
    private func isLastRow(_ indexPath: IndexPath) -> Bool {
        return videoStreamViews.count == indexPath.row + 1
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

