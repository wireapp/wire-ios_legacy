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
@testable import Wire

class AnalyticsMixpanelProviderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        UserDefaults.shared().set(nil, forKey: MixpanelDistinctIdKey)
        UserDefaults.shared().synchronize()
        
        super.tearDown()
    }
    
    func testThatItGeneratesAndStoresUniqueMixpanelId() {
        // given
        let userDefaults = UserDefaults.shared()
        XCTAssertNotNil(userDefaults)
        XCTAssertNil(userDefaults!.string(forKey: MixpanelDistinctIdKey))
        
        // when
        let sut = AnalyticsMixpanelProvider()
        let generatedId = sut.mixpanelDistinctId
        
        // then
        let storedId = userDefaults!.string(forKey: MixpanelDistinctIdKey)
        XCTAssertNotNil(storedId)
        XCTAssertEqual(storedId!, generatedId)
    }
}
