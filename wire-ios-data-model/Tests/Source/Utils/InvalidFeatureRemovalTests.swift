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
@testable import WireDataModel

class InvalidFeatureRemovalTests: DiskDatabaseTest {

    func testAllInstancesRemoved() throws {
        coreDataStack.syncContext.performGroupedAndWait { context in
            // Given
            let team = Team.insertNewObject(in: context)
            team.remoteIdentifier = UUID()

            Feature.insert(name: .appLock, status: .enabled, config: nil, context: context)
            Feature.insert(name: .appLock, status: .disabled, config: nil, context: context)

            XCTAssertTrue(self.fetchInstances(in: context).count > 1)

            // When
            InvalidFeatureRemoval.removeInvalid(in: context)

            // Then
            XCTAssertEqual(self.fetchInstances(in: context).count, 0)
        }
    }

    func testRestoreNewDefaultConferenceCallingConfig() throws {
        coreDataStack.syncContext.performGroupedAndWait { context in
            // Given
            self.fetchInstances(in: context).forEach(context.delete)

            Feature.insert(name: .conferenceCalling, status: .disabled, config: nil, context: context)
            XCTAssertEqual(self.fetchInstances(in: context).count, 1)

            // When
            InvalidFeatureRemoval.restoreDefaultConferenceCallingConfig(in: context)

            // Then
            let instances = self.fetchInstances(in: context)
            XCTAssertEqual(instances.count, 1)
            XCTAssertEqual(instances[0].status, .enabled)
        }
    }

    private func fetchInstances(in context: NSManagedObjectContext) -> [Feature] {
        let fetchRequest = NSFetchRequest<Feature>(entityName: Feature.entityName())
        return context.fetchOrAssert(request: fetchRequest)
    }

}
