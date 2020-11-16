// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import Countly
@testable import Wire

final class AnalyticsCountlyProviderTests: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!

    var sut: Analytics!
    
    override func setUp() {
        super.setUp()
        
        coreDataFixture = CoreDataFixture()
    }

    override func tearDown() {
        sut = nil
        coreDataFixture = nil
        MockCountly.reset()
        
        super.tearDown()
    }

    func testThatLogRoundedConvertNumberIntoBuckets() {
        XCTAssertEqual([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 50, 100].map({$0.logRound()}), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 46, 91])
    }

    func testThatCountlyAttributesFromConverationIsGenerated() {
        let mockConversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC, otherUser: otherUser)

        let convertedDictionary = mockConversation.attributesForConversation.countlyStringValueDictionary

        XCTAssertEqual(convertedDictionary, ["conversation_guests_wireless": "0",
                                             "is_allow_guests": "False",
                                             "conversation_type": "one_to_one",
                                             "conversation_guests_pro": "0",
                                             "user_type": "user",
                                             "with_service": "False",
                                             "conversation_size": "2",
                                             "conversation_services": "0",
                                             "is_global_ephemeral": "False",
                                             "conversation_guests": "0"])
    }

    // MARK: - app.open tag

    func testThatAppOpenIsStoredAndTaggedAfterSelfUserIsSet() {
        coreDataFixture.teamTest {

            //GIVEN
            sut = Analytics(optedOut: false)
            let analyticsCountlyProvider = AnalyticsCountlyProvider(countlyInstanceType: MockCountly.self,
                                                                    countlyAppKey: "dummy countlyAppKey")!
            sut.provider = analyticsCountlyProvider

            //WHEN
            XCTAssertEqual(analyticsCountlyProvider.storedEventsCount, 0)
            sut.tagEvent("app.open")

            //THEN
            XCTAssertEqual(analyticsCountlyProvider.storedEventsCount, 1)
            XCTAssertEqual(MockCountly.recordEventCount, 0)

            //WHEN
            sut.selfUser = coreDataFixture.selfUser

            //THEN
            XCTAssertEqual(MockCountly.startCount, 1)

            XCTAssertEqual(analyticsCountlyProvider.storedEventsCount, 0)
            XCTAssertEqual(MockCountly.recordEventCount, 1)
        }
    }
    
    func testThatCountlyIsNotStartedForNonTeamMember() {
        coreDataFixture.nonTeamTest {
            //GIVEN
            sut = Analytics(optedOut: false)
            let analyticsCountlyProvider = AnalyticsCountlyProvider(countlyInstanceType: MockCountly.self)!
            sut.provider = analyticsCountlyProvider

            //WHEN
            sut.selfUser = coreDataFixture.selfUser

            //THEN
            XCTAssertEqual(MockCountly.startCount, 0)
        }
    }

}

final class MockCountly: CountlyInstance {
    static var recordEventCount = 0
    static var startCount = 0

    static let shared = MockCountly()
    
    static func reset() {
        recordEventCount = 0
        startCount = 0
    }

    static func sharedInstance() -> Self {
        return shared as! Self
    }
    
    func recordEvent(_ key: String, segmentation: [String: String]?) {
        MockCountly.recordEventCount += 1
    }
    
    func start(with config: CountlyConfig) {
        MockCountly.startCount += 1
    }
}
