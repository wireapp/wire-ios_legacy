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
import WireUtilities

extension NSManagedObjectContext: TearDownCapable {

    /// Tear down the context. Using the context after this call results in
    /// undefined behavior.
    public func tearDown() {
        self.performGroupedBlockAndWait {
            self.tearDownUserInfo()
            let objects = self.registeredObjects
            objects.forEach {
                if let tearDownCapable = $0 as? TearDownCapable {
                    tearDownCapable.tearDown()
                }
            }
            self.reset()
        }
    }

    private func tearDownUserInfo() {
        let allKeys = userInfo.allKeys
        for value in userInfo.allValues {
            if let tearDownCapable = value as? TearDownCapable {
                tearDownCapable.tearDown()
            }
        }
        userInfo.removeObjects(forKeys: Array(allKeys))
    }
}
