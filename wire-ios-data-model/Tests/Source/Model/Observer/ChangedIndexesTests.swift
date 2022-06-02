//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
@testable import WireDataModel

class ChangedIndexesTests: ZMBaseManagedObjectTest {

    // MARK: CollectionView

    func testThatItCalculatesInsertsAndDeletesBetweenSets() {
        // given
        let startState = WireDataModel.OrderedSetState(array: ["A", "B", "C", "D", "E"])
        let endState = WireDataModel.OrderedSetState(array: ["A", "F", "E", "C", "D"])

        // when
        let sut = WireDataModel.ChangedIndexes(start: startState, end: endState, updated: Set())

        // then
        XCTAssertEqual(sut.deletedIndexes, [1])
        XCTAssertEqual(sut.insertedIndexes, [1])
    }

    func testThatItCalculatesMovesCorrectly() {

        // given
        let startState = WireDataModel.OrderedSetState(array: ["A", "B", "C", "D", "E"])
        let endState = WireDataModel.OrderedSetState(array: ["A", "F", "D", "C", "E"])

        // when
        let sut = WireDataModel.ChangedIndexes(start: startState, end: endState, updated: Set())

        // then
        // [A,B,C,D,E] -> [A,F,C,D,E] delete & insert
        var callCount = 0
        sut.enumerateMovedIndexes { (from, to) in
            if callCount == 0 {
                // D: [3->2]
                XCTAssertEqual(from, 3)
                XCTAssertEqual(to, 2)
            }
            callCount += 1
        }
        XCTAssertEqual(callCount, 1)

        var result = ["A", "B", "C", "D", "E"]
        sut.deletedIndexes.forEach {result.remove(at: $0)}
        sut.insertedIndexes.forEach {result.insert(endState.array[$0], at: $0)}
        sut.enumerateMovedIndexes { (from, to) in
            let item = startState.array[from]
            result.remove(at: result.firstIndex(of: item)!)
            result.insert(item, at: to)
        }
        XCTAssertEqual(result, ["A", "F", "D", "C", "E"])
    }

    func testThatItCalculatesMovesCorrectly_2() {

        // given
        let startState = WireDataModel.OrderedSetState(array: ["A", "B", "C", "D", "E"])
        let endState = WireDataModel.OrderedSetState(array: ["A", "D", "E", "F", "C"])

        // when
        let sut = WireDataModel.ChangedIndexes(start: startState, end: endState, updated: Set())

        // then
        // [A,B,C,D,E] -> [A,C,D,F,E] delete & insert
        var callCount = 0
        sut.enumerateMovedIndexes { (from, to) in
            if callCount == 0 {
                // ACDFE
                // E: [3->1] -> ADCFE
                XCTAssertEqual(from, 3)
                XCTAssertEqual(to, 1)
            }
            if callCount == 1 {
                // ADCFE
                // D: [4->2] -> ADECF
                XCTAssertEqual(from, 4)
                XCTAssertEqual(to, 2)
            }
            if callCount == 2 {
                // ADECF
                // C: [2->4] -> ADEFC
                XCTAssertEqual(from, 2)
                XCTAssertEqual(to, 4)
            }
            callCount += 1
        }
        XCTAssertEqual(callCount, 3)

        var result = ["A", "B", "C", "D", "E"]
        sut.deletedIndexes.forEach {result.remove(at: $0)}
        sut.insertedIndexes.forEach {result.insert(endState.array[$0], at: $0)}
        sut.enumerateMovedIndexes { (from, to) in
            let item = startState.array[from]
            result.remove(at: result.firstIndex(of: item)!)
            result.insert(item, at: to)
        }
        XCTAssertEqual(result, ["A", "D", "E", "F", "C"])
    }

    func testThatItCalculatesMovedIndexesForSwappedIndexesCorrectly() {
        // If you move an item from 0->1 another item has to move to index 0

        // given
        let startState = WireDataModel.OrderedSetState(array: ["A", "B", "C"])
        let endState = WireDataModel.OrderedSetState(array: ["C", "B", "A"])

        // when
        let sut = WireDataModel.ChangedIndexes(start: startState, end: endState, updated: Set())

        // then
        XCTAssertEqual(sut.deletedIndexes, IndexSet())
        XCTAssertEqual(sut.insertedIndexes, IndexSet())

        // then
        var callCount = 0
        sut.enumerateMovedIndexes { (from, to) in
            if callCount == 0 {
                XCTAssertEqual(from, 2)
                XCTAssertEqual(to, 0)
            }
            if callCount == 1 {
                XCTAssertEqual(from, 1)
                XCTAssertEqual(to, 1)
            }
            callCount += 1
        }
        XCTAssertEqual(callCount, 2)

        var result = ["A", "B", "C"]
        sut.enumerateMovedIndexes { (from, to) in
            let item = startState.array[from]
            result.remove(at: result.firstIndex(of: item)!)
            result.insert(item, at: to)
        }
        XCTAssertEqual(result, ["C", "B", "A"])
    }

