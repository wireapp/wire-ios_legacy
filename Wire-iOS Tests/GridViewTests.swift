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

import Foundation
import SnapshotTesting
import XCTest
@testable import Wire

class GridViewTests: XCTestCase {

    var sut: GridView!
    var tiles = [UIView]()

    let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: XCTestCase.DeviceSizeIPhone5)

    lazy var views: [UIView] = colors.map {
        let view = UIView(frame: frame)
        view.backgroundColor = $0
        return view
    }

    let colors: [UIColor] = [
        .red,
        .blue,
        .cyan,
        .brown,
        .orange,
        .green,
        .yellow,
        .magenta,
        .purple,
        .systemPink,
        .systemTeal,
        .gray
    ]

    override func setUp() {
        super.setUp()
        sut = GridView()
        sut.frame = frame
        sut.dataSource = self
        tiles.removeAll()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testGrid(withAmount amount: Int,
                  file: StaticString = #file,
                  testName: String = #function,
                  line: UInt = #line) {
        // Given
        tiles = Array(views.prefix(amount))
        sut.reloadData()

        // Then
        verify(matching: sut, file: file, testName: testName, line: line)
    }

    // MARK: - Tests

    func testOneView() {
        testGrid(withAmount: 1)
    }

    func testTwoViews() {
        testGrid(withAmount: 2)
    }

    func testThreeViews() {
        testGrid(withAmount: 3)
    }

    func testFourViews() {
        testGrid(withAmount: 4)
    }

    func testSixViews() {
        testGrid(withAmount: 6)
    }

    func testEightViews() {
        testGrid(withAmount: 8)
    }

    func testTenViews() {
        testGrid(withAmount: 10)
    }

    func testTwelveViews() {
        testGrid(withAmount: 12)
    }

}


extension GridViewTests: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tiles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridCell.reuseIdentifier, for: indexPath) as? GridCell else {
            return UICollectionViewCell()
        }

        cell.add(streamView: tiles[indexPath.row])
        return cell
    }

}
