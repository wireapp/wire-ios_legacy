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

import XCTest
@testable import Wire

class ColorViewCell: UICollectionViewCell {}

class ColorViewController: VerticalColumnCollectionViewController {

    struct Item {
        let color: ZMAccentColor
        let size: CGSize
    }

    enum TestEnvironment {
        case phone, tablet
    }

    let dataSource: [Item]
    var testEnvironment: TestEnvironment

    init(dataSource: [Item], testEnvironment: TestEnvironment) {
        self.dataSource = dataSource
        self.testEnvironment = testEnvironment

        let columnLayout = AdaptiveColumnLayout(compact: 2, regular: 3, large: 4)
        super.init(interItemSpacing: 2, interColumnSpacing: 4, columnLayout: columnLayout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = dataSource[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = UIColor(for: item.color)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, sizeOfItemAt indexPath: IndexPath) -> CGSize {
        return dataSource[indexPath.row].size
    }

    override var isRegularLayout: Bool {
        return testEnvironment == .tablet
    }

}

// MARK: - Tests

class VerticalColumnCollectionViewLayoutTests: ZMSnapshotTestCase {

    let items: [ColorViewController.Item] = [
        // square, downscale
        ColorViewController.Item(color: .vividRed, size: CGSize(width: 1000, height: 1000)),
        // square, upscale
        ColorViewController.Item(color: .violet, size: CGSize(width: 10, height: 10)),
        // portrait, downscale
        ColorViewController.Item(color: .brightYellow, size: CGSize(width: 1000, height: 1500)),
        // portrait, upscale
        ColorViewController.Item(color: .strongLimeGreen, size: CGSize(width: 10, height: 15)),
        // landscape, downscale
        ColorViewController.Item(color: .strongBlue, size: CGSize(width: 1500, height: 1000)),
        // landscape, upscale
        ColorViewController.Item(color: .softPink, size: CGSize(width: 15, height: 10)),
        // add 4 more to test multiline
        ColorViewController.Item(color: .vividRed, size: CGSize(width: 1000, height: 1000)),
        ColorViewController.Item(color: .violet, size: CGSize(width: 10, height: 10)),
        ColorViewController.Item(color: .brightYellow, size: CGSize(width: 1000, height: 1500)),
        ColorViewController.Item(color: .strongLimeGreen, size: CGSize(width: 10, height: 15))
    ]

    override func setUp() {
        super.setUp()
        recordMode = true
    }

    func testColumns_iPhone() {
        let sut = ColorViewController(dataSource: items, testEnvironment: .phone)
        verifyInAllIPhoneSizes(view: sut.view)
    }

    func testColumns_iPad() {
        let sut = ColorViewController(dataSource: items, testEnvironment: .tablet)
        verifyInAllTabletWidths(view: sut.view)
    }

}
