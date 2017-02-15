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

import Foundation
import XCTest
import Classy
import Cartography
@testable import Wire

class SearchResultLabelTests: ZMSnapshotTestCase {
    let sut = SearchResultLabel()
    
    override func setUp() {
        super.setUp()
        accentColor = .violet
        CASStyler.default().styleItem(sut)
        self.recordMode = true
    }
    
    func testThatItShowsStringWithoutHighlight() {
        let textCombinations = Set<String>(arrayLiteral: "Very short text", "Very very long text Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
        
        let queryCombinations = Set<String>(arrayLiteral: "", "Short", "Very", "very long", "veniam")
        
        let firstMutation = { (proto: SearchResultLabel, value: String) -> SearchResultLabel in
            let new = proto.copyInstance()
            new.resultText = value
            return new
        }
        let firstMutator = Mutator<SearchResultLabel, String>(applicator: firstMutation, combinations: textCombinations)
        
        let secondMutation = { (proto: SearchResultLabel, value: String) -> SearchResultLabel in
            let new = proto.copyInstance()
            new.query = value
            return new
        }
        let secondMutator = Mutator<SearchResultLabel, String>(applicator: secondMutation, combinations: queryCombinations)
        
        let combinator = CombinationTest(mutable: self.sut, mutators: [firstMutator, secondMutator])
        
        XCTAssertEqual(combinator.testAll {
            let identifier = "\($0.combinationChain)"
            print("Testing combination " + identifier)
            constrain($0.result) { label in
                label.width <= 320
            }
            $0.result.numberOfLines = 1
            $0.result.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
            $0.result.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
            
            $0.result.layoutForTest()
            self.verify(view: $0.result, identifier: identifier, file: #file, line: #line)
            return .none
            }.count, 0, line: #line)
    }
}

