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
import SnapshotTesting
@testable import Wire

final class SearchResultLabelTests: ZMSnapshotTestCase {
    var sut: SearchResultLabel!

    override func setUp() {
        super.setUp()
        accentColor = .violet
    }

    override func tearDown() {
        sut = nil
        resetColorScheme()
        super.tearDown()
    }

    fileprivate func performTest(file: StaticString = #file, line: UInt = #line) {
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
            new.queries = value.components(separatedBy: .whitespaces)
            return new
        }

        let secondMutator = Mutator<SearchResultLabel, String>(applicator: secondMutation, combinations: queryCombinations)

        let combinator = CombinationTest(mutable: self.sut, mutators: [firstMutator, secondMutator])

        XCTAssertEqual(combinator.testAll {
            let identifier = "\($0.combinationChain)"
            print("Testing combination " + identifier)

            $0.result.configure(with: $0.result.resultText!, queries: $0.result.queries)
            $0.result.numberOfLines = 1
            $0.result.translatesAutoresizingMaskIntoConstraints = false
            $0.result.setContentCompressionResistancePriority(.required, for: .vertical)
            $0.result.setContentHuggingPriority(.required, for: .vertical)
            $0.result.widthAnchor.constraint(lessThanOrEqualToConstant: 320).isActive = true

            $0.result.layoutForTest()
            let mockBackgroundView = UIView(frame: $0.result.frame)
            mockBackgroundView.backgroundColor = .from(scheme: .background)
            mockBackgroundView.addSubview($0.result)

            self.verify(view: mockBackgroundView, identifier: identifier, file: #file, line: #line)
            return .none
            }.count, 0, line: #line)
    }

    func prepareForTest(variant: ColorSchemeVariant, mode: UIUserInterfaceStyle) {
        ColorScheme.default.variant = variant
        sut = SearchResultLabel()
        sut.overrideUserInterfaceStyle = mode
        sut.font = UIFont.systemFont(ofSize: 17)
    }

    func testThatItShowsStringWithoutHighlightInDarkTheme() {

        prepareForTest(variant: .dark, mode: .dark)
        performTest()
    }

    func testThatItShowsStringWithoutHighlight() {
        prepareForTest(variant: .light, mode: .light)
        performTest()
    }
}
