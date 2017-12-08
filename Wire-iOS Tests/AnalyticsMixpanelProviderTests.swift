//
//  AnalyticsMixpanelProviderTests.swift
//  Wire-iOS-Tests
//
//  Created by John Nguyen on 29.11.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import XCTest
@testable import Wire

class AnalyticsMixpanelProviderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        UserDefaults.shared().set(nil, forKey: MixpanelDistinctIdKey)
        UserDefaults.shared().synchronize()
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
