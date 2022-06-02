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

import XCTest
import LocalAuthentication
@testable import WireDataModel

class BiometricsStateTests: XCTestCase {

    private var sut: BiometricsState!

    let state1 = Data([1])
    let state2 = Data([2])

    override func setUp() {
        super.setUp()
        sut = BiometricsState()
    }

    override func tearDown() {
        sut.lastPolicyDomainState = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_BiometricsChangedIsTrue_IfDomainStatesDiffer() {
        // Given
        sut.lastPolicyDomainState = state1

        let context = MockLAContext(evaluatedPolicyDomainState: state2)

        // Then
        XCTAssertTrue(sut.biometricsChanged(in: context))
    }

    func test_BiometricsChangedIsFalse_IfDomainStatesDontDiffer() {
        // Given
        sut.lastPolicyDomainState = state1

        let context = MockLAContext(evaluatedPolicyDomainState: state1)

        // Then
        XCTAssertFalse(sut.biometricsChanged(in: context))
    }

    func test_BiometricsChangedIsFalse_IfThereIsNoPreviousState() {
        // Given
        sut.lastPolicyDomainState = nil

        let context = MockLAContext(evaluatedPolicyDomainState: state1)

        // Then
        XCTAssertFalse(sut.biometricsChanged(in: context))
    }

    func test_ItPersistsState() {
        // Given
        sut.lastPolicyDomainState = nil

        let context = MockLAContext(evaluatedPolicyDomainState: state1)
        _ = sut.biometricsChanged(in: context)

        // When
        sut.persistState()

        // Then
        sut.lastPolicyDomainState = state1
    }

}
