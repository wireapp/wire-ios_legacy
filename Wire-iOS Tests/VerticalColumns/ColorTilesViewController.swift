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
@testable import Wire
import WireCommonComponents

struct ColorTile {
    let color: AccentColor
    let size: CGSize
}

final class ColorTilesViewController: VerticalColumnCollectionViewController, DeviceMockable {

    let tiles: [ColorTile]
    var device: DeviceProtocol = UIDevice.current

    init(tiles: [ColorTile], device: DeviceProtocol = UIDevice.current) {
        self.tiles = tiles
        self.device = device

        let columnCount = AdaptiveColumnCount(compact: 2, regular: 3, large: 4)
        super.init(interItemSpacing: 1, interColumnSpacing: 1, columnCount: columnCount)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "tile")
    }

    // MARK: - Collection View

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tiles.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tile = tiles[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tile", for: indexPath)
        cell.contentView.backgroundColor = UIColor(for: tile.color)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, sizeOfItemAt indexPath: IndexPath) -> CGSize {
        return tiles[indexPath.row].size
    }

    override var isRegularLayout: Bool {
        return isIPadRegular(device: device)
    }

}
