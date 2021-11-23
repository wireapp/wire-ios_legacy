//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
@testable import Wire

struct MockCallStatusViewInputType: CallStatusViewInputType {
    var state: CallStatusViewState
    var isConstantBitRate: Bool
    var title: String
    var isVideoCall: Bool
    var userEnabledCBR: Bool
    var isForcedCBR: Bool
    var variant: ColorSchemeVariant
}

extension MockCallStatusViewInputType {
    static func fixture(isForcedCBR: Bool, userEnabledCBR: Bool) -> CallStatusViewInputType {
        return MockCallStatusViewInputType(state: .established(duration: 200), isConstantBitRate: true, title: "title", isVideoCall: false, userEnabledCBR: userEnabledCBR, isForcedCBR: isForcedCBR, variant: .dark)
    }
}

class CallStatusViewInputTypeTests: XCTestCase {

    func testShouldShowBitRateLabel() {
        var sut: CallStatusViewInputType

        sut = MockCallStatusViewInputType.fixture(isForcedCBR: true, userEnabledCBR: false)
        XCTAssertTrue(sut.shouldShowBitrateLabel)

        sut = MockCallStatusViewInputType.fixture(isForcedCBR: false, userEnabledCBR: true)
        XCTAssertTrue(sut.shouldShowBitrateLabel)

        sut = MockCallStatusViewInputType.fixture(isForcedCBR: false, userEnabledCBR: false)
        XCTAssertFalse(sut.shouldShowBitrateLabel)
    }
}
