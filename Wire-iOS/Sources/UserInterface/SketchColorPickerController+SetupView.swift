//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import Foundation

extension SketchColorPickerController {

    @objc
    func setUpColorsCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 44, height: 40)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        colorsCollectionViewLayout = flowLayout

        colorsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        colorsCollectionView.showsHorizontalScrollIndicator = false
        colorsCollectionView.backgroundColor = .from(scheme: .background)
        view.addSubview(colorsCollectionView)

        colorsCollectionView.register(SketchColorCollectionViewCell.self, forCellWithReuseIdentifier: "SketchColorCollectionViewCell")
        colorsCollectionView.dataSource = self
        colorsCollectionView.delegate = self

        colorsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        colorsCollectionView.fitInSuperview()
    }
}
