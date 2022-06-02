////
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
@testable import WireSyncEngine

final class ZMUserSessionTests_SecurityClassification: ZMUserSessionTestsBase {

    func createUser(moc: NSManagedObjectContext, domain: String?) -> ZMUser {
        let user = ZMUser(context: moc)
        user.remoteIdentifier = UUID()
        user.domain = domain
        user.name = "Other Test User"

        return user
    }

    func storeClassifiedDomains(with status: Feature.Status, domains: [String]) {
        let classifiedDomains = Feature.ClassifiedDomains(
            status: status,
            config: Feature.ClassifiedDomains.Config(domains: domains)
        )
        sut.featureService.storeClassifiedDomains(classifiedDomains)
    }

    func testThatItReturnsNone_WhenFeatureIsEnabled_WhenSelfDomainIsNil() {
        // given
        let otherUser = createUser(moc: syncMOC, domain: UUID().uuidString)

        storeClassifiedDomains(with: .enabled, domains: [])

        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = nil
            self.syncMOC.saveOrRollback()
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(with: [otherUser])

        // then
        XCTAssertEqual(classification, .none)
    }

    func testThatItReturnsNone_WhenFeatureIsDisabled_WhenSelfDomainIsNotNil() {
        // given
        let otherUser = createUser(moc: syncMOC, domain: UUID().uuidString)

        storeClassifiedDomains(with: .disabled, domains: [])

        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(with: [otherUser])

        // then
        XCTAssertEqual(classification, .none)
    }

    func testThatItReturnClassified_WhenFeatureIsEnabled_WhenAllOtherUserDomainIsClassified() {
        // given
        let otherUser1 = createUser(moc: syncMOC, domain: UUID().uuidString)
        let otherUser2 = createUser(moc: syncMOC, domain: UUID().uuidString)
        let otherUser3 = createUser(moc: syncMOC, domain: UUID().uuidString)
        let otherUsers = [otherUser1, otherUser2, otherUser3]
        let classifiedDomains = otherUsers.map { $0.domain! }

        storeClassifiedDomains(with: .enabled, domains: classifiedDomains)

        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(with: otherUsers)

        // then
        XCTAssertEqual(classification, .classified)
    }

    func testThatItReturnsNotClassified_WhenFeatureIsEnabled_WhenAtLeastOneOtherUserDomainIsNotClassified() {
        // given
        let otherUser1 = createUser(moc: syncMOC, domain: UUID().uuidString)
        let otherUser2 = createUser(moc: syncMOC, domain: UUID().uuidString)
        let otherUser3 = createUser(moc: syncMOC, domain: UUID().uuidString)
        let otherUsers = [otherUser1, otherUser2, otherUser3]

        var classifiedDomains = otherUsers.map { $0.domain! }
        classifiedDomains.removeFirst()

        storeClassifiedDomains(with: .enabled, domains: classifiedDomains)

        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(with: otherUsers)

        // then
        XCTAssertEqual(classification, .notClassified)
    }

    func testThatItReturnsNotClassified_WhenFeatureIsEnabled_WhenAtLeastOneOtherUserDomainIsNil() {
        // given
        let otherUser1 = createUser(moc: syncMOC, domain: UUID().uuidString)
        let otherUser2 = createUser(moc: syncMOC, domain: nil)
        let otherUser3 = createUser(moc: syncMOC, domain: UUID().uuidString)
        let otherUsers = [otherUser1, otherUser2, otherUser3]

        let classifiedDomains = otherUsers.compactMap { $0.domain }

        storeClassifiedDomains(with: .enabled, domains: classifiedDomains)

        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(with: otherUsers)

        // then
        XCTAssertEqual(classification, .notClassified)
    }

}