    func testThatItCalculatesUpdatesCorrectly() {
        // Updated indexes refer to the indexes after the update

        // given
        let startState = WireDataModel.OrderedSetState(array: ["A", "B", "C"])
        let endState = WireDataModel.OrderedSetState(array: ["C", "D", "B", "A"])

        // when
        let sut = WireDataModel.ChangedIndexes(start: startState, end: endState, updated: Set(["B"]))

        // then
        XCTAssertEqual(sut.updatedIndexes, IndexSet([2]))
    }

    // MARK: TableView

    func testThatItCalculatesMovesCorrectly_tableView() {

        // given
        let startState = WireDataModel.OrderedSetState(array: ["A", "B", "C", "D", "E"])
        let endState = WireDataModel.OrderedSetState(array: ["A", "F", "D", "C", "E"])

        // when
        let sut = WireDataModel.ChangedIndexes(start: startState, end: endState, updated: Set(), moveType: .uiTableView)

        // then
        // [A,B,C,D,E] -> [A,F,C,D,E] delete & insert
        var callCount = 0
        sut.enumerateMovedIndexes { (from, to) in
            if callCount == 0 {
                // D: [3->2]
                XCTAssertEqual(from, 3)
                XCTAssertEqual(to, 2)
            }
            callCount += 1
        }
        XCTAssertEqual(callCount, 1)

        var result = ["A", "B", "C", "D", "E"]
        sut.deletedIndexes.forEach {result.remove(at: $0)}
        sut.insertedIndexes.forEach {result.insert(endState.array[$0], at: $0)}
        sut.enumerateMovedIndexes { (from, to) in
            let item = result.remove(at: from)
            result.insert(item, at: to)
        }
        XCTAssertEqual(result, ["A", "F", "D", "C", "E"])
    }

    func testThatItCalculatesMovesCorrectly_2_tableView() {

        // given
        let startState = WireDataModel.OrderedSetState(array: ["A", "B", "C", "D", "E"])
        let endState = WireDataModel.OrderedSetState(array: ["A", "D", "E", "F", "C"])

        // when
        let sut = WireDataModel.ChangedIndexes(start: startState, end: endState, updated: Set(), moveType: .uiTableView)

        // then
        // [A,B,C,D,E] -> [A,C,D,F,E] delete & insert
        var callCount = 0
        sut.enumerateMovedIndexes { (from, to) in
            if callCount == 0 {
                // ACDFE
                // E: [3->1] -> ADCFE
                XCTAssertEqual(from, 2)
                XCTAssertEqual(to, 1)
            }
            if callCount == 1 {
                // ADCFE
                // D: [4->2] -> ADECF
                XCTAssertEqual(from, 4)
                XCTAssertEqual(to, 2)
            }
            if callCount == 2 {
                // ADECF
                // C: [2->4] -> ADEFC
                XCTAssertEqual(from, 4)
                XCTAssertEqual(to, 3)
            }
            callCount += 1
        }
        XCTAssertEqual(callCount, 3)

        var result = ["A", "B", "C", "D", "E"]
        sut.deletedIndexes.forEach {result.remove(at: $0)}
        sut.insertedIndexes.forEach {result.insert(endState.array[$0], at: $0)}
        sut.enumerateMovedIndexes { (from, to) in
            let item = result.remove(at: from)
            result.insert(item, at: to)
        }
        XCTAssertEqual(result, ["A", "D", "E", "F", "C"])
    }

    func testThatItCalculatesMovedIndexesForSwappedIndexesCorrectly_tableView() {
        // If you move an item from 0->1 the item at index 1 moves implicitly to 0, its move do not need to be defined

        // given
        let startState = WireDataModel.OrderedSetState(array: ["A", "B", "C"])
        let endState = WireDataModel.OrderedSetState(array: ["C", "B", "A"])

        // when
        let sut = WireDataModel.ChangedIndexes(start: startState, end: endState, updated: Set(), moveType: .uiTableView)

        // then
        XCTAssertEqual(sut.deletedIndexes, IndexSet())
        XCTAssertEqual(sut.insertedIndexes, IndexSet())

        // then
        var callCount = 0
        sut.enumerateMovedIndexes { (from, to) in
            if callCount == 0 {
                XCTAssertEqual(from, 2)
                XCTAssertEqual(to, 0)
            }
            if callCount == 1 {
                XCTAssertEqual(from, 2)
                XCTAssertEqual(to, 1)
            }
            callCount += 1
        }
        XCTAssertEqual(callCount, 2)

        var result = ["A", "B", "C"]
        sut.enumerateMovedIndexes { (from, to) in
            let item = result.remove(at: from)
            result.insert(item, at: to)
        }
        XCTAssertEqual(result, ["C", "B", "A"])
    }

}
